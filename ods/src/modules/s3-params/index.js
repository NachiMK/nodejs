import trim from 'lodash/trim'
import isEmpty from 'lodash/isEmpty'
import moment from 'moment'
import { CleanUpString, IsValidString } from '../../utils/string-utils/index'

/**
 * @class S3Params
 * @classdesc A simple class that is used to gather parameters about files on S3 and outputting files back to S3
 *
 * When creating a new object send in any of following params
 * @param {string} S3DataFilePath - Path where the S3 file that needs to be converted is stored
 * @param {string} S3OutputBucket - Path where the output CSV files should be stored
 * @param {string} S3OutputKeyPrefix - Prefix of the CSV file /path/filename-12.csv
 * @param {object} Options - Various options to create/parse data
 * @param {string} Options.fileExtension - Extension to be given to the file.
 * @param {string} Options.appendDateTimeToFileName - default to true, indicates whether date time should appeneded to file name
 * @param {string} Options.dateTimeFormat - if Options.appendDatetimeToFileName is true then indicate what should be format.
 *                                          Format should be parsed by moment.format function
 */
export class S3Params {
  get S3DataFilePath() {
    return this._s3DataFilePath
  }
  get S3OutputBucket() {
    return this._s3OutputBucket
  }
  get S3OutputKeyPrefix() {
    return this._s3OutputKeyPrefix
  }
  get Options() {
    return this._options
  }
  get FileExtension() {
    return this.Options.fileExtension
  }
  get AppendDateTimeToFileName() {
    return this.Options.appendDateTimeToFileName
  }
  get DateTimeFormat() {
    return this.Options.dateTimeFormat
  }

  constructor(params = {}) {
    this._s3DataFilePath = params.S3DataFilePath || ''
    this._s3OutputBucket = params.S3OutputBucket || ''
    this._s3OutputKeyPrefix = params.S3OutputKeyPrefix || ''
    this.setOptions(params.Options)
  }

  setOptions(opts = {}) {
    /**
     * {
     *  fileExtension: ""
     *  appendDateTimeToFileName: true
     *  dateTimeFormat: "YYYYMMDD_HHmmssSSS"
     * }
     */
    const retOpts = {
      fileExtension: '.json',
      appendDateTimeToFileName: true,
      dateTimeFormat: 'YYYYMMDD_HHmmssSSS',
    }
    this._options = {
      ...retOpts,

      fileExtension: CleanUpString(opts.FileExtension, retOpts.fileExtension),
      appendDateTimeToFileName: CleanUpString(
        opts.AppendDateTimeToFileName,
        retOpts.appendDateTimeToFileName
      ),
      dateTimeFormat: CleanUpString(opts.DateTimeFormat, retOpts.dateTimeFormat),
    }
  }

  ValidateInputFiles() {
    if (!IsValidString(this.S3DataFilePath)) {
      throw new Error('Invalid S3 Param. Please pass valid S3 File')
    }
  }

  ValidateOutputFiles() {
    if (!IsValidString(this.S3OutputBucket)) {
      throw new Error('Invalid S3 Param. Please pass valid S3OutputBucket')
    }
    if (!IsValidString(this.S3OutputKeyPrefix)) {
      throw new Error('Invalid S3 Param. Please pass valid S3OutputKeyPrefix')
    }
  }

  getOutputParams(appendAdditionalKey = '') {
    let keyName = this.S3OutputKeyPrefix
    if (IsValidString(appendAdditionalKey)) {
      keyName = `${keyName}${appendAdditionalKey}`
    }
    keyName = this.getFileName(
      keyName,
      this.FileExtension,
      this.AppendDateTimeToFileName,
      this.DateTimeFormat
    )
    return {
      S3OutputBucket: this.S3OutputBucket,
      S3OutputKey: keyName,
    }
  }

  getFileName(
    Key,
    FileExtension = '.json',
    AppendDtTm = true,
    DateTimeFormat = 'YYYYMMDD_HHmmssSSS'
  ) {
    let filename = trim(Key)

    // add or replace time stamp to file name
    if (AppendDtTm) {
      const timestamp = moment().format(DateTimeFormat)
      if (Key.includes(DateTimeFormat)) {
        filename = Key.replace(`{${DateTimeFormat}}`, timestamp).replace(DateTimeFormat, timestamp)
      } else {
        const timeRegEx = new RegExp(
          `(.*)(${moment().format('YYYY')})(\\d{2})(\\d{2})(_{1})(\\d{9})(.*)`,
          'gim'
        )
        if (!Key.match(timeRegEx)) {
          filename = `${Key}-${timestamp}`
        }
      }
    }

    // add extension
    if (FileExtension && !isEmpty(FileExtension) && !filename.includes(FileExtension))
      filename += FileExtension

    // remove repeatative characters
    filename = filename.replace(/--/gi, '-').replace(/-_/gi, '-')
    return filename
  }
}
