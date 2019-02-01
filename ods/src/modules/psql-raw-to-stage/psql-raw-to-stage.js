//@ts-check
import _ from 'lodash'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { GetJSONFromS3Path, SaveStringToS3File } from '../s3ODS'
import { IsValidString } from '../../utils/string-utils/index'
import { SchemaDiff } from '../json-sql-schema-diff'
import { getPreStageDefaultCols } from '../ODSConstants'
import { GetSchemaOfSimplePropByDataPath } from '../json-schema-utils'
import { executeCommand, getConnectionString } from '../../data/psql/index'
import { KnexTable } from '../../data/psql/table/knexTable'

export class PostgresRawToStage {
  logger = createLogger({
    format: _format.combine(
      _format.timestamp({
        format: 'YYYY-MM-DD HH:mm:ss',
      }),
      _format.splat(),
      _format.prettyPrint()
    ),
  })

  constructor({
    StageTableSchema = 'stg',
    StageTableName = '',
    S3SchemaFile = '',
    PathToSchema = '',
    DBConnection = '',
    S3OutputBucket = '',
    S3OutputKeyPrefix = '',
    RawTableName = '',
    LogLevel = 'warn',
    DataTypeKey = 'db_type',
    AddTrackingCols = true,
    BatchKey = -1,
  } = {}) {
    this._stageTableSchema = StageTableSchema
    this._stageTableName = StageTableName
    this._s3SchemaFile = S3SchemaFile
    this._pathToSchema = PathToSchema
    this._dBConnection = DBConnection || this.DefaultDBConnection
    this._s3OutputBucket = S3OutputBucket
    this._s3OutputKeyPrefix = S3OutputKeyPrefix || this._stageTableName
    this._rawTableName = RawTableName
    this._logLevel = LogLevel
    this._dataTypeKey = DataTypeKey
    this._addTrackingCols = AddTrackingCols
    this._batchKey = BatchKey

    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = LogLevel
    this.logger.add(this.consoleTransport)
  }

  get StageTableSchema() {
    return this._stageTableSchema
  }
  get StageTableName() {
    return this._stageTableName
  }
  get S3SchemaFile() {
    return this._s3SchemaFile
  }
  get PathToSchema() {
    return this._pathToSchema
  }
  get DBConnection() {
    return this._dBConnection
  }
  get S3OutputBucket() {
    return this._s3OutputBucket
  }
  get S3OutputKeyPrefix() {
    return this._s3OutputKeyPrefix
  }
  get RawTableName() {
    return this._rawTableName
  }
  get LogLevel() {
    return this._logLevel
  }
  get DataTypeKey() {
    return this._dataTypeKey
  }
  get AddTrackingCols() {
    return this._addTrackingCols
  }
  get BatchKey() {
    return this._batchKey
  }

  get DefaultDBConnection() {
    return getConnectionString('odsdynamodb', process.env.STAGE || 'dev')
  }

  ToString() {
    return `Parameters for Psql-raw-to-stage
    StageTableSchema : ${this.StageTableSchema},
    StageTablePrefix : ${this.StageTableName},
    S3SchemaFile : ${this.S3SchemaFile},
    PathToSchema : ${this.PathToSchema},
    DBConnection : ${!_.isUndefined(this.DBConnection)},
    S3OutputBucket : ${this.S3OutputBucket},
    S3OutputKeyPrefix : ${this.S3OutputKeyPrefix},
    RawTableName : ${this.RawTableName},
    LogLevel : ${this.LogLevel},
    DataTypeKey : ${this.DataTypeKey},
    AddTrackingCols : ${this.AddTrackingCols},
    BatchKey : ${this.BatchKey}
    `
  }

  async LoadData() {
    this.IsValidParam()
    const retResp = {
      status: {
        message: 'processing',
      },
      Attributes: {},
    }
    try {
      this.LogMsg(`Staging Data, Params: ${this.ToString()}`, 'info')
      // get JSON data from the S3 File
      this._JsonFroms3SchemaFile = await GetJSONFromS3Path(this.S3SchemaFile)

      retResp.Attributes.StageTableName = `${this.StageTableName}`
      retResp.Attributes.JsonSchemaPath = this.PathToSchema
      const tblDiff = await this.GetTableDiffScript()

      // default values for attributes
      retResp.Attributes.TableDiffExists = false
      retResp.Attributes.TableSchemaUpdated = false

      // apply script if needed
      if (IsValidString(tblDiff.DBScript)) {
        retResp.Attributes.TableDiffExists = true
        retResp.Attributes.S3ScriptFilePath = tblDiff.S3FilePath || ''

        // Create the Tables/Apply difference in DB
        await this.ApplyScriptsToDB(tblDiff.DBScript)
        retResp.Attributes.TableSchemaUpdated = true
      }

      // Copy data from PreStage to Stage.
      const RowCount = await this.CopyDataToStage()
      retResp.Attributes.DataCopied = !_.isUndefined(RowCount) && RowCount > 0 ? true : false
      retResp.Attributes.RowCount = RowCount

      retResp.status.message = 'success'
    } catch (err) {
      const e = new Error(`Error in copying data to stage table, ${err.message}`)
      retResp.error = e
      retResp.status.message = 'error'
      this.LogMsg(e.message, 'error')
      throw e
    }
    return retResp
  }

