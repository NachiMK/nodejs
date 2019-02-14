import _ from 'lodash'
import moment from 'moment'
import { isObject } from 'util'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { SaveStringToS3File, GetJSONFromS3Path } from '../s3ODS/index'
import { S3Params } from '../s3-params/index'
import { IsValidString, CleanUpString } from '../../utils/string-utils/index'
import { CleanUpBool } from '../../utils/bool-utils/index'
import { ExtractMatchingKeyFromSchema } from '../json-extract-matching-keys'
import { JsonToKnexDataTypeEnum } from '../../data/psql/table/json-to-knex-mapping'
import { knexNoDB } from '../../data/psql/index'
import { GetCleanColumnName } from '../../data/psql/DataTypeTransform'

export class JsonSchemaToDBSchema {
  logger = createLogger({
    format: _format.combine(
      _format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss',
      }),
      _format.splat(),
      _format.prettyPrint()
    ),
  })

  constructor(params = {}) {
    this._tableNamePrefix = params.TableNamePrefix || ''
    this._batchId = params.BatchId || ''
    this._s3Params = new S3Params(params)
    this.setDBOptions(params.DBOptions)
    this._outputTableName = ''
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }

  get TableNamePrefix() {
    return this._tableNamePrefix
  }

  get BatchId() {
    return this._batchId
  }
  get S3Parameters() {
    return this._s3Params
  }
  get LogLevel() {
    return this.loglevel
  }
  get DBOptions() {
    return this._dbOptions
  }
  get AppendBatchId() {
    return this._dbOptions.appendBatchId
  }
  get AppendDateTimeToTable() {
    return this._dbOptions.appendDateTimeToTable
  }
  get TableSchema() {
    return this._dbOptions.tableSchema
  }
  get DataTypeKey() {
    return this._dbOptions.dataTypeKey
  }
  get OutputTableName() {
    return this._outputTableName
  }
  get CleanColumnNames() {
    return this._dbOptions.removeNonAlphaNumericCharsInColumnNames
  }

  setDBOptions(opts = {}) {
    const retOpts = {
      tableSchema: 'public',
      dataTypeKey: 'type',
      appendDateTimeToTable: true,
      appendBatchId: true,
      removeNonAlphaNumericCharsInColumnNames: true,
    }
    let ignoreColumns = []
    if (opts.IgnoreColumns && _.isArray(opts.IgnoreColumns) && opts.IgnoreColumns.length > 0) {
      ignoreColumns = opts.IgnoreColumns
    }
    this._dbOptions = {
      ...retOpts,

      tableSchema: CleanUpString(opts.TableSchema, retOpts.tableSchema),
      ignoreColumns: ignoreColumns,
      dataTypeKey: CleanUpString(opts.DataTypeKey, retOpts.dataTypeKey),
      appendDateTimeToTable: CleanUpBool(opts.AppendDateTimeToTable, retOpts.appendDateTimeToTable),
      appendBatchId: CleanUpBool(opts.AppendBatchId, retOpts.appendBatchId),
      removeNonAlphaNumericCharsInColumnNames: CleanUpBool(
        opts.RemoveNonAlphaNumericCharsInColumnNames,
        retOpts.removeNonAlphaNumericCharsInColumnNames
      ),
    }
  }

  async createTableScriptByJsonSchema({ JsonSchema, DataTypeKey = 'type' }) {
    if (JsonSchema) {
      // get columns and types.
      const colsAndTypes = await getColumnsAndType(JsonSchema, DataTypeKey)
      this.logger.log('debug', `Cols and Types:${colsAndTypes}`)
      // get script
      this._outputTableName = this.getTableName()
      const dbScript = await this.getCreateTableSQL(
        this.TableSchema,
        this.OutputTableName,
        colsAndTypes,
        this.CleanColumnNames
      )
      this.logger.log('debug', `SQL Script:${dbScript}`)
      return dbScript
    }

    async function getColumnsAndType(jsonSchema, dataTypeKey) {
      if (jsonSchema && dataTypeKey) {
        // extract all columns and types based on type column
        //DATA-742
        const matchingSchema = ExtractMatchingKeyFromSchema(jsonSchema, dataTypeKey, {
          IncludeMaxLength: true,
        })
        // console.log(`Matching schema: ${JSON.stringify(matchingSchema)}`)
        // if we didnt find any columns, throw error
        if (matchingSchema && isObject(matchingSchema) && Object.keys(matchingSchema).length > 0) {
          // return the object of cols/types
          return matchingSchema
        } else {
          throw new Error(
            `JsonSchema doesnt have any properties matching key: ${dataTypeKey} or Invalid Json Schema`
          )
        }
      } else {
        throw new Error(
          `Invalid Param. JsonSchema: ${JSON.stringify(
            jsonSchema
          )} or dataTypeKey: ${dataTypeKey} was not provided to get Columns and Types.`
        )
      }
    } // end of getSchema
  }

  async getCreateTableSQL(tableSchema, tableName, colsAndTypes, cleanColumnNames = true) {
    let knex
    let dbScript
    if (tableName && colsAndTypes) {
      // find the postgres DB Type whic is equivalent of the given JSON type
      // loop through objects
      const colNames = Object.keys(colsAndTypes)
      if (colNames && colNames.length > 0) {
        try {
          // get knex type
          knex = knexNoDB()
          // create table
          dbScript = await knex.schema
            .withSchema(tableSchema)
            .createTable(tableName, function(table) {
              // preserve the order of column creation
              for (const colIndex in colNames) {
                try {
                  // find what action to take
                  //DATA-742
                  const objEnum = _.cloneDeep(
                    JsonToKnexDataTypeEnum[colsAndTypes[colNames[colIndex]].type]
                  )
                  // create column by calling appropriate function
                  // do we have a length if so use it? DATA-742
                  if (
                    objEnum.opts &&
                    !_.isUndefined(objEnum.opts['length']) &&
                    !_.isUndefined(colsAndTypes[colNames[colIndex]].maxLength)
                  ) {
                    objEnum.opts['length'] =
                      objEnum.opts['length'] >= colsAndTypes[colNames[colIndex]].maxLength
                        ? objEnum.opts['length']
                        : colsAndTypes[colNames[colIndex]].maxLength
                  }
                  const nameOfColumn = cleanColumnNames
                    ? GetCleanColumnName(colNames[colIndex])
                    : colNames[colIndex]
                  objEnum.AddColFunction(table, nameOfColumn, objEnum.opts || {})
                } catch (err) {
                  const e = new Error(
                    `Error in adding column: ${colIndex} to Table: ${tableName}, error: ${
                      err.message
                    }`
                  )
                  console.log(e.message)
                  throw e
                }
              }
            })
            .toSQL()
        } catch (err) {
          throw new Error(`Error in adding cols to Table: ${tableName}, error: ${err.message}`)
        } finally {
          if (knex) {
            knex.destroy()
          }
        }
      } else {
        throw new Error('colsAndTypes is empty. Cannot get Create Table SQL Statement')
      }
      // throw error in case of invalid script object
      if (!(dbScript && dbScript.length && dbScript.length > 0 && dbScript[0].sql)) {
        throw new Error(
          `Create Table script failed with unknown error. sql attribute missing. dbScript: ${dbScript}`
        )
      }
      return dbScript[0].sql
    } else {
      throw new Error(
        `Invalid Parameter. tableName: ${tableName} or colsAndTypes: ${colsAndTypes} is null.`
      )
    }
  }

  async createTableScriptByS3SchemaFile() {
    this.ValidateParams()
    this.S3Parameters.ValidateInputFiles()
    try {
      // Get data from S3
      const inputdata = await GetJSONFromS3Path(this.S3Parameters.S3DataFilePath)
      // object has any items
      if (inputdata) {
        // get script
        const dbScript = await this.createTableScriptByJsonSchema({
          JsonSchema: inputdata,
          DataTypeKey: this.DataTypeKey,
        })
        return dbScript
      }
    } catch (err) {
      const e = new Error(`Error in generating SQL Script from JSON Schema. ${err.message}`)
      this.logger.log('error', e.message)
      throw e
    }
  }

  getTableName() {
    const batch = this.AppendBatchId && _.isNumber(this.BatchId) ? `_${this.BatchId}` : ''
    const timestamp = this.AppendDateTimeToTable ? `_${moment().format('YYMMDD_HHmmss')}` : ''
    const tblName = `${this.TableNamePrefix}${batch}${timestamp}`
      .replace(/[\W]+/g, '')
      .replace(/__/gi, '_')
    return tblName.substring(0, 63)
  }

  async saveDBSchema(schemaToSave = '') {
    let retFileName
    try {
      // TODO
      this.S3Parameters.ValidateOutputFiles()
      let schema = schemaToSave
      if (!schemaToSave || _.isEmpty(schemaToSave)) {
        schema = await this.createTableScriptByS3SchemaFile()
      }
      if (schema) {
        const { S3OutputBucket, S3OutputKey } = this.S3Parameters.getOutputParams()
        this.logger.log('info', `S3Path: s3://${S3OutputBucket}/${S3OutputKey}`)
        retFileName = await SaveStringToS3File({
          S3OutputBucket,
          S3OutputKey,
          StringData: schema,
          AppendDateTimeToFileName: false,
          FileExtension: this.S3Parameters.FileExtension,
        })
      } else {
        throw new Error('No DB Schema to save. Check S3Path or the Schema passed in')
      }
    } catch (err) {
      // TODO
      const e = new Error(`Error in Saving DB Schema from Json Schema. ${err.message}`)
      this.logger.log('error', e.message)
      throw e
    }
    return retFileName
  }

  ValidateParams() {
    // validate the rest of parameters
    if (!IsValidString(this.TableNamePrefix)) {
      throw new Error('Invalid Param. TableName Prefix is required.')
    }
  }
}
