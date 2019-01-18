//@ts-check
import pickBy from 'lodash/pickBy'
import isUndefined from 'lodash/isUndefined'
import odsLogger from '../../modules/log/ODSLogger'
import {
  DynamicAttributeEnum,
  PreDefinedAttributeEnum,
} from '../../modules/ODSConstants/AttributeNames'
import { GetJSONFromS3Path, SaveStringToS3File } from '../../modules/s3ODS'
import {
  InvalidPreStageDataError,
  InvalidStageTableError,
} from '../../modules/ODSErrors/StageError'
import { IsValidString } from '../../utils/string-utils/index'
import { SchemaDiff } from '../../modules/json-sql-schema-diff'
import { GetSchemaByDataPath } from '../../modules/json-schema-utils'
import { executeCommand, getConnectionString } from '../../data/psql'
import { KnexTable } from '../../data/psql/table/knexTable'
import { getPreStageDefaultCols } from '../../modules/ODSConstants'

const JsonObjectNameEnum = DynamicAttributeEnum.JsonObjectName.value
const JsonSchemaPathEnum = PreDefinedAttributeEnum.FlatJsonSchemaPath.value
const JsonSchemaPathPropName = 'JsonSchemaPath'
const PreStageTableEnum = DynamicAttributeEnum.PreStageTableName.value
const S3SchemaFileBucketName = PreDefinedAttributeEnum.S3SchemaFileBucketName.value
const StageTablePrefix = 'StageTablePrefix'
const S3SchemaFileEnum = PreDefinedAttributeEnum.S3SchemaFile.value
const StgTblS3PrefixEnum = PreDefinedAttributeEnum.StageSchemaFile.value
const psqlStgTblPrefixEnum = PreDefinedAttributeEnum.StageTablePrefix.value

/**
 * @class: OdsPreStageToStage
 * @description: This class takes a pipeline task, gets Schema details,
 * based on schema creates stage table or updates the table with correct schema
 * Loads data from Prestage tables to stage tables.
 * @param dataPipeLineTask: DataPipeLineTask Object that is load with its attributes
 */
export class OdsPreStageToStage {
  constructor(dataPipeLineTask) {
    this._dataPipeLineTask = dataPipeLineTask
    this._LogLevel = 'warn'
    if (dataPipeLineTask.TaskQueueAttributes && dataPipeLineTask.TaskQueueAttributes.LogLevel) {
      this._LogLevel = dataPipeLineTask.TaskQueueAttributes.LogLevel || 'warn'
    }
  }
  get DataPipeLineTask() {
    return this._dataPipeLineTask
  }
  get TaskAttributes() {
    return this.DataPipeLineTask.TaskQueueAttributes
  }
  get LogLevel() {
    return this._LogLevel
  }

