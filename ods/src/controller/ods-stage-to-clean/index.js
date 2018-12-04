//@ts-check
import _ from 'lodash'
import odsLogger from '../../modules/log/ODSLogger'
import {
  DynamicAttributeEnum,
  PreDefinedAttributeEnum,
} from '../../modules/ODSConstants/AttributeNames'
import { SaveStringToS3File } from '../../modules/s3ODS'
import { SQLTableDiff } from '../../modules/sql-schema-diff/SQLTableDiff'
import { IsValidString } from '../../utils/string-utils/index'
import { executeCommand, getConnectionString, executeScalar, executeQueryRS } from '../../data/psql'
import { getCleanTableDefaultCols, getPreStageDefaultCols } from '../../modules/ODSConstants'

const JsonObjectNameEnum = DynamicAttributeEnum.JsonObjectName.value
const JsonSchemaPathPropName = 'JsonSchemaPath'
const CleanTableNameEnum = DynamicAttributeEnum.CleanTableName.value
const CleanTblS3PrefixEnum = PreDefinedAttributeEnum.CleanSchemaFile.value
const CleanTablePrefixEnum = PreDefinedAttributeEnum.CleanTablePrefix.value
const S3SchemaFileBucketName = PreDefinedAttributeEnum.S3SchemaFileBucketName.value
// const S3SchemaFileEnum = PreDefinedAttributeEnum.S3SchemaFile.value
const RowCntEnum = DynamicAttributeEnum.RowCount.value
const StageTblEnum = DynamicAttributeEnum.StageTableName.value
const StgSchemaEnum = PreDefinedAttributeEnum.DBSchemaStageTable.value
const CleanSchemaEnum = PreDefinedAttributeEnum.DBSchemaCleanTable.value
const BizKeyColEnum = PreDefinedAttributeEnum.BusinessKeyColumn.value

/**
 * @class ODSStageToClean
 * @description This class loads given table into a clean stage table.
 *
 * Steps:
 *  - Gets stage table that was staged prior to this step.
 *  - Syncs Stage schema (based on Json and existing clean table)
 *  - Copies data from stage to clean by call Stored procedure
 *
 * @throws
 *  - StageToCleanLoadError
 *  - StageToCleanValidationError
 */
export class ODSStageToClean {
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
  get DBConnection() {
    return getConnectionString('odsdynamodb', process.env.STAGE)
  }
  get S3Bucket() {
    return this.DataPipeLineTask.TaskQueueAttributes[S3SchemaFileBucketName] || ''
  }
  ValidateParam() {
    if (!this.DataPipeLineTask) {
      throw new Error(`InValidParam. DataPipeLineTask is required.`)
    }
  }
  get PrevTaskId() {
    return (
      this.DataPipeLineTask.TaskQueueAttributes[DynamicAttributeEnum.PreviousTaskId.value] || -1
    )
  }
  get StageTableSchema() {
    return this.DataPipeLineTask.TaskQueueAttributes[StgSchemaEnum] || ''
  }
  get CleanTableSchema() {
    return this.DataPipeLineTask.TaskQueueAttributes[CleanSchemaEnum] || ''
  }
  get BusinessKeyColName() {
    return this.DataPipeLineTask.TaskQueueAttributes[BizKeyColEnum] || ''
  }

  /**
   * @property TablesToLoad
   * @returns
  //  * { "Table" :
  //  *    {
  //  *      "Index" : 0,
  //  *      "StageTableName" : stg."clients_clients",
  //  *      "JsonSchemaPath" : "clients",
  //  *      "JsonObjectName" : "clients",
  //  *      "CleanTableName" : "public.clients_Clients",
  //  *      "S3OutputPrefix" : '',
  //  *      "StageRowCount"  : 0,
  //  *    }
  //  * }
   */
  get TablesToLoad() {
    const regExCsv = new RegExp(/S3CSVFile\d+\.{1}.*/, 'gi')
    const regExJ = new RegExp(JsonObjectNameEnum, 'gi')

    if (this.TaskAttributes) {
      const filtered = _.pickBy(this.TaskAttributes, function(attvalue, attkey) {
        // Attribute name should in format: S3CSVFile1.CSVFileName or S3CSVFile1.JsonObjectName
        return attkey.match(regExCsv)
      })
      // Every file has few info, File name, Json key, and Json path in schema
      // we are going to combine that into one object
      const retCollection = {}
      const s3Prefix = this.TaskAttributes[CleanTblS3PrefixEnum] || ''
      const ParentPrefix = this.TaskAttributes[CleanTablePrefixEnum]
      Object.keys(filtered).map((item) => {
        const [fileCommonKey, AttributeName] = item.split('.')
        if (!retCollection[fileCommonKey] && item.match(regExCsv)) {
          retCollection[fileCommonKey] = {}
        }
        if (AttributeName.match(regExJ)) {
          const [idx] = filtered[item].split('-')
          const tblname = filtered[item].replace(/\d+-/gi, '')
          retCollection[fileCommonKey] = {
            Index: parseInt(idx),
            [StageTblEnum]: filtered[`${fileCommonKey}.${StageTblEnum}`],
            [JsonSchemaPathPropName]: filtered[`${fileCommonKey}.${JsonSchemaPathPropName}`],
            [JsonObjectNameEnum]: filtered[item],
            [CleanTableNameEnum]: `${ParentPrefix}${tblname}`,
            S3OutputPrefix: `${s3Prefix}${filtered[item]}-db`,
            StageRowCount: filtered[`${fileCommonKey}.${RowCntEnum}`],
          }
        }
      })

      return retCollection
    }
    return {}
  }

