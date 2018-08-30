import odsLogger from '../../../modules/log/ODSLogger'
import { JsonDataNormalizer } from '../../../modules/json-data-normalizer'
import { TaskStatusEnum } from '../../../modules/ODSConstants'

export async function DoTaskJsonToJsonNormalize(dataPipeLineTaskQueue) {
  const taskResp = {}
  let input

  try {
    input = getInput(dataPipeLineTaskQueue)
  } catch (err) {
    taskResp.Status = TaskStatusEnum.Error.name
    taskResp.error = new Error(
      `Paramter required to complete task is missing/not formated properly. ${err.message}`
    )
  }

  if (input) {
    try {
      odsLogger.log('info', 'About to build Normalized File for:', input)
      const resp = await JsonDataNormalizer(input)

      odsLogger.log('info', 'Response for saving Normalized file:', resp)
      extractStatusAndAttributes(resp, dataPipeLineTaskQueue, taskResp)
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name
      taskResp.error = new Error(`${err.message}`)
    }
  }
  return taskResp
}

function extractStatusAndAttributes(moduleResponse, task, taskResponse) {
  if (IsStatusSuccess(moduleResponse)) {
    // completed successfully
    // get file as well
    if (moduleResponse.S3FlatJsonFile) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name
      taskResponse.error = undefined
      task.TaskQueueAttributes.S3UniformJsonFile = moduleResponse.S3UniformJsonFile
      task.TaskQueueAttributes.S3FlatJsonFile = moduleResponse.S3FlatJsonFile
    } else {
      taskResponse.Status = TaskStatusEnum.Error.name
      taskResponse.error = new Error(
        'Json Normalizer returned Success, but S3UniformJSONFile Name is missing.'
      )
    }
  } else {
    // throw an error
    taskResponse.Status = TaskStatusEnum.Error.name
    taskResponse.error = new Error(
      `Saving Normalized data Failed. Retry Process. Error: ${moduleResponse.error}`
    )
  }
}

function getInput(task) {
  const input = {
    S3DataFile: task
      .getTaskAttributeValue('S3DataFile')
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    Overwrite: 'yes',
    S3SchemaFile: task
      .getTaskAttributeValue('S3SchemaFile')
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    S3OutputBucket: task.getTaskAttributeValue('S3UniformJSONBucketName'),
    S3UniformJsonPrefix: task.getTaskAttributeValue('Prefix.UniformJSONFile'),
    S3FlatJsonPrefix: task.getTaskAttributeValue('Prefix.FlatJSONFile'),
    TableName: task.TableName,
    BatchId: task.DataPipeLineTaskQueueId,
    LogLevel: 'info',
  }

  return input
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
