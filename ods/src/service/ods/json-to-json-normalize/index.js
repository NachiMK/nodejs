import odsLogger from '../../../modules/log/ODSLogger'
import forIn from 'lodash/forIn'
import { JsonDataNormalizer } from '../../../modules/json-data-normalizer'
import { TaskStatusEnum } from '../../../modules/ODSConstants/index'
import { PreDefinedAttributeEnum } from '../../../modules/ODSConstants/AttributeNames'

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
    if (moduleResponse[PreDefinedAttributeEnum.S3FlatJsonFile.value]) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name
      taskResponse.error = undefined
      task.TaskQueueAttributes.S3UniformJSONFile =
        moduleResponse[PreDefinedAttributeEnum.S3UniformJSONFile.value]
      task.TaskQueueAttributes.S3FlatJsonFile =
        moduleResponse[PreDefinedAttributeEnum.S3FlatJsonFile.value]
      // copy keys and paths
      // Object.assign(task.TaskQueueAttributes, moduleResponse.JsonKeysAndPath)
      const enumFlatkey = PreDefinedAttributeEnum.FlatJsonObjectName.value
      const enumFlatKeyPath = PreDefinedAttributeEnum.FlatJsonSchemaPath.value
      forIn(moduleResponse.JsonKeysAndPath, (val, key) => {
        const [prefix, idx, partialkey] = key.split('.')
        if (enumFlatkey.includes(partialkey)) {
          task.TaskQueueAttributes[`${enumFlatkey.replace('#', idx)}`] = val
        }
        if (enumFlatKeyPath.includes(partialkey)) {
          task.TaskQueueAttributes[`${enumFlatKeyPath.replace('#', idx)}`] = val
        }
      })
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
      .getTaskAttributeValue(PreDefinedAttributeEnum.S3DataFile.value)
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    Overwrite: 'yes',
    S3SchemaFile: task
      .getTaskAttributeValue(PreDefinedAttributeEnum.S3SchemaFile.value)
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    S3OutputBucket: task.getTaskAttributeValue(
      PreDefinedAttributeEnum.S3UniformJSONBucketName.value
    ),
    S3UniformJsonPrefix: task.getTaskAttributeValue(
      PreDefinedAttributeEnum.PrefixUniformJSONFile.value
    ),
    JsonKeysToIgnore: task.getTaskAttributeValue(PreDefinedAttributeEnum.JsonKeysToIgnore.value),
    S3FlatJsonPrefix: task.getTaskAttributeValue(PreDefinedAttributeEnum.PrefixFlatJSONFile.value),
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
