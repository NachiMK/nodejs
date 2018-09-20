import _ from 'lodash'
import odsLogger from '../../../modules/log/ODSLogger'
import { TaskStatusEnum } from '../../../modules/ODSConstants'
import { OdsCsvToPreStage } from '../../../controller/ods-csv-to-prestage'

export async function DoTaskCsvToPreStage(dataPipeLineTaskQueue) {
  const taskResp = {}
  if (dataPipeLineTaskQueue) {
    try {
      odsLogger.log('info', 'About to call CSV To Postgres RAW:', dataPipeLineTaskQueue)
      const objCsvToPostgresRaw = new OdsCsvToPreStage(dataPipeLineTaskQueue)
      const loadresp = await objCsvToPostgresRaw.SaveFilesToDatabase()

      odsLogger.log('debug', 'Response for saving to postgres:', loadresp)
      extractStatusAndAttributes(loadresp, dataPipeLineTaskQueue, taskResp)
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name
      taskResp.error = objCsvToPostgresRaw.error
        ? objCsvToPostgresRaw.error
        : new Error(`Unknown Error: ${err.message}`)
      odsLogger.log('error', taskResp.error.message)
    }
  } else {
    taskResp.Status = TaskStatusEnum.Error.name
    taskResp.error = new Error(`Invalid Data Pipe Line Task Queue: ${dataPipeLineTaskQueue}`)
    odsLogger.log('error', taskResp.error.message)
  }
  return taskResp
}

function extractStatusAndAttributes(moduleResponse, task, taskResponse) {
  if (IsStatusSuccess(moduleResponse)) {
    // completed successfully
    // get file as well
    const fileList = moduleResponse.fileList
    if (fileList && fileList.length > 0) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name
      taskResponse.error = undefined
      _.forEach(fileList, (saveFileResult, fileIndexKey) => {
        console.log('fileOutput forloop:', JSON.stringify(saveFileResult, null, 2))
        console.log('fileIndexKey forloop:', fileIndexKey)
        task.TaskQueueAttributes[`${fileIndexKey}.S3JsonSchemaFilePath`] =
          saveFileResult.S3JsonSchemaFilePath
        task.TaskQueueAttributes[`${fileIndexKey}.S3DBSchemaFilePath`] =
          saveFileResult.S3DBSchemaFilePath
        task.TaskQueueAttributes[`${fileIndexKey}.TableName`] = saveFileResult.TableName
        task.TaskQueueAttributes[`${fileIndexKey}.TableCreated`] = saveFileResult.TableCreated
        task.TaskQueueAttributes[`${fileIndexKey}.RowCount`] = saveFileResult.RowCount
      })
    } else {
      taskResponse.Status = TaskStatusEnum.Error.name
      taskResponse.error = new Error(
        'CSV to PreStage returned Success, but Pre-stage table names are missing.'
      )
    }
  } else {
    // throw an error
    taskResponse.Status = TaskStatusEnum.Error.name
    taskResponse.error = new Error(
      `Saving Csv to Prestage Failed. Retry Process. Error: ${moduleResponse.error}`
    )
  }
}

function getStatusMessage(resp) {
  if (resp && resp.status && resp.status.message) {
    return resp.status.message.toUpperCase()
  }
  return ''
}

function IsStatusSuccess(resp) {
  return getStatusMessage(resp) === 'SUCCESS'
}
