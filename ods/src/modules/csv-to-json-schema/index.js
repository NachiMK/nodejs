import CSVParser from 'csv-parse/lib/sync'
import jsonSchemaGen from 'json-schema-generator'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { GetStringFromS3Path, SaveJsonToS3File } from '../s3ODS/index'
import { S3Params } from '../s3-params/index'

export class CSVToJsonSchema {
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
    this._s3Params = new S3Params(params)
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }

  get S3Parameters() {
    return this._s3Params
  }
  get LogLevel() {
    return this.loglevel
  }

  async getJsonSchemaFromCSV() {
    this.ValidateParams()
    try {
      // Get data from S3
      const inputdata = await GetStringFromS3Path(this.S3Parameters.S3DataFilePath)
      // object has any items
      if (inputdata) {
        const jsondata = CSVParser(inputdata, { columns: true })
        // process data.
        this.logger.log('debug', `CSV Data:${JSON.stringify(jsondata)}`)
        const jsonSchema = jsonSchemaGen(jsondata)
        this.logger.log('debug', `Json Schema from CSV Data:${JSON.stringify(jsonSchema)}`)
        return jsonSchema
      }
    } catch (err) {
      const e = new Error(`Error in getting Json Schema from CSV. ${err.message}`)
      this.logger.log('error', e.message)
      throw e
    }
  }

  async saveJsonSchemaFromCSV() {
    let retFileName
    try {
      // TODO
      this.S3Parameters.ValidateOutputFiles()
      const schema = await this.getJsonSchemaFromCSV()
      if (schema) {
        const { S3OutputBucket, S3OutputKey } = this.S3Parameters.getOutputParams()
        this.logger.log('info', `S3Path: s3://${S3OutputBucket}/${S3OutputKey}`)
        retFileName = await SaveJsonToS3File(schema, {
          S3OutputBucket,
          S3OutputKey,
          AppendDateTimeToFileName: false,
        })
      } else {
        throw new Error('GetJsonSchemaFromCSV didnt throw error or return a schema.')
      }
    } catch (err) {
      // TODO
      const e = new Error(`Error in Saving Schema from CSV. ${err.message}`)
      this.logger.log('error', e.message)
      throw e
    }
    return retFileName
  }

  ValidateParams() {
    this.S3Parameters.ValidateInputFiles()
    // validate the rest of parameters
  }
}
