import odsLogger from '../../../modules/log/ODSLogger'
import { TaskStatusEnum } from '../../../modules/ODSConstants'
import { PreDefinedAttributeEnum } from '../../../modules/ODSConstants/AttributeNames'
import { JsonObjectArrayToS3CSV } from '../../../modules/json-object-arrays-to-s3-csv'

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
    odsLogger.log('error', taskResp.error.message)
  }

  if (input) {
    try {
      odsLogger.log('info', 'About to call Json to CSV for:', input)
      const objJsonToCSV = new JsonObjectArrayToS3CSV(input)
      await objJsonToCSV.CreateFiles()

      odsLogger.log('debug', 'Response for saving CSV files:', objJsonToCSV.Output)
      extractStatusAndAttributes(objJsonToCSV, dataPipeLineTaskQueue, taskResp)
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name
      taskResp.error = new Error(`Error in JsonObjectArrayToS3CSV: ${err.message}`)
      odsLogger.log('error', taskResp.error.message)
    }
  }
  return taskResp
}

function extractStatusAndAttributes(moduleResponse, task, taskResponse) {
  if (IsStatusSuccess(moduleResponse.Output)) {
    // completed successfully
    // get file as well
    const fileAndObjectNames = moduleResponse.ProcessedKeyAndFiles()
    if (fileAndObjectNames && fileAndObjectNames.length > 0) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name
      taskResponse.error = undefined
      let idx = 0
      fileAndObjectNames.forEach((element) => {
        Object.assign(task.TaskQueueAttributes, element)
        // task.TaskQueueAttributes[`S3CSVFile${idx}`] = element
        idx += 1
      })
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
      `Saving Json to CSV Failed. Retry Process. Error: ${moduleResponse.Output.error}`
    )
  }
}

function getInput(task) {
  const input = {
    S3DataFilePath: task
      .getTaskAttributeValue(PreDefinedAttributeEnum.S3FlatJsonFile.value)
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    Overwrite: 'yes',
    S3SchemaFile: task
      .getTaskAttributeValue(PreDefinedAttributeEnum.S3SchemaFile.value)
      .replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    S3OutputBucket: task.getTaskAttributeValue(PreDefinedAttributeEnum.S3CSVFilesBucketName.value),
    S3OutputKeyPrefix: task.getTaskAttributeValue(PreDefinedAttributeEnum.PrefixCSVFile.value),
    TableName: task.TableName,
    BatchId: task.DataPipeLineTaskQueueId,
    LogLevel: 'info',
    Options: {
      splitEachArrayToSeparateFile: true,
      appendObjectKeyToFileName: true,
      appendDateTimeToFileName: false,
      dateTimeFormat: 'YYYYMMDD_HHmmssSSS',
      delimiter: ',',
      eol: '\n',
      fileExtentions: '.csv',
    },
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
