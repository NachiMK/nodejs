import isEmpty from 'lodash/isEmpty'
import isUndefined from 'lodash/isUndefined'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { SaveStringToS3File } from '../s3ODS/index'
import { IsValidString, CleanUpString } from '../../utils/string-utils/index'

/**
 * @class JsonToS3CSV
 * @classdesc This class takes in a JSON data, converts to CSV and saves to S3
 *
 * When creating a new object send in any of following params
 * @param {string} JsonData - Required. Json data to convert
 * @param {string} S3OutputBucket - Path where the output CSV files should be stored
 * @param {string} S3OutputKeyPrefix - Prefix of the CSV file /path/filename-12.csv
 * @param {LogLevel} LogLevel - Level of logging to be done. Logging is done to Console using Winston
 * @param {object} Options - Various options to create/parse data
 * @param {string} Options.delimiter - column delimiter, defaults to comma, It could be any single character (, or ; or \t or space)
 * @param {string} Options.eol - Row delimiter, defaults to \r
 * @param {string} Options.includeHeader - defualts to true, indicates whether output file should have header
 *
 * @throws : Invalid data/Invalid Param errors
 */
export class JsonToS3CSV {
  output = {
    status: {
      message: 'processing',
    },
    error: undefined,
    S3CSVFile: undefined,
  }
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
    this.s3OutputBucket = params.S3OutputBucket || ''
    this.s3OutputKey = params.S3OutputKey || ''
    this.loglevel = params.LogLevel || 'warn'
    this.inputJsonData = params.JsonData || ''
    this.setOptions(params.Options)
    // initialize non params
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }

  get ModuleError() {
    return this.Output.error
  }
  get ModuleStatus() {
    return this.Output.status.message
  }
  get Output() {
    return this.output
  }
  get S3OUtput() {
    return this.s3Output
  }
  get LogLevel() {
    return this.loglevel
  }
  get S3OutputBucket() {
    return this.s3OutputBucket
  }
  get S3OutputKey() {
    return this.s3OutputKey
  }
  get Options() {
    return this.options
  }
  get InputJsonData() {
    return this.inputJsonData
  }
  setOptions(opts = {}) {
    /**
     * {
     *  delimiter:""
     *  eol:""
     *  fileExtension: ""
     *  includeHeader: true
     * }
     */
    const retOpts = {
      delimiter: ',',
      eol: '\n',
      fileExtension: '.csv',
      includeHeader: true,
    }
    this.options = {
      ...retOpts,

      delimiter: CleanUpString(opts.delimiter, retOpts.delimiter),
      eol: CleanUpString(opts.eol, retOpts.eol),
      fileExtension: CleanUpString(opts.fileExtension, retOpts.fileExtension),
      includeHeader: CleanUpString(opts.includeHeader, retOpts.includeHeader),
    }
  }

  async getCSVData() {
    let csv
    try {
      this.logger.log('info', 'Validating Params')
      this.ValidateParams()
      this.logger.log('info', 'Params are valid')
      // object has any items
      if (!isEmpty(this.InputJsonData)) {
        // process data.
        this.logger.log('info', 'Converting to CSV.')
        csv = await this.convertToCSV()
        this.logger.log('info', 'CSV conversion successfull.')
        this.logger.log('debug', `Data converted to CSV:${csv}`)
      } else {
        this.logger.log('warn', 'Input JsonData had no data.')
        throw new Error(`No data in input Json: ${this.InputJsonData}`)
      }
      this.Output.status.message = 'success'
    } catch (err) {
      this.Output.status.message = 'error'
      this.Output.S3CSVFile = undefined
      this.Output.error = new Error(err.message)
      this.logger.log('error', err.message)
      csv = undefined
      throw new Error(err.message)
    }
    return csv
  }

  ValidateParams() {
    if (isEmpty(this.InputJsonData)) {
      throw new Error('Invalid Param. Please pass valid Json Data')
    }
  }

  async convertToCSV() {
    try {
      this.logger.log('debug', `Data to convert:${JSON.stringify(this.InputJsonData, null, 2)}`)
      if (IsValidString(this.InputJsonData)) {
        const json2csv = require('json2csv').parse
        const opts = {
          delimiter: this.Options.delimiter,
          eol: this.Options.eol,
          header: this.Options.includeHeader,
        }
        return json2csv(this.InputJsonData, opts)
      }
    } catch (err) {
      this.logger.log('error', `Error in json2CSV: ${err.message}`)
      throw new Error(`Error in json2CSV: ${err.message}`)
    }
    return ''
  }

  async SaveCSVToS3() {
    try {
      // validate bucket info and proceed.
      if (
        this.S3OutputBucket &&
        this.S3OutputKey &&
        this.S3OutputBucket.length > 0 &&
        this.S3OutputKey.length > 0
      ) {
        this.logger.log('debug', 'Params are valid to save csv to s3')
        const csvData = await this.getCSVData()
        this.logger.log('debug', 'Got csv data, now going to save it.')
        // if all good and if S3 info to output is provided then save.
        if (csvData) {
          this.logger.log('info', 'Saving file to S3')
          await SaveStringToS3File({
            S3OutputBucket: this.S3OutputBucket,
            S3OutputKey: this.S3OutputKey,
            StringData: csvData,
            FileExtension: this.Options.fileExtension,
            AppendDateTimeToFileName: false,
          })
          this.Output.S3CSVFile = `s3://${this.S3OutputBucket}/${this.S3OutputKey}`
          this.logger.log('debug', 'Saved file to S3 successfully.')
        } else if (this.InputFileHasData) {
          throw new Error('Unknown Error converting to CSV. No CSV data to save to S3')
        }
        this.Output.status.message = 'success'
        this.logger.log('info', 'Done saving csv file to S3.')
      } else {
        throw new Error('S3 Bucket and Key names are required to save data.')
      }
    } catch (err) {
      this.Output.status.message = 'error'
      this.Output.S3CSVFile = undefined
      this.Output.error = new Error(`Error in Saving CSV to S3: ${err.message}`)
      this.logger.log('error', `Error in Saving CSV to S3: ${err.message}`)
      throw this.Output.error
    }
  }
}
