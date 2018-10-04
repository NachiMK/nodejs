import odsLogger from '../../../modules/log/ODSLogger'
import { TaskStatusEnum } from '../../../modules/ODSConstants'
import { OdsPreStageToStage } from '../../../controller/ods-prestage-to-stage/index'

export async function DoTaskPreStageToStage(dataPipeLineTaskQueue) {
  const taskResp = {}
  if (dataPipeLineTaskQueue) {
    odsLogger.log('info', 'About to call Pre-Stage To Stage:', dataPipeLineTaskQueue)
    const objPreStageToStage = new OdsPreStageToStage(dataPipeLineTaskQueue)
    try {
      const stgResp = await objPreStageToStage.StageData()

      odsLogger.log('debug', 'Response for saving to postgres stage:', stgResp)
      extractStatusAndAttributes(stgResp, dataPipeLineTaskQueue, taskResp)
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name
      taskResp.error = objPreStageToStage.error
        ? objPreStageToStage.error
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
    taskResponse.Status = TaskStatusEnum.Completed.name
    taskResponse.error = undefined
    Object.assign(task.TaskQueueAttributes, moduleResponse.TaskQueueAttributes)
  } else {
    // throw an error
    taskResponse.Status = TaskStatusEnum.Error.name
    taskResponse.error = new Error(
      `Prestage to Stage Failed. Retry Process. Error: ${moduleResponse.error}`
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