  async LoadData() {
    const output = {
      status: {
        message: 'processing',
      },
      TaskAttributes: {},
      error: {},
    }
    try {
      const tables = this.TablesToLoad
      // const retTables = []
      for (const item of Object.keys(tables)) {
        const key = item
        const table = tables[item]
        table.LoadCleanTable = 'no'
        if (table.StageRowCount && table.StageRowCount > 0) {
          // Find schema difference
          const sqlTblDiffObj = new SQLTableDiff(this.getTableDiffParams(table))
          const defaultColumns = this.getDefaultTrackingCols(table, tables)
          const colsToIgnore = getPreStageDefaultCols()
          // apply schema difference
          const diffScript = await sqlTblDiffObj.GetSQLDiffScript(defaultColumns, colsToIgnore)
          let applyResp = false
          // Sync Clean table with stage table
          if (IsValidString(diffScript)) {
            applyResp = await this.ApplyScriptsToDB(table, diffScript)
            // save the SQL diff to S3 -- ignore errors
            table.S3SCriptFilePath = await this.SaveSQLToS3(table, diffScript)
          }
          table.CleanTableScriptApplied = applyResp === true
          // Run validation scripts comparing stage vs clean, log error rows and throws erro
          table.LoadCleanTable = 'yes'
        }
        // retTables.push(retObj)
      }

      _.forEach(tables, async (table, key) => {
        odsLogger.log('info', `Merging Stage to clean table: ${table}`)
        // stage has some rows
        if (table['LoadCleanTable'] === 'yes') {
          // Call Stored proc to copy form stage to clean if no errors
          // get saved clean table data count for pipe line task
          // Return count
          const loadResp = await this.MergeStageToClean(table, tables)
          if (loadResp && loadResp.status === 'success') {
            table['CleanTableRowCount'] = loadResp.RowCount
          }
        }
      })

      // update attributes
      _.forIn(tables, (table, key) => {
        _.forIn(table, (val, subkey) => {
          output.TaskAttributes[`${key}.${subkey}`] = val
        })
      })
      return output
    } catch (err) {
      output.error = new Error(`Error LoadData stage to clean: ${err.message}`)
      odsLogger.log('error', output.error.message)
      output.status.message = 'error'
      throw output.error
    }
  }

