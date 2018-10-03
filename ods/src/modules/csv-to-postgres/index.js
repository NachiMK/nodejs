import isArray from 'lodash/isArray'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { isObject } from 'util'
import { IsValidString, CleanUpString } from '../../utils/string-utils/index'
import { CleanUpBool } from '../../utils/bool-utils/index'
import { DynamicAttributeEnum } from '../../modules/ODSConstants/AttributeNames'
import { CSVToJsonSchema } from '../csv-to-json-schema'
import { JsonSchemaToDBSchema } from '../json-schema-to-db-schema'
import { executeCommand, executeQueryRS } from '../../data/psql/index'
import { KnexTable } from '../../data/psql/table/knexTable'

export class CsvToPostgres {
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
    this._CSVFilePath = params.S3DataFilePath || ''
    this._tableNamePrefix = params.TableNamePrefix || ''
    this._dBConnection = params.DBConnection || ''
    this._batchId = params.BatchId || ''
    this.setS3Options(params.S3Options || {})
    this.setDBOptions(params.DBOptions || {})

    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel || 'warn'
    this.logger.add(this.consoleTransport)
  }

  get CSVFilePath() {
    return this._CSVFilePath
  }
  get DBConnection() {
    return this._dBConnection
  }
  get TableNamePrefix() {
    return this._tableNamePrefix
  }
  get BatchId() {
    return this._batchId
  }
  get DBOptions() {
    return this._dbOptions
  }
  get S3Options() {
    return this._s3Options
  }
  get Jsonschema() {
    return this._jsonschema
  }
  get DBScript() {
    return this._dbScript
  }
  get OutputTableName() {
    return this._outputTableName
  }
  get OutputTableSchema() {
    return this._outputTableSchema
  }
  get OutputTableWithSchema() {
    return `${this.OutputTableSchema}.${this.OutputTableName}`
  }

  setDBOptions(opts = {}) {
    const retOpts = {
      _tableSchema: 'public',
      _dataTypeKey: 'type',
      _appendDateTimeToTable: true,
      _appendBatchId: true,
      _dropTableIfExists: true,
    }
    let ignoreColumns = []
    if (opts.IgnoreColumns && isArray(opts.IgnoreColumns) && opts.IgnoreColumns.length > 0) {
      ignoreColumns = opts.IgnoreColumns
    }
    this._dbOptions = {
      ...retOpts,

      _tableSchema: CleanUpString(opts.TableSchema, retOpts._tableSchema),
      _ignoreColumns: ignoreColumns,
      _appendDateTimeToTable: CleanUpBool(
        opts.AppendDateTimeToTable,
        retOpts._appendDateTimeToTable
      ),
      _appendBatchId: CleanUpBool(opts.AppendBatchId, retOpts._appendBatchId),
      _dropTableIfExists: CleanUpBool(opts.DropTableIfExists, retOpts._dropTableIfExists),
    }
  }

  setS3Options(opts = {}) {
    const retOpts = {
      _saveIntermediatFilesToS3: false,
      _s3OutputBucket: '',
      _s3OutputKeyPrefix: '',
    }

    this._s3Options = {
      ...retOpts,

      _saveIntermediatFilesToS3: CleanUpBool(
        opts.SaveIntermediatFilesToS3,
        retOpts._saveIntermediatFilesToS3
      ),
      _s3OutputBucket: CleanUpString(opts.S3OutputBucket, retOpts._s3OutputBucket),
      _s3OutputKeyPrefix: CleanUpString(opts.S3OutputKeyPrefix, retOpts._s3OutputKeyPrefix),
    }
  }

  async LoadData() {
    let Output = {}
    this.ValidateParam()
    try {
      // get json schema and save to this._jsonschema
      Output[DynamicAttributeEnum.S3JsonSchemaFilePath.value] = await this.getJsonSchema()
      // get db script and save to this._dbScript
      Output[DynamicAttributeEnum.S3DBSchemaFilePath.value] = await this.getDBScript()
      Output[DynamicAttributeEnum.PreStageTableName.value] = this.OutputTableWithSchema
      // create table or throw error
      await this.CreateTable()
      Output[DynamicAttributeEnum.TableCreated.value] = true
      // copy data and return row count or throw error
      Output[DynamicAttributeEnum.RowCount.value] = await this.CopyDataToTable()
    } catch (err) {
      await DropTable(this.DBConnection, this.OutputTableSchema, this.OutputTableName)
      const e = new Error(`Error in loading data, ${err.message} to table: ${Output.TableName}`)
      this.logger.log('error', e.message)
      throw e
    }
    return Output

    async function DropTable(connString, schemaName, tableName) {
      const blnDropped = false
      try {
        const tbl = new KnexTable({
          ConnectionString: connString,
          TableName: tableName,
          TableSchema: schemaName,
        })
        blnDropped = await tbl.DropTableIfExists()
      } catch (err) {
        console.log('error', `Error in Dropping Table: ${tableName}`)
        // eating the error here.
      }
      return blnDropped
    }
  }

  ValidateParam() {
    if (!IsValidString(this.CSVFilePath)) {
      throw new Error(`Invalid Params. CSV File Path is required. ${this.CSVFilePath}`)
    }
    if (!IsValidString(this.DBConnection)) {
      throw new Error(`Invalid Params. DBConnection is required. ${this.DBConnection}`)
    }
    if (!IsValidString(this.TableNamePrefix)) {
      throw new Error(`Invalid Params. TableNamePrefix is required. ${this.TableNamePrefix}`)
    }
  }

  async getJsonSchema() {
    const objParams = {
      S3DataFilePath: this.CSVFilePath,
    }
    if (this.S3Options._saveIntermediatFilesToS3) {
      objParams.S3OutputBucket = this.S3Options._s3OutputBucket
      objParams.S3OutputKeyPrefix = `${this.S3Options._s3OutputKeyPrefix}-json-bycsv-`
      objParams.FileExtension = '.json'
      objParams.AppendDateTimeToFileName = true
    }
    const objJsonSchemaGen = new CSVToJsonSchema(objParams)
    // get schema
    this._jsonschema = await objJsonSchemaGen.getJsonSchemaFromCSV()
    // save file
    if (this.S3Options._saveIntermediatFilesToS3) {
      const s3filepath = await objJsonSchemaGen.saveJsonSchemaFromCSV()
      return s3filepath
    }
  }

  async getDBScript() {
    const objParams = {
      TableNamePrefix: this.TableNamePrefix,
      BatchId: this.BatchId,
      DBOptions: {
        TableSchema: this.DBOptions._tableSchema,
        DataTypeKey: this.DBOptions._dataTypeKey,
        IgnoreColumns: this.DBOptions._ignoreColumns,
        AppendDateTimeToTable: this.DBOptions._appendDateTimeToTable,
        AppendBatchId: this.DBOptions._appendBatchId,
      },
    }

    if (this.S3Options._saveIntermediatFilesToS3) {
      objParams.S3DataFilePath = ''
      objParams.S3OutputBucket = this.S3Options._s3OutputBucket
      objParams.S3OutputKeyPrefix = `${this.S3Options._s3OutputKeyPrefix}-db-raw-`
      objParams.Options = {
        FileExtension: '.sql',
        AppendDateTimeToFileName: true,
      }
    }

    const objDBScriptGen = new JsonSchemaToDBSchema(objParams)
    // get script
    this._dbScript = await objDBScriptGen.createTableScriptByJsonSchema({
      JsonSchema: this.Jsonschema,
    })
    this._outputTableSchema = objDBScriptGen.TableSchema
    this._outputTableName = objDBScriptGen.OutputTableName
    // save file
    if (this.S3Options._saveIntermediatFilesToS3) {
      const s3filepath = await objDBScriptGen.saveDBSchema(this._dbScript)
      return s3filepath
    }
  }

  async CreateTable() {
    if (this.OutputTableName && this.DBScript) {
      const dbResp = await executeCommand({
        Query: this.DBScript,
        ConnectionString: this.DBConnection,
        BatchKey: this.BatchId,
      })
      if (!dbResp.completed || isObject(dbResp.error)) {
        throw new Error(
          `Error creating SQL Table: ${this.OutputTableName}, error: ${dbResp.error.message}`
        )
      }
    } else {
      throw new Errror(
        `Invalid Param Tablename: ${this.OutputTableName} or DBScript: ${this.DBScript} is empty.`
      )
    }
  }

  async CopyDataToTable() {
    let rowCnt = -1
    if (this.CSVFilePath && this.OutputTableWithSchema) {
      const tbl = new KnexTable({
        ConnectionString: this.DBConnection,
        TableName: this.OutputTableName,
        TableSchema: this.OutputTableSchema,
      })
      const blnTblExists = await tbl.TableExists()
      if (blnTblExists) {
        //copy
        rowCnt = await tbl.UploadDataFromS3(this.CSVFilePath)
      } else {
        throw new Error(`Table: ${this.OutputTableWithSchema} does not exists in DB`)
      }
    } else {
      throw new Errror(
        `Invalid Param: ${this.OutputTableWithSchema} or CSVFilePath: ${this.CSVFilePath} is empty.`
      )
    }
    return rowCnt
  }
}
