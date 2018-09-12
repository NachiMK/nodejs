import isEmpty from 'lodash/isEmpty'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { GetJSONFromS3Path, getFileName } from '../s3ODS/index'
import { JsonToS3CSV } from '../json-to-s3-csv'
import { CleanUpString, StringLength } from '../../utils/string-utils/index'

/**
 * @class JsobObjectArrayToS3CSV
 * @classdesc Based on Parameters, converts data in Json file on S3 to mulitple CSV files.
 *
 * When creating a new object send in any of following params
 * @param {string} S3DataFilePath - Path where the S3 file that needs to be converted is stored
 * @param {string} S3OutputBucket - Path where the output CSV files should be stored
 * @param {string} S3OutputKeyPrefix - Prefix of the CSV file /path/filename-12.csv
 * @param {LogLevel} LogLevel - Level of logging to be done. Logging is done to Console using Winston
 * @param {object} Options - Various options to create/parse data
 * @param {string} Options.keysToProcess - List of Keys in S3 Json files that should be parsed to CSV,
 *                                         if no keys are provided then all keys in file are processed
 * @param {string} Options.delimiter - column delimiter, defaults to comma, It could be any single character (, or ; or \t or space)
 * @param {string} Options.eol - Row delimiter, defaults to \r
 * @param {string} Options.appendDateTimeToFileName - default to true, indicates whether date time should appeneded to CSV file name
 * @param {string} Options.dateTimeFormat - if Options.appendDatetimeToFileName is true then indicate what should be format.
 *                                          Format should be parsed by moment.format function
 * @param {string} Options.includeHeader - defualts to true, indicates whether output file should have header
 * @param {string} Options.appendKeyNameToFileName - defaults to true, indicates whether object key should be added to file.
 */
export class JsonObjectArrayToS3CSV {
  output = {
    status: {
      message: 'processing',
    },
    error: undefined,
    keyStatus: undefined,
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
    this.s3DataFilePath = params.S3DataFilePath || ''
    this.s3OutputBucket = params.S3OutputBucket || ''
    this.s3OutputKeyPrefix = params.S3OutputKeyPrefix || ''
    this.loglevel = params.LogLevel || 'warn'
    this.setOptions(params.Options)
    // initialize non params
    this.inputFileHasData = false
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel
    this.logger.add(this.consoleTransport)
  }

  get S3DataFilePath() {
    return this.s3DataFilePath
  }
  get ModuleError() {
    return this.Output.error
  }
  get ModuleStatus() {
    return this.Output.status.message
  }
  /**
   * @property Output
   * This property shows the output after processing this given object
   *
   * This output object has following properties
   * Output.status.message - indicates success for all good, processing or error for failures
   * Output.error - indicates the JS error that was thrown during any processing
   * Output.keyStatus - indicates the keys from input Json that was processed and outcome of each
   *  Output.keyStatus.KeyProcessed - Name of the object key that was processed
   *  Output.keyStatus.status - indicates processing status of this key (processing/success/error/ignored)
   *  Output.keyStatus.csvFileName - Name of CSV file with full S3 path where the data was saved if status is success
   *  Output.keyStatus.error - if any error in processing the key it will be show here, only applicable when status is error
   *
   */
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
  get S3OutputKeyPrefix() {
    return this.s3OutputKeyPrefix
  }
  get InputFileHasData() {
    return this.inputFileHasData
  }
  get Options() {
    return this.options
  }
  get KeysToProcess() {
    return this.options.keysToProcess
  }
  get S3CSVFiles() {
    let fileList = []
    if (this.Output && this.Output.keyStatus)
      fileList = this.Output.keyStatus
        .filter((keystat) => keystat.status === 'success')
        .map((filestat) => filestat.csvFileName)
    return fileList
  }

  /**
   * @function setOptions
   * Sets the following options
   * keysToProcess:""
   * delimiter:""
   * eol:""
   * fileExtension: ""
   * appendDateTimeToFileName: true
   * dateTimeFormat: ""
   * includeHeader: true
   * appendKeyNameToFileName: true
   */
  setOptions(opts = {}) {
    const retOpts = {
      keysToProcess: '',
      delimiter: ',',
      eol: '\n',
      fileExtension: '.csv',
      appendDateTimeToFileName: true,
      dateTimeFormat: 'YYYYMMDD_HHmmssSSS',
      includeHeader: true,
      appendKeyNameToFileName: true,
    }
    this.options = {
      ...retOpts,

      keysToProcess: CleanUpString(opts.keysToProcess, ''),
      delimiter: CleanUpString(opts.delimiter, retOpts.delimiter),
      eol: CleanUpString(opts.eol, retOpts.eol),
      fileExtension: CleanUpString(opts.fileExtension, retOpts.fileExtension),
      appendDateTimeToFileName: CleanUpString(
        opts.appendDateTimeToFileName,
        retOpts.appendDateTimeToFileName
      ),
      dateTimeFormat: CleanUpString(opts.dateTimeFormat, retOpts.dateTimeFormat),
      includeHeader: CleanUpString(opts.includeHeader, retOpts.includeHeader),
      appendKeyNameToFileName: CleanUpString(
        opts.appendKeyNameToFileName,
        retOpts.appendKeyNameToFileName
      ),
    }
  }

