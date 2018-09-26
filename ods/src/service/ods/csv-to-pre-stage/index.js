import _ from 'lodash'
import odsLogger from '../../../modules/log/ODSLogger'
import { TaskStatusEnum } from '../../../modules/ODSConstants/index'
import { DynamicAttributeEnum } from '../../../modules/ODSConstants/AttributeNames'
import { OdsCsvToPreStage } from '../../../controller/ods-csv-to-prestage'

export async function DoTaskCsvToPreStage(dataPipeLineTaskQueue) {
  const taskResp = {}
  if (dataPipeLineTaskQueue) {
    const objCsvToPostgresRaw = new OdsCsvToPreStage(dataPipeLineTaskQueue)
    try {
      odsLogger.log('info', 'About to call CSV To Postgres RAW:', dataPipeLineTaskQueue)
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
      _.forEach(fileList, (item) => {
        const csvFileKey = Object.keys(item)[0]
        const saveFileResult = item[csvFileKey]
        task.TaskQueueAttributes[
          `${csvFileKey}.${DynamicAttributeEnum.S3JsonSchemaFilePath.value}`
        ] = saveFileResult[DynamicAttributeEnum.S3JsonSchemaFilePath.value]
        task.TaskQueueAttributes[
          `${csvFileKey}..${DynamicAttributeEnum.S3DBSchemaFilePath.value}`
        ] = saveFileResult[DynamicAttributeEnum.S3DBSchemaFilePath.value]
        task.TaskQueueAttributes[`${csvFileKey}.${DynamicAttributeEnum.PreStageTableName.value}`] =
          saveFileResult[DynamicAttributeEnum.PreStageTableName.value]
        task.TaskQueueAttributes[`${csvFileKey}.${DynamicAttributeEnum.TableCreated.value}`] =
          saveFileResult[DynamicAttributeEnum.TableCreated.value]
        task.TaskQueueAttributes[`${csvFileKey}.${DynamicAttributeEnum.RowCount.value}`] =
          saveFileResult[DynamicAttributeEnum.RowCount.value]
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
