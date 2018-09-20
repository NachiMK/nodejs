import pickBy from 'lodash/pickBy'
import odsLogger from '../../modules/log/ODSLogger'
import { CsvToPostgres } from '../../modules/csv-to-postgres'
import { getConnectionString } from '../../data/psql'

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
  get S3CSVFileList() {
    if (this.TaskAttributes) {
      const filtered = pickBy(this.TaskAttributes, function(attvalue, attkey) {
        return attkey.match(/S3CSVFile\d+/gi)
      })
      return filtered
    }
    return []
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
      const fileList = this.S3CSVFileList
      if (fileList && Object.keys(fileList).length > 0) {
        odsLogger.log('debug', `CSV File count to process: ${Object.keys(fileList).length}`)
        // Load data (in Parallel, could cause DB issue, need to monitor)
        retSaveFileStatus.fileList = await Promise.all(
          Object.keys(fileList).map(async (fileKey) => {
            const output = {}
            output[fileKey] = await this.saveFile(fileList[fileKey])
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

  async saveFile(csvFile) {
    odsLogger.log('debug', `CSV to Postgres File: ${csvFile}`)
    const event = this.getCsvToPostgresInput(csvFile)
    const objCsvToPsql = new CsvToPostgres(event)
    const resp = await objCsvToPsql.LoadData()
    resp.FileName = csvFile
    odsLogger.log('debug', `Status of CSV to Postgres File: ${csvFile} is ${resp}`)
    return resp
  }

  getCsvToPostgresInput(csvS3FilePath) {
    // strip few parts of CSV file to get the right table name
    // expected file name: 50-53-clients-CSV-2-HixmeAccidentCompositePrices.csv
    const subTableName = csvS3FilePath
      .replace(/(.*)(\d+)-(\d+)-(.+)(-CSV)-/, '')
      .replace('.csv', '')
      .replace('-', '_')
    let tablePrefix = `${this.TaskAttributes['psql.PreStageTable.Prefix']}${subTableName}`
    let s3FilePrefix = `${this.TaskAttributes['Prefix.SchemaFile']}${subTableName}-`
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
        S3OutputBucket: this.TaskAttributes['S3SchemaFileBucketName'],
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