  /**
   * @function CreateFiles
   * @async
   *
   * This function creates the CSV files based on given params
   * and Json file.
   *
   * @see classdesc for more information on params.
   *
   * Upon completion this function populates the output object
   *
   * @returns - doesnt technically return anything it only populates. Ouput property.
   * @see Output
   *
   */
  async CreateFiles() {
    try {
      this.logger.log('info', 'Validating Params')
      this.ValidateParams()
      this.logger.log('info', 'Params are valid getting File from S3')
      const inputJson = await GetJSONFromS3Path(this.S3DataFilePath)
      // object has any items
      if (inputJson) {
        this.inputFileHasData = true
        // process data.
        this.logger.log('info', 'Starting split process.')
        let keystoKeep = this.KeysToProcess.split(',')
        const dataKeys = Object.keys(inputJson)
        this.logger.log(
          'info',
          `Keys Length: ${dataKeys.length}, Keys: ${JSON.stringify(dataKeys, null, 2)}`
        )
        if (dataKeys && dataKeys.length > 0) {
          this.Output.keyStatus = await Promise.all(
            dataKeys.map((currentKey, index) => {
              if (
                (Array.isArray(keystoKeep) &&
                  keystoKeep.indexOf(currentKey) > -1 &&
                  StringLength(this.KeysToProcess) > 0) ||
                StringLength(this.KeysToProcess) === 0
              ) {
                this.logger.log(
                  'debug',
                  `Calling CareteFileFromJson for  key: ${currentKey} index: ${index}`
                )
                return this.CreateFileFromJson(currentKey, inputJson[currentKey], index)
              } else
                return {
                  KeyProcessed: currentKey,
                  status: 'ignored',
                  csvFileName: undefined,
                  error: undefined,
                }
            })
          )
        }
        this.logger.log('debug', `Output: ${JSON.stringify(this.Output, null, 2)}`)
        this.logger.log('info', 'CSV conversion successfull.')
      } else {
        this.logger.log('warn', 'Input file had no data.')
        throw new Error(`No data in File: ${this.S3DataFilePath}`)
      }
      this.Output.status.message = 'success'
    } catch (err) {
      this.Output.status.message = 'error'
      this.Output.S3CSVFile = undefined
      this.Output.csvData = undefined
      this.Output.error = new Error(err.message)
      this.logger.log('error', err.message)
      throw this.Output.error
    }
  }

  async CreateFileFromJson(key, data, index) {
    let retStatus = {
      KeyProcessed: `${index}-${key}`,
      status: 'processing',
      csvFileName: undefined,
      error: undefined,
    }
    try {
      this.logger.log('debug', `Creating individual files, current key: ${key}, index:${index}`)
      if (data) {
        const params = this.getParams(`${index}-${key}`)
        params.JsonData = data
        const objJsonToCSV = new JsonToS3CSV(params)
        await objJsonToCSV.SaveCSVToS3()
        if (objJsonToCSV.Output.S3CSVFile) {
          retStatus.csvFileName = objJsonToCSV.Output.S3CSVFile
        } else {
          if (objJsonToCSV.error) {
            throw new Error(objJsonToCSV.Output.error.message)
          } else {
            throw new Error('Unknown Error from JsonToS3CSV')
          }
        }
        retStatus.status = 'success'
      } else {
        this.logger.log('warn', `NO data was passed in for key: ${key}`)
      }
    } catch (err) {
      retStatus.status = 'error'
      retStatus.csvFileName = undefined
      retStatus.error = new Error(`Error: ${err.message} saving data for key:${key} to S3 file`)
    }

    return retStatus
  }

  ValidateParams() {
    if (isEmpty(this.S3DataFilePath)) {
      throw new Error('Invalid Param. Please pass valid S3 File')
    }
    if (isEmpty(this.S3OutputBucket)) {
      throw new Error('Invalid Param. Please pass valid S3OutputBucket')
    }
  }

  getParams(key) {
    let keyName = this.S3OutputKeyPrefix
    if (this.Options.appendKeyNameToFileName) {
      keyName = `${keyName}${key}`
    }
    keyName = getFileName(
      keyName,
      this.Options.fileExtension,
      this.Options.appendDateTimeToFileName,
      this.Options.dateTimeFormat
    )
    return {
      S3OutputBucket: this.S3OutputBucket,
      S3OutputKey: keyName,
      LogLevel: this.LogLevel,
      Options: {
        delimiter: this.Options.delimiter,
        eol: this.Options.eol,
        includeHeader: this.Options.includeHeader,
      },
    }
  }
}
