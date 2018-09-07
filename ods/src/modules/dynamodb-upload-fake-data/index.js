import isEmpty from 'lodash/isEmpty'
import chunk from 'lodash/chunk'
import { format as _format, transports as _transports, createLogger } from 'winston'
import { GetJSONFromS3Path } from '../s3ODS'
import { CleanUpString } from '../../utils/string-utils/index'

const util = require('util')
const awsBatch = require('aws-sdk')
awsBatch.config.update({ region: 'us-west-2' })

const MAX_BATCH_ITEMS = 25

export class FakeDataUploader {
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
    this.targetTable = params.TargetTable || ''
    this.s3DataFilePath = params.S3DataFilePath || ''
    this.action = params.Action || 'put'
    this.continueUpdateOnError = params.ContinueUpdateOnError || true
    this.setDeleteOption(params.DeleteOption)

    this.consoleTransport = new _transports.Console()
    this.consoleTransport.level = params.LogLevel || 'warn'
    this.logger.add(this.consoleTransport)
  }

  get TargetTable() {
    return this.targetTable
  }
  get S3DataFilePath() {
    return this.s3DataFilePath
  }
  get Action() {
    return this.action
  }
  get ContinueUpdateOnError() {
    return this.continueUpdateOnError
  }
  get IsPutRequest() {
    if (this.Action && this.Action === 'put') {
      return true
    }
    return false
  }
  get IsDeleteRequest() {
    if (this.Action && this.Action === 'delete') {
      return true
    }
    return false
  }
  get DeleteOption() {
    return this.deleteOption
  }

  setDeleteOption(opts = {}) {
    const retOpts = {
      KeyName: 'ID',
      KeyNameInFile: 'ID',
    }
    this.deleteOption = {
      ...retOpts,
      KeyName: CleanUpString(opts.KeyName, ''),
      KeyNameInFile: CleanUpString(opts.KeyNameInFile, ''),
    }
  }

  async BatchUpload() {
    this.ValidateParams()
    let retOutput = {
      ItemCountInInput: -1,
      ItemsUpdated: 0,
      BatchErrors: [],
    }
    const allItems = await this.getJsonData()
    // upload if we have some items
    if (allItems && allItems.length > 0) {
      retOutput.ItemCountInInput = allItems.length
      // chunk into smaller arrays
      const batchedItems = chunk(allItems, MAX_BATCH_ITEMS)
      for (const currentBatch in batchedItems) {
        // batchedItems.forEach(async (currentBatch, index) => {
        this.logger.log('debug', `Processing Items in Batch index: ${currentBatch}`)
        try {
          let items
          // get items in json format
          if (this.IsPutRequest) {
            items = this.getPutRequestItems(batchedItems[currentBatch], currentBatch)
          } else if (this.IsDeleteRequest) {
            items = this.getDeleteRequestItems(batchedItems[currentBatch], currentBatch)
          }
          // save the data to dynamo
          await this.batchWrite(items)
          retOutput.ItemsUpdated += items.length
        } catch (err) {
          const e = new Error(`Error in BatchUpload: ${err.message}`)
          this.logger.log('error', e.message)
          if (!this.ContinueUpdateOnError) {
            throw e
          } else {
            retOutput.BatchErrors.push({
              BatchID: currentBatch,
              error: e.message,
            })
          }
        }
        //})
      }
    } else {
      throw new Error(`No items to upload to Target Table:${this.TargetTable}`)
    }
    this.logger.log(
      'info',
      `FakeDataUploader.BatchUpload Output: ${JSON.stringify(retOutput, null, 2)}`
    )
    return retOutput
  }

  ValidateParams() {
    this.logger.log(
      'debug',
      `Target Table: ${this.TargetTable}, S3DataFilePath: ${this.S3DataFilePath}, Action: ${
        this.Action
      }`
    )
    if (this.TargetTable.length <= 0) {
      throw new Error('Invalid Param. Target Table is required to update')
    } else if (this.TargetTable.includes('prod-')) {
      throw new Error(
        `Invalid Param. Cannot upload data to Prod tables. Table: ${this.TargetTable}`
      )
    }
    if (isEmpty(this.S3DataFilePath)) {
      throw new Error('Invalid Param. S3DataFilePath is required for FakeDataUploader')
    }
    if (this.Action.length <= 0) {
      throw new Error('Invalid Param. Action is required and can be either put/delete')
    } else {
      if (this.Action !== 'put' && this.Action !== 'delete') {
        throw new Error(
          `Invalid Param. Action can be either put/delete, provided value: ${this.Action}`
        )
      }
      if (this.Action === 'delete') {
        if (!this.DeleteOption) {
          throw new Error(`Invalid Param. Action is ${this.Action} so DeleteOptions are required`)
        } else if (!this.DeleteOption.KeyName || !this.DeleteOption.KeyNameInFile) {
          throw new Error(
            `Invalid Param. Action is ${this.Action}, DeleteOption is ${
              this.DeleteOption
            }. But KeyName or KeyNameInFile is missing`
          )
        }
      }
    }
  }

  async getJsonData() {
    return GetJSONFromS3Path(this.S3DataFilePath)
  }

  getDeleteRequestItems(batchItems, index) {
    const itemsArray = batchItems.map((item) => {
      return {
        DeleteRequest: {
          Key: {
            [this.DeleteOption.KeyName]: item[this.DeleteOption.KeyNameInFile],
          },
        },
      }
    })
    this.logger.log('debug', `No of items to Delete in Batch: ${index} is : ${itemsArray.length}`)
    return itemsArray
  }

  getPutRequestItems(batchItems, index) {
    const itemsArray = batchItems.map((item) => {
      return {
        PutRequest: {
          Item: item,
        },
      }
    })
    this.logger.log('debug', `No of items to put in Batch: ${index} is : ${itemsArray.length}`)
    return itemsArray
  }

  async batchWrite(items) {
    if (!items) {
      this.logger.log('warn', 'batchWrite was called with empty items')
      return
    }
    const docClient = new awsBatch.DynamoDB.DocumentClient()
    try {
      const params = {
        RequestItems: {
          [this.TargetTable]: items,
        },
      }
      // write items
      this.logger.log(
        'info',
        `About to Write to Table: ${this.TargetTable}, Params Defined: ${params}, Items Count: ${
          Object.keys(params.RequestItems[this.TargetTable]).length
        }`
      )
      const resp = await docClient.batchWrite(params).promise()
      if (resp && resp.UnprocessedItems && resp.UnprocessedItems[this.TargetTable]) {
        if (this.IsPutRequest) {
          this.logger.log(
            'warn',
            `Unprocessed Items in batchWrite/PutRequest. Count: ${
              resp.UnprocessedItems[this.TargetTable].PutRequest.length
            }`
          )
          // recursively calling to process all remaining items
          await docClient.batchWrite(resp.UnprocessedItems[this.TargetTable].PutRequest)
        } else if (this.IsDeleteRequest) {
          this.logger.log(
            'warn',
            `Unprocessed Items in batchWrite/DeleteRequest. Count: ${
              resp.UnprocessedItems[this.TargetTable].PutRequest.length
            }`
          )
          // recursively calling to process all remaining items
          await docClient.batchWrite(resp.UnprocessedItems[this.TargetTable].DeleteRequest)
        }
      }
      this.logger.log('debug', 'Wrote items to table.')
    } catch (err) {
      this.logger.log('error', `Error in items: ${JSON.stringify(items, null, 2)}`)
      throw new Error(`Error in batchWrite: ${err.message}`)
    }
  }
}