  getTableDiffParams(table) {
    return {
      SourceTable: table.StageTableName,
      SourceTableSchema: this.StageTableSchema,
      TargetTable: table.CleanTableName,
      TargetTableSchema: this.CleanTableSchema,
      SourceDBConnection: this.DBConnection,
      TargetDBConnection: this.DBConnection,
      LogLevel: this.LogLevel,
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
        if (!dbResp.completed || !_.isUndefined(dbResp.error)) {
          throw new Error(
            `Error updating SQL Table: ${table.CleanTableName}, error: ${dbResp.error.message}`
          )
        } else {
          return true
        }
      }
    } catch (err) {
      odsLogger.log('error', `Error in ApplyScriptsToDB: ${err.message}`)
      throw new Error(`Error in ApplyScriptsToDB: ${err.message}`)
    }
  }

  async SaveSQLToS3(table, sqlScript) {
    let retFile = ''
    if (!_.isEmpty(sqlScript) && !_.isEmpty(table.S3OutputPrefix)) {
      try {
        retFile = await SaveStringToS3File({
          S3OutputBucket: this.S3Bucket,
          S3OutputKey: table.S3OutputPrefix,
          StringData: sqlScript,
          AppendDateTimeToFileName: true,
          Overwrite: 'yes',
          FileExtension: '.sql',
        })
      } catch (err) {
        odsLogger.log('error', `Error in SaveSQLToS3: ${err.message}`)
        throw new Error(`Error in SaveSQLToS3: ${err.message}`)
      }
    }
    return retFile
  }

  getLienageColsAndTables(table, tables) {
    const jsonSchemaPath = table[JsonSchemaPathPropName]
    const output = {
      ParentId: '',
      RootId: '',
      TableName: '',
      PrimaryKeyName: '',
      StageParentTableName: '',
      CleanParentTableName: '',
      RootParentTableName: '',
      IsRoot: false,
    }
    const [...lineagePath] = jsonSchemaPath.split('.')
    const tbl =
      Array.isArray(lineagePath) && lineagePath.length > 0
        ? lineagePath[lineagePath.length - 1]
        : ''
    let parentid = ''
    let rootid = ''
    let IsRootTable = true
    // find parent
    if (!_.isUndefined(lineagePath) && _.size(lineagePath) > 1) {
      parentid = lineagePath[lineagePath.length - 2]
      rootid = lineagePath[0]
      IsRootTable = false
    }
    output.TableName = tbl
    output.PrimaryKeyName = `${tbl}Id`
    output.ParentId = `Parent_${parentid}Id`
    output.RootId = `Root_${rootid}Id`
    if (!IsRootTable) {
      // find my parent stage/clean table
      const parentPath = lineagePath.slice(0, lineagePath.length - 1).join('.')
      const objParent = _.find(tables, (val) => {
        if (val[JsonSchemaPathPropName].localeCompare(parentPath) === 0) {
          return true
        } else {
          return false
        }
      })
      output.CleanParentTableName = !_.isUndefined(objParent) ? objParent[CleanTableNameEnum] : ''
      output.StageParentTableName = !_.isUndefined(objParent) ? objParent[StageTblEnum] : ''
      // find my root table
      const rootPath = lineagePath[0]
      const objRoot = _.find(tables, (val) => {
        if (val[JsonSchemaPathPropName].localeCompare(rootPath) === 0) {
          return true
        } else {
          return false
        }
      })
      output.RootParentTableName = !_.isUndefined(objRoot) ? objRoot[CleanTableNameEnum] : ''
    } else {
      output.IsRoot = true
    }
    return output
  }

  getDefaultTrackingCols(table, tableList) {
    const c = this.getLienageColsAndTables(table, tableList)
    let jstr = JSON.stringify(getCleanTableDefaultCols())
    const backtojson = JSON.parse(
      jstr
        .replace(/{TableName}/gi, c.TableName)
        .replace(/{Parent}/gi, c.ParentId)
        .replace(/{Root}/gi, c.RootId)
    )
    if (!c.IsRoot) {
      // delete json objects where AddOnlyToRootTable: True
      // if this table is not a ROOT table
      return _.omitBy(backtojson, (coldefintion, colName) => {
        return coldefintion.AddOnlyToRootTable
      })
    }
    return backtojson
  }

  async MergeStageToClean(table, tableList) {
    const output = {
      status: 'processing',
      RowCount: 0,
    }
    const tableName = table.CleanTableName
    try {
      const mergeParams = this.getMergeParams(table, tableList)
      output.RowCount = await this.dataMergeParams(mergeParams)
    } catch (err) {
      const errmsg = `Error in MergeStageToClean Table: ${tableName}, ${err.message}`
      odsLogger.log('error', errmsg)
      throw new Error(errmsg)
    }
    return output
  }

  getMergeParams(table, tableList) {
    const lineageCols = this.getLienageColsAndTables(table, tableList)
    const mergeParams = {
      StageTable: {
        Schema: this.StageTableSchema,
        TableName: table[StageTblEnum],
        ParentTableName: lineageCols.StageParentTableName,
      },
      CleanTable: {
        Schema: this.CleanTableSchema,
        TableName: table.CleanTableName,
        ParentTableName: lineageCols.CleanParentTableName,
        PrimaryKeyName: lineageCols.PrimaryKeyName,
        BusinessKeyName: '',
        RootTableName: lineageCols.RootParentTableName,
      },
      PreStageToStageTaskId: parseInt(this.PrevTaskId),
      TaskQueueId: this.DataPipeLineTask.DataPipeLineTaskQueueId,
    }
    if (lineageCols.IsRoot === true) {
      mergeParams.CleanTable.BusinessKeyName = this.BusinessKeyColName
    }
    return JSON.stringify(mergeParams, null, 2)
  }

  async dataMergeParams(mergeParams) {
    try {
      const mergeSQL = `SELECT * FROM public."udf_MergeStageToClean"('${mergeParams}'::jsonb);`
      const qParams = {
        Query: mergeSQL,
        ConnectionString: this.DBConnection,
        BatchKey: this.DataPipeLineTask.DataPipeLineTaskQueueId,
      }
      const dbResp = await executeQueryRS(qParams)
      if (!dbResp.completed || !_.isUndefined(dbResp.error)) {
        throw new Error(`Error merging to Table: ${dbResp.error.message}`)
      } else {
        return dbResp.rowCount
      }
    } catch (err) {
      odsLogger.log('error', `Error in dataMergeParams: ${err.message}`)
      throw new Error(`Error in dataMergeParams: ${err.message}`)
    }
  }
}
