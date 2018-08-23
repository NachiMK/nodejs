import odsLogger from '../../../modules/log/ODSLogger'
// import { JsonToCSV } from '../../../modules/json-to-csv';
import { TaskStatusEnum } from '../../../modules/ODSConstants'

export async function DoTaskJsonToCSV(dataPipeLineTaskQueue) {
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
      odsLogger.log('info', 'About to call Json to CSV for:', input)
      const resp = {} // await JsonToCSV(input);

      odsLogger.log('info', 'Response for saving CSV files:', resp)
      extractStatusAndAttributes(resp, dataPipeLineTaskQueue, taskResp)
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name
      taskResp.error = new Error(
        `Unknown Error calling module to do task. Retry Process. Error: ${err.message}`
      )
    }
  }
  return taskResp
}

function extractStatusAndAttributes(moduleResponse, task, taskResponse) {
  if (IsStatusSuccess(moduleResponse)) {
    // completed successfully
    // get file as well
    if (moduleResponse.files) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name
      taskResponse.error = undefined
      task.TaskQueueAttributes.CSVFiles = moduleResponse.files
    } else {
      taskResponse.Status = TaskStatusEnum.Error.name
      taskResponse.error = new Error(
        'Json to CSV returned Success, but S3CSVFiles path is missing.'
      )
    }
  } else {
    // throw an error
    taskResponse.Status = TaskStatusEnum.Error.name
    taskResponse.error = new Error(
      `Saving Json to CSV Failed. Retry Process. Error: ${moduleResponse.error}`
    )
  }
}

function getInput(task) {
  const s3FileKeyPrefix = task.getTaskAttributeValue('Prefix.CSVFile')
  const indexOfPrefix = s3FileKeyPrefix.lastIndexOf('/')
  const myFilePrefix = s3FileKeyPrefix.substr(
    indexOfPrefix + 1,
    s3FileKeyPrefix.length - indexOfPrefix
  )

  const input = {
    Datafile: task
      .getTaskAttributeValue('S3CSVBucketName')
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    FilePrefix: myFilePrefix,
    Output: `s3://${task.getTaskAttributeValue('S3CSVBucketName')}/${s3FileKeyPrefix.replace(
      myFilePrefix,
      ''
    )}`,
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
