import _ from 'lodash'
import AWS from 'aws-sdk'
import hash from 'object-hash'
import table from '@hixme/tables'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { SaveJsonToS3File } from '../s3ODS/index'
import { invokeLambda } from '../aws-lambda/invoke-lambda'

const AwsExpDynamoDB = new AWS.DynamoDB({ region: 'us-west-2' })
const DEFAULT_RECORD_CREATION = '01/01/2016'
const DEFAULT_SCAN_LIMIT = 10000
const DEFAULT_ROWS_PER_FILE = 100
const DEFAULT_EXP_LOGLEVEL = 'warn'
const DEFAULT_MAX_LAMBDA_RECURSION = 5000

/**
 * @class ExportTableToS3
 * @classdesc This class takes in a dynamo table name, gets all records, chunks and saves them to multiple s3 files.
 *
 * When creating a new object send in the following params
 * @param {string} S3OutputBucket - Path where the output JSON files should be stored
 * @param {string} S3OutputKeyPrefix - Prefix of the JSON file /path/filename-12.csv
 * @param {LogLevel} LogLevel - Level of logging to be done. Logging is done to Console using Winston
 * @param {bool} AppendDateTime  - Flag to indicate if we should append date time to file name
 * @param {int} ChunkSize - Number of records per file. If none then default is 25
 *
 * @throws : Invalid data/Invalid Param errors
 */
