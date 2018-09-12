import isEmpty from 'lodash/isEmpty'
import timesLimit from 'async/timesLimit'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { SaveStringToS3File, GetJSONFromS3Path } from '../s3ODS/index'

const jsf = require('json-schema-faker')

export class FakeDataGenerator {
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
    this.s3FakerSchemaFile = params.S3FakerSchemaFile || ''
    this.s3OutputBucket = params.S3OutputBucket || ''
    this.s3OutputKey = params.S3OutputKey || ''
    this.loglevel = params.LogLevel || 'warn'
    this.rowsToGenerate = params.RowsToGenerate || '10'

    // initialize non params
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }

  get RowsToGenerate() {
    return this.rowsToGenerate
  }

  get S3FakerSchemaFile() {
    return this.s3FakerSchemaFile
  }

  get S3OutputBucket() {
    return this.s3OutputBucket
  }

  get S3OutputKey() {
    return this.s3OutputKey
  }

  get LogLevel() {
    return this.loglevel
  }

  get ModuleLogger() {
    return this.logger
  }

  /**
   * @function getFakeData
   * @description : returns a Promise that can provide the fake data after resolved.
   * @throws: Invalid Params error or other errors rekated to json schema faker
   *
   * @returns A Promise that can be resolved to actual data. Data will be in JSON format.
   */
  async getFakeData() {
    this.logger.log('info', 'Validating Params')
    this.ValidateParams()
    this.logger.log('info', 'Params are valid')
    const inputJsonData = await GetJSONFromS3Path(this.S3FakerSchemaFile)
    // object has any items
    if (!isEmpty(inputJsonData)) {
      // process data.
      this.logger.log('info', 'Generating Fake Data.')
      return new Promise((resolve, reject) =>
        timesLimit(
          this.RowsToGenerate,
          10,
          async (n) => {
            this.logger.log('debug', `Processing item: ${n}`)
            const retVal = await this.generateFakeData(inputJsonData)
            return retVal
          },
          function(err, data) {
            if (!err) {
              resolve(data)
            } else {
              reject(err)
            }
          }
        )
      )
    } else {
      this.logger.log('error', 'Input Faker Json schema file is empty.')
      throw new Error(`Input Faker Json schema file is empty: ${inputJsonData}`)
    }
  }

  ValidateParams() {
    if (isEmpty(this.S3FakerSchemaFile)) {
      throw new Error('Invalid Param. Please pass valid Json Data')
    }
  }

  async generateFakeData(inputSchema) {
    this.logger.log('debug', `Data to convert:${JSON.stringify(inputSchema, null, 2)}`)
    try {
      jsf.extend('chance', function() {
        const Chance = require('chance')
        let chance = new Chance()
        return chance
      })
      jsf.extend('faker', function() {
        let faker = require('faker')
        return faker
      })
      const retVal = await jsf.resolve(inputSchema)
      return retVal
    } catch (err) {
      this.logger.log('error', `Error in generating fake data: ${err.message}`)
      throw new Error(`Error in generating fake data: ${err.message}`)
    }
  }

  async UploadFakeDataToS3(fakeData) {
    let S3CSVFile
    this.logger.log('debug', 'Got Fake data data, now going to save it.')
    // if all good and if S3 info to output is provided then save.
    if (fakeData) {
      this.logger.log('info', 'Saving file to S3')
      await SaveStringToS3File({
        S3OutputBucket: this.S3OutputBucket,
        S3OutputKey: this.S3OutputKey,
        StringData: JSON.stringify(fakeData),
        FileExtension: '.json',
        AppendDateTimeToFileName: false,
      })
      S3CSVFile = `s3://${this.S3OutputBucket}/${this.S3OutputKey}`
      this.logger.log('debug', 'Saved file to S3 successfully.')
    } else {
      throw new Error(
        'Unknown Error getting fake data. GetFakeData did not throw an error but returned empty object'
      )
    }
    this.logger.log('info', 'Done saving csv file to S3.')
    return S3CSVFile
  }

  async SaveFakeJsonData() {
    let S3CSVFile
    try {
      // validate bucket info and proceed.
      if (
        this.S3OutputBucket &&
        this.S3OutputKey &&
        this.S3OutputBucket.length > 0 &&
        this.S3OutputKey.length > 0
      ) {
        this.logger.log('debug', 'Params are valid to save csv to s3')
        await this.getFakeData()
          .then(async (fakeData) => {
            S3CSVFile = await this.UploadFakeDataToS3(fakeData)
          })
          .catch((err) => {
            throw new Error(`Error getting Fake data: ${err.message}`)
          })
      } else {
        throw new Error('S3 Bucket and Key names are required to save data.')
      }
    } catch (err) {
      const e = new Error(`Error in Saving fake data to S3: ${err.message}`)
      this.logger.log('error', e.message)
      throw e
    }
    return S3CSVFile
  }
}