  get TablesToStage() {
    const regExCsv = new RegExp(/S3CSVFile\d+\.{1}.*/, 'gi')
    const regExJ = new RegExp(JsonObjectNameEnum, 'gi')
    const regExT = new RegExp(PreStageTableEnum, 'gi')
    const regExSchema = new RegExp(JsonSchemaPathEnum.replace(/#/gi, '\\d+'), 'gi')
    const s3Prefix = this.TaskAttributes[StgTblS3PrefixEnum] || ''
    if (this.TaskAttributes) {
      const filtered = pickBy(this.TaskAttributes, function(attvalue, attkey) {
        // Attribute name should in format: S3CSVFile1.CSVFileName or S3CSVFile1.JsonObjectName
        return (
          (attkey.match(regExCsv) && (attkey.match(regExJ) || attkey.match(regExT))) ||
          attkey.match(regExSchema)
        )
      })
      // Every file has few info, File name, Json key, and Json path in schema
      // we are going to combine that into one object
      const retCollection = {}
      const stgParentPrefix = this.TaskAttributes[psqlStgTblPrefixEnum]
      Object.keys(filtered).map((item) => {
        const [fileCommonKey, AttributeName] = item.split('.')
        if (!retCollection[fileCommonKey] && item.match(regExCsv)) {
          retCollection[fileCommonKey] = {}
        }
        if (AttributeName.match(regExJ)) {
          const [idx] = filtered[item].split('-')
          const tblname = filtered[item].replace(/\d+-/gi, '').replace(/-/gi, '_')
          retCollection[fileCommonKey] = {
            [JsonObjectNameEnum]: filtered[item],
            [StageTablePrefix]: `${stgParentPrefix}${tblname}`,
            Index: parseInt(idx),
            S3OuputPrefix: `${s3Prefix}-${filtered[item]}-db`,
            [JsonSchemaPathPropName]: filtered[`${JsonSchemaPathEnum.replace(/#/gi, idx)}`],
          }
        } else if (AttributeName.match(regExT)) {
          retCollection[fileCommonKey][PreStageTableEnum] = filtered[item]
        }
      })
      return retCollection
    }
    return {}
  }

  LogMsgToODSLogger(msg) {
    odsLogger.log(this.LogLevel, msg)
  }
  LogJsonToODSLogger(jsonMsg) {
    odsLogger.log(this.LogLevel, jsonMsg)
  }

  get DBConnection() {
    return getConnectionString('odsdynamodb', process.env.STAGE)
  }

  /**
   * @function : StageData
   * It creates stage tables if needed,
   * modifies the stage table schema if needed based on JSON schema
   * Adds data from RAW to stage and does some data conversion in the process
   *
   * @throws: InvalidPreStageDataError, StageSchemaUpdateError
   * IF some rows fail conversion then entire batch is FAILED - InvalidPreStageDataError is thrown
   * IF stage table is missing then - InvalidSTageTableError is thrown
   * IF stage table schema couldnt be synced with PreStage then StageSchemaUpdateError is thrown
   */
  async StageData(parallelRuns = 1, tableSchema = 'stg') {
    this.ValidateParam()
    const retResp = {
      status: {
        message: 'processing',
      },
      TaskQueueAttributes: {},
    }
    try {
      const tables = this.TablesToStage
      this.LogMsgToODSLogger(`Staging Data, No Of Tables to Stage: ${tables.length}`)
      // get JSON data from the S3 File
      if (isUndefined(this._JsonFroms3SchemaFile)) {
        this._JsonFroms3SchemaFile = await GetJSONFromS3Path(this.TaskAttributes[S3SchemaFileEnum])
      }
      const tableResults = []
      for (const item of Object.keys(tables)) {
        const table = tables[item]
        retResp.TaskQueueAttributes[`${item}.StageTableName`] = `${table.StageTablePrefix}`
        retResp.TaskQueueAttributes[`${item}.${JsonSchemaPathPropName}`] =
          table[JsonSchemaPathPropName]
        const tblDiff = await this.GetTableDiffScript(table, tableSchema)

        // default values for attributes
        retResp.TaskQueueAttributes[`${item}.TableDiffExists`] = false
        retResp.TaskQueueAttributes[`${item}.TableSchemaUpdated`] = false

        // apply script if needed
        if (IsValidString(tblDiff.DBScript)) {
          retResp.TaskQueueAttributes[`${item}.TableDiffExists`] = true
          retResp.TaskQueueAttributes[`${item}.S3ScriptFilePath`] = tblDiff.S3FilePath || ''

          // Create the Tables/Apply difference in DB
          await this.ApplyScriptsToDB(table, tblDiff.DBScript)
          retResp.TaskQueueAttributes[`${item}.TableSchemaUpdated`] = true
        }

        // Copy data from PreStage to Stage.
        const RowCount = await this.CopyDataToStage(table, tableSchema)
        retResp.TaskQueueAttributes[`${item}.DataCopied`] =
          !isUndefined(RowCount) && RowCount > 0 ? true : false
        retResp.TaskQueueAttributes[`${item}.RowCount`] = RowCount
        tableResults.push({
          [`${item}`]: RowCount,
        })
      }

      if (tableResults && tableResults.length > 0) {
        retResp.status.message = 'success'
      }
    } catch (err) {
      const e = new Error(`Error in copying data to stage table, ${err.message}`)
      retResp.error = e
      retResp.status.message = 'error'
      odsLogger.log('error', e.message)
      throw e
    }
    return retResp
  }

  async GetTableDiffScript(table, tableSchema) {
    const output = {}
    const stgTblPrefix = table[StageTablePrefix]
    const stgTblSchemaPath = table[JsonSchemaPathPropName]
    try {
      const jsonschema = await this.getTableJsonSchema(stgTblSchemaPath, table.Index)
      const objSchemaDiff = new SchemaDiff({
        JsonSchema: jsonschema,
        TableName: stgTblPrefix,
        TableSchema: tableSchema,
        DataTypeKey: 'db_type',
        DBConnection: this.DBConnection,
      })
      // get script
      output.DBScript = await objSchemaDiff.SQLScript(this.getDefaultTrackingCols())
      output.TableSchema = tableSchema
      output.TableName = stgTblPrefix
      // save file
      if (
        IsValidString(this.TaskAttributes[S3SchemaFileBucketName]) &&
        IsValidString(output.DBScript)
      ) {
        output.S3FilePath = await SaveStringToS3File({
          S3OutputBucket: this.TaskAttributes[S3SchemaFileBucketName],
          S3OutputKey: table.S3OuputPrefix,
          StringData: output.DBScript,
          AppendDateTimeToFileName: true,
          Overwrite: 'yes',
          FileExtension: '.sql',
        })
      }
    } catch (err) {
      odsLogger.log('error', `Error in getting Stage table script: ${err.message}`)
      throw new Error(`Error in getting Stage table script: ${err.message}`)
    }
    return output
  }

  async getTableJsonSchema(stgTableSchemaPath, index) {
    // const rootItem = index === 0
    // extract the schema for given object
    if (this._JsonFroms3SchemaFile && stgTableSchemaPath) {
      // strip the first part
      const [, ...pathNoRoot] = stgTableSchemaPath.split('.')
      // if (rootItem) {
      //   return this._JsonFroms3SchemaFile
      // }
      const opts = { ExcludeObjects: true, ExcludeArrays: true }
      const schema = GetSchemaByDataPath(this._JsonFroms3SchemaFile, pathNoRoot.join('.'), opts)
      this.LogMsgToODSLogger(
        `Stage Table Prefix: ${stgTableSchemaPath}, Found in Schema: ${!isUndefined(schema)}`
      )
      if (!isUndefined(schema)) {
        if (schema['type'] === 'array') {
          return schema.items
        } else {
          return schema
        }
      } else {
        throw new Error(`Table schema at path: ${stgTableSchemaPath} is not Found in JSON Schema`)
      }
    } else {
      throw new Error(
        `Either No JSON in file: ${
          this.TaskAttributes[S3SchemaFileEnum]
        } or schema path is empty: ${stgTableSchemaPath}`
      )
    }
  }

  async ApplyScriptsToDB(table, dbDiffScript) {
    try {
      if (IsValidString(dbDiffScript)) {
        const qParams = {
          Query: dbDiffScript,
          ConnectionString: this.DBConnection,
          BatchKey: this.DataPipeLineTask.DataPipeLineTaskQueueId,
        }
        const dbResp = await executeCommand(qParams)
        if (!dbResp.completed || !isUndefined(dbResp.error)) {
          throw new Error(
            `Error updating SQL Table: ${table.StageTablePrefix}, error: ${dbResp.error.message}`
          )
        }
      } else {
        throw new Error('Invalid Parameters to Apply scripts.')
      }
    } catch (err) {
      odsLogger.log('error', `Error in ApplyScriptsToDB: ${err.message}`)
      throw new InvalidStageTableError(`Error in ApplyScriptsToDB: ${err.message}`)
    }
  }

  async CopyDataToStage(table, tableSchema) {
    let rowCnt = 0
    try {
      const knexTable = new KnexTable({
        TableName: table.StageTablePrefix,
        TableSchema: tableSchema,
        ConnectionString: this.DBConnection,
      })
      const blnExists = await knexTable.TableExists()
      if (blnExists) {
        rowCnt = await knexTable.CopyDataFromPreStage({
          PreStageTableName: table.PreStageTableName,
          DataPipeLineTaskQueueId: this.DataPipeLineTask.DataPipeLineTaskQueueId,
        })
        if (!isUndefined(rowCnt) && rowCnt > 0) {
          return rowCnt
        } else {
          throw new Error(
            `Data Load to Table: ${table.StageTablePrefix} completed but didn't load data!`
          )
        }
      } else {
        throw new Error(`Table: ${table.StageTablePrefix} does not exists in DBConnection`)
      }
    } catch (err) {
      odsLogger.log('error', `Error in CopyDataToStage script: ${err.message}`)
      throw new InvalidPreStageDataError(`Error in CopyDataToStage script: ${err.message}`)
    }
  }

  ValidateParam() {
    if (!this.DataPipeLineTask) {
      throw new Error(`InValidParam. DataPipeLineTask is required.`)
    }
  }

  getDefaultTrackingCols() {
    const defCols = getPreStageDefaultCols()
    const retObj = {
      AddTrackingCols: true,
      AdditionalColumns: defCols,
    }
    return retObj
  }
}