export class ExportDynamoTableToS3 {
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
    this.dynamoTable = params.DynamoTableName || ''
    this.s3OutputBucket = params.S3OutputBucket || ''
    this.s3FilePrefix = params.S3FilePrefix || ''
    this.appendDateTime = params.AppendDateTime || true
    this.loglevel = params.LogLevel || DEFAULT_EXP_LOGLEVEL
    this.rowsPerFile = !isNaN(parseInt(params.RowsPerFile))
      ? params.RowsPerFile
      : DEFAULT_ROWS_PER_FILE
    this.defaultRecordCreatedDtTm = !isNaN(Date.parse(params.DefaultRecordCreated))
      ? new Date(Date.parse(params.DefaultRecordCreated))
      : new Date(Date.parse(DEFAULT_RECORD_CREATION))
    // key to start downloading from
    this.lastEvaluatedKey = params.LastEvaluatedKey || ''
    // should we save outcome to DB
    this.lambdaToSave = params.LambdaFunctionToSave || process.env.LambdaFunctionToSave || ''
    // initialize non params
    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel || DEFAULT_EXP_LOGLEVEL
    this.logger.add(this.consoleTransport)
  }

  ParamsToString() {
    return `
    dynamoTable: ${this.dynamoTable}
    s3OutputBucket: ${this.s3OutputBucket}
    s3FilePrefix: ${this.s3FilePrefix}
    appendDateTime: ${this.appendDateTime}
    loglevel: ${this.loglevel}
    RowsPer File: ${this.rowsPerFile}
    defaultRecordCreatedDtTm: ${this.defaultRecordCreatedDtTm}
    lastEvaluatedKey: ${this.lastEvaluatedKey}
    `
  }

  IsValidParams() {
    if (_.isUndefined(this.dynamoTable) || _.size(this.dynamoTable) <= 0) {
      throw new Error(`Invalid Param. params.DynamoTableName is required.`)
    }
    if (!_.isArray(this.dynamoTable.split('-'))) {
      throw new Error(`Invalid Param. params.DynamoTableName should be like prod-sourceTable.`)
    }
    if (_.isEmpty(this.s3OutputBucket)) {
      throw new Error(`Invalid Param. params.S3OuputBucket is required to write files to S3`)
    }
    if (_.isEmpty(this.s3FilePrefix)) {
      throw new Error(`Invalid Param. params.S3FilePrefix is required to write files to S3`)
    }
    this.logger.log('debug', `All Parameters are valid ${this.ParamsToString()}`)
  }

  async Export(exportParams = {}) {
    this.logger.log('info', `Export Started for ${this.dynamoTable}, Params: ${exportParams}`)
    const { LastEvaluatedKey, StartIndex = 1, ScanLimit = DEFAULT_SCAN_LIMIT } = exportParams
    this.IsValidParams()
    const [prefix, ...tblNameArray] = this.dynamoTable.split('-')
    const sourceTable = tblNameArray.join('-')
    this.logger.log('debug', `Prefix: ${prefix}, sourceTable: ${sourceTable}`)

    const lastKey = !_.isUndefined(LastEvaluatedKey) ? LastEvaluatedKey : undefined
    const startIndex = !isNaN(parseInt(StartIndex)) ? StartIndex : 1

    try {
      // use @hixme/table Create function to get a handler to dynamo table
      const hixmeTable = table.create(sourceTable, { tablePrefix: prefix })
      // this may take a while if the table is too big
      this.logger.log(
        'info',
        `Getting All data for ${this.dynamoTable}. hixmeTable: ${hixmeTable}...`
      )
      const scanResp = await hixmeTable.getAll({
        ExclusiveStartKey: lastKey,
        MaxLimit: ScanLimit,
      })
      const creationTime = await this.getTableCreationTime(this.dynamoTable)
      this.logger.log(
        'info',
        `Received Data from dynamo table ${this.dynamoTable}, Records: ${_.size(scanResp.Items)}`
      )
      const chunkResults = await this.chunkAndSave(
        scanResp.Items,
        sourceTable,
        creationTime,
        startIndex
      )
      const saveResult = {
        [this.dynamoTable]: {
          TotalRecords: _.size(scanResp.Items),
          Files: chunkResults,
        },
      }
      this.logger.log('debug', `Export -> saveResults:`, saveResult)

      // If a lambda is provided to queue imports then call it.
      const savedbResp = await this.saveToDatabase(saveResult)

      // let us split the data into smaller chunk files and save to s3
      return { LastEvaluatedKey: scanResp.LastEvaluatedKey, SaveResponse: savedbResp }
    } catch (err) {
      const e = new Error(`Error exporting Json data from dynamo to S3: ${err.message}`)
      this.logger.log('error', e.message)
      throw e
    }
  }

  async saveToDatabase(saveResult) {
    try {
      // If a lambda is provided to queue imports then call it.
      if (!_.isUndefined(this.lambdaToSave) && this.lambdaToSave.length > 0) {
        const lambdaParams = {
          FunctionName: this.lambdaToSave,
          region: 'us-west-2',
        }
        // if we have way too many files, then let us chunk it
        if (_.size(saveResult[Object.keys(saveResult)[0]].Files) > 0) {
          // chunk only if too big (like more than 100 items)
          const fileChunks = _.chunk(saveResult[Object.keys(saveResult)[0]].Files, 100)
          if (_.size(fileChunks) > 0) {
            const dbTblName = this.dynamoTable
            this.logger.log('info', `Number of Lambda Calls: ${_.size(fileChunks)}`)
            const fileChunkSaveResult = await Promise.all(
              fileChunks.map(async (files) => {
                this.logger.log('debug', `Files in current batch: ${_.size(files)}`)
                const currentChunk = {
                  [dbTblName]: {
                    TotalRecords: _.size(files),
                    Files: files,
                  },
                }
                const lambdaCallResp = await invokeLambda(lambdaParams, currentChunk)
                currentChunk.CalledLambda = !_.isUndefined(lambdaCallResp) ? 'Yes' : 'No'
                currentChunk.LambdaResponse = lambdaCallResp
                this.logger.log('debug', `currentChunk: ${JSON.stringify(currentChunk, null, 2)}`)
                return currentChunk
              })
            )
            return fileChunkSaveResult
          }
        }
      } else {
        // no lambda was provided so return the results that was sent in.
        return saveResult
      }
    } catch (err2) {
      saveResult.CalledLambda = 'No-Errored'
      saveResult.LambdaResponse = { ErrorMessage: err2.message }
      this.logger.log(
        'error',
        `Error in calling Lambda: ${this.lambdaToSave}, error: ${err2.message}`
      )
    }
  }

  async chunkAndSave(data, sourceTable, creationTime, indexToStart = 1) {
    const arrOfChunks = _.chunk(data, this.rowsPerFile)
    this.logger.log('info', `Total # of Files to Create: ${_.size(arrOfChunks)}`)
    const saveResult = await Promise.all(
      arrOfChunks.map(async (currentChunk, idx) => {
        const startIdx = idx * this.rowsPerFile + indexToStart
        const endIdx = startIdx + _.size(currentChunk) - 1
        this.logger.log('debug', `Processing records from ${startIdx} to ${endIdx}`)
        // save to s3
        const s3Params = {
          S3OutputBucket: this.s3OutputBucket,
          S3OutputKey: `${this.s3FilePrefix}-${startIdx}-to-${endIdx}`,
          AppendDateTimeToFileName: this.appendDateTime,
        }
        const transformedData = this.transformData(currentChunk, sourceTable, creationTime)
        const s3Resp = await SaveJsonToS3File(transformedData, s3Params)
        return {
          SourceEntity: sourceTable,
          StartIndex: startIdx,
          EndIndex: endIdx,
          RowCountInBatch: _.size(currentChunk),
          ImportSequence: indexToStart + idx - 1,
          S3File: s3Resp,
        }
      })
    )
    return saveResult
  }

  transformData(jsonRows, sourceTable, tableCreationTime) {
    const eventReceivedDtTm = tableCreationTime
    if (jsonRows) {
      const retJson = _.map(jsonRows, (row, rowIdx) => {
        const rowkey = this.getRowKey(row)
        const transformedRow = {
          HistoryId: rowkey, //record.eventID,
          HistoryAction: 'INSERT',
          HistoryDate: eventReceivedDtTm.slice(0, 10).replace(/-/gi, ''),
          HistoryCreated: eventReceivedDtTm,
          Rowkey: rowkey,
          SourceTable: sourceTable,
          RecordSeqNumber: 10000000000001,
          ApproximateCreationDateTime: eventReceivedDtTm,
        }
        Object.assign(transformedRow, row)
        return transformedRow
      })
      return retJson
    }
    return []
  }

  async getTableCreationTime(tableName) {
    const params = {
      TableName: tableName,
    }
    try {
      const descTableData = await AwsExpDynamoDB.describeTable(params).promise()
      if (descTableData) {
        return descTableData.Table.CreationDateTime.toISOString()
      }
    } catch (err) {
      this.logger.log('error', `Error finding Table info for Table: ${tableName}`)
      this.logger.log('error', `Error:${err.message}`)
    }
    return this.defaultRecordCreatedDtTm.toISOString()
  }

  getRowKey(item) {
    let retVal
    try {
      if (!_.isUndefined(item) && !_.isUndefined(item.Id)) {
        retVal = item.Id.toString()
        // console.log('id from object', JSON.stringify(retVal))
      } else {
        // some tables have a key that is named *PublicKey/*Name, so for those tables
        // get the value of those keys as the row key
        const publicKeyAttributes = Object.keys(item).filter(
          (keyname) => keyname.match(/PublicKey$/gi) || keyname.match(/Name$/gi)
        )
        if (!_.isUndefined(publicKeyAttributes) && publicKeyAttributes.length > 0) {
          const idColName = publicKeyAttributes[0]
          retVal = item[idColName].toString()
        } else {
          retVal = hash(item, { algorithm: 'md5', encoding: 'base64' })
        }
      }
    } catch (err) {
      this.logger.log(
        'error',
        `Error in Finding "Id" column for Object:.${JSON.stringify(item, null, 2)}`
      )
    }
    return retVal
  }
}