  async GetTableDiffScript() {
    const output = {}
    const stgTblPrefix = this.StageTableName
    const stgTblSchemaPath = this.PathToSchema
    try {
      const jsonschema = await this.getTableJsonSchema(stgTblSchemaPath)
      const objSchemaDiff = new SchemaDiff({
        JsonSchema: jsonschema.Schema,
        HadNestedProperties: jsonschema.HadNestedProperties,
        TableName: stgTblPrefix,
        TableSchema: this.StageTableSchema,
        DataTypeKey: this.DataTypeKey,
        DBConnection: this.DBConnection,
      })
      // get script
      output.DBScript = await objSchemaDiff.SQLScript(this.getDefaultTrackingCols())
      output.TableSchema = this.StageTableSchema
      output.TableName = stgTblPrefix
      // save file
      if (IsValidString(this.S3OutputBucket) && IsValidString(output.DBScript)) {
        output.S3FilePath = await SaveStringToS3File({
          S3OutputBucket: this.S3OutputBucket,
          S3OutputKey: this.S3OutputKeyPrefix,
          StringData: output.DBScript,
          AppendDateTimeToFileName: true,
          Overwrite: 'yes',
          FileExtension: '.sql',
        })
      }
    } catch (err) {
      this.LogMsg(`Error in getting Stage table script: ${err.message}`, 'error')
      throw new Error(`Error in getting Stage table script: ${err.message}`)
    }
    return output
  }

  async getTableJsonSchema(stgTableSchemaPath) {
    // extract the schema for given object
    if (this._JsonFroms3SchemaFile && stgTableSchemaPath) {
      // strip the first part
      const [, ...pathNoRoot] = stgTableSchemaPath.split('.')
      const opts = { ExcludeObjects: true, ExcludeArrays: true }
      const schemaByDataResp = GetSchemaOfSimplePropByDataPath(
        this._JsonFroms3SchemaFile,
        pathNoRoot.join('.'),
        opts
      )
      const schema = schemaByDataResp.Schema
      this.LogMsg(
        `Stage Table Prefix: ${stgTableSchemaPath}, Found in Schema: ${!_.isUndefined(schema)}`
      )
      if (!_.isUndefined(schema)) {
        if (schema['type'] === 'array') {
          return { Schema: schema.items, HadNestedProperties: schemaByDataResp.HadNestedProperties }
        } else {
          return { Schema: schema, HadNestedProperties: schemaByDataResp.HadNestedProperties }
        }
      } else {
        throw new Error(`Table schema at path: ${stgTableSchemaPath} is not Found in JSON Schema`)
      }
    } else {
      throw new Error(
        `Either No JSON in file: ${
          this.S3SchemaFile
        } or schema path is empty: ${stgTableSchemaPath}`
      )
    }
  }

  async ApplyScriptsToDB(dbDiffScript) {
    try {
      if (IsValidString(dbDiffScript)) {
        const qParams = {
          Query: dbDiffScript,
          ConnectionString: this.DBConnection,
          BatchKey: this.BatchKey,
        }
        const dbResp = await executeCommand(qParams)
        if (!dbResp.completed || !_.isUndefined(dbResp.error)) {
          throw new Error(
            `Error updating SQL Table: ${this.StageTableName}, error: ${dbResp.error.message}`
          )
        }
      } else {
        throw new Error('Invalid Parameters to Apply scripts.')
      }
    } catch (err) {
      this.LogMsg(`Error in ApplyScriptsToDB: ${err.message}`, 'error')
      throw new Error(`Error in ApplyScriptsToDB: ${err.message}`)
    }
  }

  async CopyDataToStage() {
    let rowCnt = 0
    try {
      const knexTable = new KnexTable({
        TableName: this.StageTableName,
        TableSchema: this.StageTableSchema,
        ConnectionString: this.DBConnection,
      })
      const blnExists = await knexTable.TableExists()
      if (blnExists) {
        rowCnt = await knexTable.CopyDataFromPreStage({
          PreStageTableName: this.RawTableName,
          DataPipeLineTaskQueueId: this.BatchKey,
        })
        if (!_.isUndefined(rowCnt) && rowCnt > 0) {
          return rowCnt
        } else {
          throw new Error(
            `Data Load to Table: ${this.StageTableName} completed but didn't load data!`
          )
        }
      } else {
        throw new Error(`Table: ${this.StageTableName} does not exists in DBConnection`)
      }
    } catch (err) {
      this.LogMsg(`Error in CopyDataToStage script: ${err.message}`, 'error')
      throw new Error(`Error in CopyDataToStage script: ${err.message}`)
    }
  }

  IsValidParam() {
    if (_.size(this.StageTableSchema) == 0) {
      throw new Error(`Invalid Param StageTableSchema is required.`)
    }
    if (_.size(this.StageTableName) == 0) {
      throw new Error(`Invalid Param StageTablePrefix is required.`)
    }
    if (_.size(this.S3SchemaFile) == 0) {
      throw new Error(`Invalid Param S3SchemaFile is required.`)
    }
    if (_.size(this.PathToSchema) == 0) {
      throw new Error(`Invalid Param PathToSchema is required.`)
    }
    if (_.size(this.DBConnection) == 0) {
      throw new Error(`Invalid Param DBConnection is required.`)
    }
    if (_.size(this.RawTableName) == 0) {
      throw new Error(`Invalid Param RawTableName is required.`)
    }
    if (_.size(this.DataTypeKey) == 0) {
      throw new Error(`Invalid Param DataTypeKey is required.`)
    }
    if (this.BatchKey <= 0) {
      throw new Error(`Invalid Param BatchKey is required.`)
    }
    return true
  }

  getDefaultTrackingCols() {
    const defCols = getPreStageDefaultCols()
    const retObj = {
      AddTrackingCols: this.AddTrackingCols,
      AdditionalColumns: defCols,
    }
    return retObj
  }

  LogMsg(msg, level = this.LogLevel) {
    this.logger.log(level, msg)
  }
}
