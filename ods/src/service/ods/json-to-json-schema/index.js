import odsLogger from '../../../modules/log/ODSLogger'
import JsonSchemaSaver from '../../../modules/ods-schema-builder'
import { TaskStatusEnum } from '../../../modules/ODSConstants'

export async function DoTaskSaveJsonSchema(dataPipeLineTaskQueue) {
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
      odsLogger.log('info', 'About to build Schema File for:', input)
      const resp = await JsonSchemaSaver(input)

      odsLogger.log('info', 'Response for saving schema file:', resp)
      extractStatusAndAttributes(resp, dataPipeLineTaskQueue, taskResp)
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name
      taskResp.error = new Error(
        `Error calling module to do task. Retry Process. Error: ${err.message}`
      )
    }
  }
  return taskResp
}

function extractStatusAndAttributes(moduleResponse, task, taskResponse) {
  if (IsStatusSuccess(moduleResponse)) {
    // completed successfully
    // get file as well
    if (moduleResponse.file) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name
      taskResponse.error = undefined
      task.TaskQueueAttributes.S3SchemaFile = moduleResponse.file
    } else {
      taskResponse.Status = TaskStatusEnum.Error.name
      taskResponse.error = new Error(
        'Json Schema Save returned Success, but S3SchemaFile Name is missing.'
      )
    }
  } else {
    // throw an error
    taskResponse.Status = TaskStatusEnum.Error.name
    taskResponse.error = new Error(
      `Saving Schema Failed. Retry Process. Error: ${moduleResponse.error}`
    )
  }
}

function getInput(task) {
  const input = {
    Datafile: task
      .getTaskAttributeValue('S3DataFile')
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    S3RAWJsonSchemaFile: task.getTaskAttributeValue('S3RAWJsonSchemaFile'),
    Output: `s3://${task.getTaskAttributeValue(
      'S3SchemaFileBucketName'
    )}/${task.getTaskAttributeValue('Prefix.SchemaFile')}`,
    Overwrite: 'yes',
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
