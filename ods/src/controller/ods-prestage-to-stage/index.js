//@ts-check
import pickBy from 'lodash/pickBy'
import isUndefined from 'lodash/isUndefined'
// import mapLimit from 'async/mapLimit'
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
import { executeCommand, getConnectionString } from '../../data/psql'
import { KnexTable } from '../../data/psql/table/knexTable'

const JsonObjectNameEnum = DynamicAttributeEnum.JsonObjectName.value
const PreStageTableEnum = DynamicAttributeEnum.PreStageTableName.value
const S3SchemaFileBucketName = PreDefinedAttributeEnum.S3SchemaFileBucketName.value
const StageTablePrefix = 'StageTablePrefix'
const S3SchemaFileEnum = PreDefinedAttributeEnum.S3SchemaFile.value
const StgTblS3PrefixEnum = PreDefinedAttributeEnum.StageSchemaFile.value
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
    const regExJ = new RegExp(JsonObjectNameEnum, 'gi')
    const regExT = new RegExp(PreStageTableEnum, 'gi')
    const s3Prefix = this.TaskAttributes[StgTblS3PrefixEnum] || ''
    if (this.TaskAttributes) {
      const filtered = pickBy(this.TaskAttributes, function(attvalue, attkey) {
        // Attribute name should in format: S3CSVFile1.CSVFileName or S3CSVFile1.JsonObjectName
        return (
          attkey.match(/S3CSVFile\d+\.{1}.*/gi) && (attkey.match(regExJ) || attkey.match(regExT))
        )
      })
      // Every file has two different information, File name and Json
      // we are going to combine that into one object
      const retCollection = {}
      Object.keys(filtered).map((item) => {
        const [fileCommonKey, AttributeName] = item.split('.')
        if (!retCollection[fileCommonKey]) {
          retCollection[fileCommonKey] = {}
        }
        if (AttributeName.match(regExJ)) {
          retCollection[fileCommonKey][JsonObjectNameEnum] = filtered[item]
          const [idx, tblname] = filtered[item].split('-')
          retCollection[fileCommonKey][StageTablePrefix] = tblname
          retCollection[fileCommonKey]['Index'] = parseInt(idx)
          retCollection[fileCommonKey]['S3OuputPrefix'] = `${s3Prefix}-${filtered[item]}-db-`
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
  async StageData(parallelRuns = 1) {
    this.ValidateParam()
    const retResp = {
      status: {
        message: 'processing',
      },
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
        const retVal = {}
        retVal[`${table.StageTablePrefix}`] = {}
        // get SQL script from JSON
        const tblDiff = await this.GetTableDiffScript(table)

        if (IsValidString(tblDiff.DBScript)) {
          retVal[`${table.StageTablePrefix}`].TableDiffExists = true
          retVal[`${table.StageTablePrefix}`].TableDiffScript = tblDiff.DBScript
          retVal[`${table.StageTablePrefix}`].S3ScriptFilePath = tblDiff.S3FilePath || ''

          // Create the Tables/Apply difference in DB
          const tblName = await this.ApplyScriptsToDB(table, retVal[`${table.StageTablePrefix}`])
          retVal[`${table.StageTablePrefix}`].TableSchemaUpdated = true
        }

        // Copy data from PreStage to Stage.
        const RowCount = await this.CopyDataToStage(table)
        retVal[`${table.StageTablePrefix}`].DataCopied =
          !isUndefined(RowCount) && RowCount > 0 ? true : false
        retVal[`${table.StageTablePrefix}`].RowCount = RowCount
        tableResults.push(retVal)
      }
      // const tableResults = await Promise.all(
      //   mapLimit(tables, parallelRuns, async (table) => {
      //     const retVal = {}
      //     retVal[`${table.StageTablePrefix}`] = {}
      //     // get SQL script from JSON
      //     const tblDiff = await this.GetTableDiffScript(table)

      //     if (toLength(tblDiff.DBScript) > 0) {
      //       retVal[`${table.StageTablePrefix}`].TableDiffExists = true
      //       retVal[`${table.StageTablePrefix}`].TableDiffScript = tblDiff.DBScript
      //       retVal[`${table.StageTablePrefix}`].S3ScriptFilePath = tblDiff.S3FilePath || ''

      //       // Create the Tables/Apply difference in DB
      //       const tblName = await this.ApplyScriptsToDB(table, retVal[`${table.StageTablePrefix}`])
      //       retVal[`${table.StageTablePrefix}`].TableSchemaUpdated = true
      //     }

      //     // Copy data from PreStage to Stage.
      //     const RowCount = await this.CopyDataToStage(table)
      //     retVal[`${table.StageTablePrefix}`].DataCopied =
      //       !isUndefined(RowCount) && RowCount > 0 ? true : false
      //     retVal[`${table.StageTablePrefix}`].RowCount = RowCount
      //     return retVal
      //   })
      // )

      if (tableResults && tableResults.length > 0) {
        retResp.status.message = 'success'
      }
    } catch (err) {
      const e = new Error(`Error in copying data to stage table, ${err.message}`)
      retResp.error = e
      retResp.status.message = 'error'
      throw e
    }
    return retResp
  }

  async GetTableDiffScript(table) {
    const output = {}
    const stgTblPrefix = table[StageTablePrefix]
    try {
      const jsonschema = await this.getTableJsonSchema(stgTblPrefix, table.Index)
      const objSchemaDiff = new SchemaDiff({
        JsonSchema: jsonschema,
        TableName: stgTblPrefix,
        TableSchema: 'stg',
        DataTypeKey: 'db_type',
        DBConnection: this.DBConnection,
      })
      // get script
      output.DBScript = await objSchemaDiff.SQLScript()
      output.TableSchema = 'stg'
      output.TableName = stgTblPrefix
      // save file
      if (IsValidString(this.TaskAttributes[S3SchemaFileBucketName])) {
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
      throw new Error(`Error in getting Stage table script: ${err.message}`)
    }
    return output
  }

  async getTableJsonSchema(stgTblPrefix, index) {
    const rootItem = index === 0
    // extract the schema for given object
    if (this._JsonFroms3SchemaFile && stgTblPrefix) {
      if (rootItem) {
        return this._JsonFroms3SchemaFile
      }
      const intKeyIndex = Object.keys(this._JsonFroms3SchemaFile.properties).indexOf(stgTblPrefix)
      this.LogMsgToODSLogger(`Stage Table Prefix: ${stgTblPrefix}, Found in Schema: ${intKeyIndex}`)
      if (intKeyIndex > 0) {
        return this._JsonFroms3SchemaFile.properties[stgTblPrefix].items
      } else {
        throw new Error(`Table: ${stgTblPrefix} is not Found in JSON Schema`)
      }
    } else {
      throw new Error(
        `Either No JSON in file: ${
          this.TaskAttributes[S3SchemaFileEnum]
        } or TablePrefix is empty: ${stgTblPrefix}`
      )
    }
  }

  async ApplyScriptsToDB(table, schemaDiffResult) {
    try {
      if (schemaDiffResult && schemaDiffResult.TableDiffScript) {
        const dbResp = await executeCommand({
          Query: schemaDiffResult.TableDiffScript,
          ConnectionString: this.DBConnection,
          BatchKey: this.DataPipeLineTask.DataPipeLineTaskQueueId,
        })
        if (!dbResp.completed || !isUndefined(dbResp.error)) {
          throw new Error(
            `Error updating SQL Table: ${table.StageTablePrefix}, error: ${dbResp.error.message}`
          )
        }
      } else {
        throw new Error('Invalid Parameters to Apply scripts.')
      }
    } catch (err) {
      throw new InvalidStageTableError(`Error in ApplyScriptsToDB: ${err.message}`)
    }
  }

  async CopyDataToStage(table) {
    let rowCnt = 0
    try {
      const knexTable = new KnexTable({
        TableName: table.StageTablePrefix,
        TableSchema: 'stg',
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
      throw new InvalidPreStageDataError(`Error in CopyDataToStage script: ${err.message}`)
    }
  }

  ValidateParam() {
    if (!this.DataPipeLineTask) {
      throw new Error(`InValidParam. DataPipeLineTask is required.`)
    }
  }
}
