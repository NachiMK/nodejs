import pickBy from 'lodash/pickBy'
import odsLogger from '../../modules/log/ODSLogger'
import { CsvToPostgres } from '../../modules/csv-to-postgres'
import { getConnectionString } from '../../data/psql'
import {
  DynamicAttributeEnum,
  PreDefinedAttributeEnum,
} from '../../modules/ODSConstants/AttributeNames'

export class OdsCsvToPreStage {
  constructor(dataPipeLineTask) {
    this._dataPipeLineTask = dataPipeLineTask
  }
  get DataPipeLineTask() {
    return this._dataPipeLineTask
  }
  get TaskAttributes() {
    return this.DataPipeLineTask.TaskQueueAttributes
  }
  get S3CSVFileObjects() {
    if (this.TaskAttributes) {
      const filtered = pickBy(this.TaskAttributes, function(attvalue, attkey) {
        // Attribute name should in format: S3CSVFile1.CSVFileName or S3CSVFile1.JsonObjectName
        return attkey.match(/S3CSVFile\d+\.{1}.*/gi)
      })
      // Every file has two different information, File name and Json
      // we are going to combine that into one object
      const retCollection = {}
      Object.keys(filtered).map((item) => {
        const [fileCommonKey, AttributeName] = item.split('.')
        if (!retCollection[`${fileCommonKey}`]) {
          retCollection[`${fileCommonKey}`] = {}
        }
        retCollection[`${fileCommonKey}`][`${AttributeName}`] = filtered[item]
      })
      return retCollection
    }
    return {}
  }

  async SaveFilesToDatabase() {
    this.ValidateParam()
    let retSaveFileStatus = {
      status: {
        message: 'processing',
      },
      error: undefined,
    }
    try {
      // get list of files
      const s3CSVFileObjects = this.S3CSVFileObjects
      if (s3CSVFileObjects && Object.keys(s3CSVFileObjects).length > 0) {
        odsLogger.log('debug', `CSV File count to process: ${Object.keys(s3CSVFileObjects).length}`)
        // Load data (in Parallel, could cause DB issue, need to monitor)
        retSaveFileStatus.fileList = await Promise.all(
          Object.keys(s3CSVFileObjects).map(async (fileKey) => {
            const output = {}
            output[fileKey] = await this.saveFile(s3CSVFileObjects[fileKey])
            return output
          })
        )
      } else {
        throw new Error(
          `No Files to Process for PipeLineTaskQueueId: ${
            this.DataPipeLineTask.DataPipeLineTaskQueueId
          }. Check Attributes.`
        )
      }
    } catch (err) {
      retSaveFileStatus.status.message = 'error'
      const e = new Error(`Error in saving CSV files to PSQL. ${err.message}`)
      retSaveFileStatus.error = e
      odsLogger.log('error', e.message)
      // on Error Stop process, undo table creation.
      cleanUpOnError(retSaveFileStatus)
      throw e
    }
    // Return
    retSaveFileStatus.status.message = 'SUCCESS'
    console.log('retSaveFileStatus:', JSON.stringify(retSaveFileStatus, null, 2))
    return retSaveFileStatus

    // helpers
    async function cleanUpOnError(saveFilesOutput) {
      if (saveFilesOutput) {
        // delete table
        // delete s3 files
      }
    }
  }

  ValidateParam() {
    if (!this.DataPipeLineTask) {
      throw new Error(`InValidParam. DataPipeLineTask is required.`)
    }
  }

  async saveFile(csvFileAndKey) {
    const csvFile = csvFileAndKey[DynamicAttributeEnum.csvFileName.value]
    const jsonkey = csvFileAndKey[DynamicAttributeEnum.JsonObjectName.value].replace(/[\W]+/gi, '')
    odsLogger.log('debug', `CSV to Postgres File: ${csvFile}, Json Key: ${{ jsonkey }}`)
    const event = this.getCsvToPostgresInput(csvFile, jsonkey.replace('-', '_'))
    const objCsvToPsql = new CsvToPostgres(event)
    const resp = await objCsvToPsql.LoadData()
    resp.FileName = csvFile
    odsLogger.log('debug', `Status of CSV to Postgres File: ${csvFile} is ${resp}`)
    return resp
  }

  getCsvToPostgresInput(csvS3FilePath, prefix) {
    let tablePrefix = `${
      this.TaskAttributes[PreDefinedAttributeEnum.psqlPreStageTablePrefix.value]
    }${prefix}`
    let s3FilePrefix = `${
      this.TaskAttributes[PreDefinedAttributeEnum.PrefixSchemaFile.value]
    }${prefix}-`
    return {
      S3DataFilePath: csvS3FilePath,
      TableNamePrefix: tablePrefix,
      DBConnection: getConnectionString(
        process.env.ODSDynamoDB || 'odsdynamodb',
        process.env.STAGE
      ),
      BatchId: this.DataPipeLineTask.DataPipeLineTaskQueueId,
      LogLevel: process.env.odsloglevel || 'warn',
      S3Options: {
        SaveIntermediatFilesToS3: true,
        S3OutputBucket: this.TaskAttributes[PreDefinedAttributeEnum.S3SchemaFileBucketName.value],
        S3OutputKeyPrefix: s3FilePrefix,
      },
      DBOptions: {
        TableSchema: 'raw',
        IgnoreColumns: [],
        AppendDateTimeToTable: true,
        AppendBatchId: false,
        DropTableIfExists: true,
      },
    }
  }
}
