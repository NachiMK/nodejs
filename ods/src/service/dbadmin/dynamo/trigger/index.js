import {
  GetDefaultOdsResponse,
  SetOdsResponseStatusToError,
  IsResponseSuccess,
} from '../../../../modules/ODSResponse'
import { DynamoStreamEventsToS3 } from '../../../../modules/dynamo-stream-to-s3'

import {
  createDynamoDBToS3PipeLineTask,
  UpdatePipeLineTaskStatus,
  createDataPipeLineTaskProcessHistory,
} from '../../../../data/ODSConfig/DataPipeLineTask'

import InvalidParameterError from '../../../../modules/ODSErrors/InvalidParameterError'
// import ODSError from '../../../../modules/ODSErrors/ODSError';

import ODSLogger from '../../../../modules/log/ODSLogger'

// dependencies
const _ = require('lodash')
// let AWS = require('aws-sdk');

export const handler = async (event) => {
  let RetError
  let S3BucketName
  const RowCount = _.isArray(event.Records) ? event.Records.length : 0
  const AppendDateTime = true
  const DateTimeFormat = 'YYYYMMDD_HHmmssSSS'
  let FilePrefix
  const defaultResp = await GetDefaultOdsResponse()

  // Parse the triggering tablename (Ex: dev-table-name) from the eventSourceARN
  const firstElement = _.head(event.Records)
  let tableName =
    typeof firstElement !== 'undefined'
      ? firstElement.eventSourceARN.split(':')[5].split('/')[1]
      : undefined
  tableName = tableName
    .replace('prod-', '')
    .replace('int-', '')
    .replace('dev-', '')

  const saveStatus = {
    ...defaultResp,
    S3BucketName: process.env.ODSS3Bucket || `${process.env.STAGE || 'dev'}-ods-data`,
    tableName,
    RowCount,
  }
  // default file prefix,
  FilePrefix = `dynamodb/${tableName}/missed/${getCurrentTime()}-${tableName}-`
  const StreamEventsToS3Params = {
    DynamoStreamEvent: event,
    KeyName: FilePrefix,
    S3BucketName,
    AppendDateTime,
    DateTimeFormat,
    TableName: tableName,
  }

  let pipeLineTaskResp
  try {
    ODSLogger.log('info', `Capturing data for Table:${tableName}, Row Count:${RowCount}`)
    pipeLineTaskResp = await createDynamoDBToS3PipeLineTask(tableName, RowCount)
    FilePrefix = pipeLineTaskResp.DataFilePrefix || FilePrefix
    S3BucketName = pipeLineTaskResp.S3DataFileBucketName || S3BucketName
    StreamEventsToS3Params.KeyName = FilePrefix
    StreamEventsToS3Params.S3BucketName = S3BucketName
  } catch (err) {
    RetError = new Error(`Error creating DatapipeLine Task for ${tableName} 
                    so data was not saved to S3 bucket.
                    error:${JSON.stringify(err, null, 2)}`)
    ODSLogger.log('error', 'Error creating DatapipeLine: %j', RetError)
    await SetOdsResponseStatusToError(saveStatus, RetError)
    // let us save the file to default folder (in async manner)
    SaveDataOnDBFailure(StreamEventsToS3Params)
    return saveStatus
  }

  let saveStreamToS3Resp
  try {
    ODSLogger.log(
      'info',
      `About to Save to S3 TableName: ${tableName}, FilePrefix: ${FilePrefix}, S3BucketName: ${S3BucketName}`
    )
    saveStreamToS3Resp = await DynamoStreamEventsToS3(StreamEventsToS3Params)
    Object.assign(saveStatus, saveStreamToS3Resp)
  } catch (err) {
    if (err instanceof InvalidParameterError) {
      await SetOdsResponseStatusToError(saveStatus, JSON.stringify(err, null, 2))
    } else {
      RetError = new Error(`Unhandled error in calling DynamoStreamEventsToS3 for ${tableName} 
                      to S3 bucket: ${S3BucketName} 
                      with FilePrefix:${FilePrefix}
                      error:${JSON.stringify(err, null, 2)}`)
      ODSLogger.log('error', 'Unhandled error in calling DynamoStreamEventsToS3 %j', RetError)
    }
    await SetOdsResponseStatusToError(saveStatus, RetError)
  }
  const updateResp = await UpdatePipeLineTaskStatus(
    pipeLineTaskResp.DataPipeLineTaskQueueId,
    saveStatus
  )
  ODSLogger.log('info', 'Updated DB Status %j', pipeLineTaskResp)

  if (updateResp && IsResponseSuccess(saveStatus)) {
    const nextStepResp = await createDataPipeLineTaskProcessHistory(
      tableName,
      pipeLineTaskResp.DataPipeLineTaskQueueId
    )
    ODSLogger.log('info', 'Create queue entries', nextStepResp)
  }

  ODSLogger.log('info', 'Completed Saving to S3, savestatus:%j', saveStatus)
  return saveStatus
}

function getCurrentTime() {
  const now = new Date()
  let timestamp = now.getFullYear().toString()
  timestamp += (now.getMonth() < 10 ? '0' : '') + now.getMonth().toString()
  timestamp += (now.getDate() < 10 ? '0' : '') + now.getDate().toString()
  timestamp += (now.getHours() < 10 ? '0' : '') + now.getHours().toString()
  timestamp += (now.getMinutes() < 10 ? '0' : '') + now.getMinutes().toString()
  timestamp += (now.getSeconds() < 10 ? '0' : '') + now.getSeconds().toString()
  timestamp += now.getMilliseconds()
  return timestamp
}

function SaveDataOnDBFailure(params) {
  try {
    DynamoStreamEventsToS3(params)
      .then((res) =>
        ODSLogger.log('error', `DB Tracking Failed. But, Event saved to S3 file.${res}`)
      )
      .catch((res) =>
        ODSLogger.log('error', `DB Tracking failed and Error saving Event to S3 file.${res}`)
      )
  } catch (err) {
    ODSLogger.log('error', `DB Tracking failed and Error saving Event to S3 file.${err}`)
  }
}