export async function exportDynamoTable(event = {}) {
  try {
    const objExport = new ExportDynamoTableToS3(event)
    const startIdx = !isNaN(parseInt(event.StartIndex)) ? parseInt(event.StartIndex) : 1
    const stg = event.STAGE || process.env.STAGE || 'dev'
    const cnt = event.RecursionCount || 1
    const maxRecursion = event.MaxRecursion || DEFAULT_MAX_LAMBDA_RECURSION
    const scanLimit = event.ScanLimit || DEFAULT_SCAN_LIMIT
    const resp = await objExport.Export({
      LastEvaluatedKey: event.LastEvaluatedKey,
      StartIndex: startIdx,
      ScanLimit: scanLimit,
    })
    if (resp.LastEvaluatedKey && cnt <= maxRecursion) {
      // call lambda again (which basically calls this function again)
      const payload = Object.assign(event, {
        LastEvaluatedKey: resp.LastEvaluatedKey,
        StartIndex: startIdx + event.ScanLimit,
        RecursionCount: cnt + 1,
        MaxRecursion: maxRecursion,
        ScanLimit: scanLimit,
      })
      console.debug(`Processing Table: ${objExport.dynamoTable}, payload:${payload}`)
      resp.RecursiveCallResponse = await invokeLambda(
        {
          FunctionName: `ods-service-${stg.toLowerCase()}-export-dynamo-table`,
          region: 'us-west-2',
        },
        payload
      )
    }
    return resp
  } catch (err) {
    console.log(`error: ${err.message}`)
  }
}
