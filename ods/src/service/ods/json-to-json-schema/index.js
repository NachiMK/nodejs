import odsLogger from '../../../modules/log/ODSLogger';
import JsonSchemaSaver from '../../../modules/json-schema-builder';
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue';
import { TaskStatusEnum } from '../../../modules/ODSConstants';

/**
 * Pick Up Task 
 *    Get my Current Status:
 *      If Ready => Proceed
 *      If On Hold, Processing, or Error => Just return. NO ERRORS.
 *        The parent or caller should do whatever is necessary. It is just this 
 *        task cannot proceed.
 *    Get Task Values (Id)
 *    Update Status as Processing
 *    Get Task Attributes
 * Do the requested Task 
 *    Analyze Response
 *    Update Status (with attribute outcome)
 * Prepare return values
 */
export async function JsonToJsonSchema(task) {
  odsLogger.log('debug', 'Parameter: JsonToJsonSchema:', task);
  const dataPipeLineTaskQueue = task;
  const resp = {
    Status: 'Unknown',
    error: {},
  };
  try {
    // Valid parameter
    ValidateParameter(dataPipeLineTaskQueue);
    // Pickup Task
    const processStatusResp = await dataPipeLineTaskQueue.PickUpTask(true);
    odsLogger.log('debug', `Value after Picking Task: ${JSON.stringify(dataPipeLineTaskQueue, null, 2)}`);

    if (processStatusResp && processStatusResp.Picked) {
      const SaveSchemaResp = await DoTaskSaveJsonSchema(dataPipeLineTaskQueue);
      odsLogger.log('info', 'saveSchema response and Task details:', SaveSchemaResp, dataPipeLineTaskQueue);

      if (SaveSchemaResp && (SaveSchemaResp.Status !== TaskStatusEnum.Processing.name)) {
        // save status
        await dataPipeLineTaskQueue.updateTaskStatus(SaveSchemaResp.Status, SaveSchemaResp.error
          , dataPipeLineTaskQueue.TaskQueueAttributes);
      }

      if (SaveSchemaResp.Status === TaskStatusEnum.Completed.name) {
        resp.Status = 'success';
        resp.error = undefined;
      } else {
        resp.Status = SaveSchemaResp.Status || 'Error';
        resp.error = SaveSchemaResp.error || new Error('Saving Schema didnt complete nor did it throw an Error.');
      }
    } else {
      resp.Status = (processStatusResp && processStatusResp.ExistingStatus) ? processStatusResp.ExistingStatus : 'UNKNOWN.2';
      resp.error = undefined;
    }
  } catch (err) {
    resp.Status = 'Error';
    resp.error = err;
    odsLogger.log('error', `Error Processing JsonToJsonSchema for Task: ${task}, messages: ${err.message}`, err);
  }
  return resp;
}

function ValidateParameter(task) {
  if (task && task instanceof DataPipeLineTaskQueue) {
    if (!task.TableName) {
      throw new Error('Table Name is invalid.');
    }
    if (!task.DataPipeLineTaskQueueId) {
      throw new Error('DataPipeLineTaskQueueId is invalid.');
    }
  } else {
    throw new Error('Task should be of Type DataPipeLineTaskQueue.');
  }
}

async function DoTaskSaveJsonSchema(dataPipeLineTaskQueue) {
  const taskResp = {};
  let input;

  try {
    input = getInput(dataPipeLineTaskQueue);
  } catch (err) {
    taskResp.Status = TaskStatusEnum.Error.name;
    taskResp.error = new Error(`Paramter required to complete task is missing/not formated properly. ${err.message}`);
  }

  if (input) {
    try {
      odsLogger.log('info', 'About to build Schema File for:', input);
      const resp = await JsonSchemaSaver(input);

      odsLogger.log('info', 'Response for saving schema file:', resp);
      extractStatusAndAttributes(resp, dataPipeLineTaskQueue, taskResp);
    } catch (err) {
      taskResp.Status = TaskStatusEnum.Error.name;
      taskResp.error = new Error(`Unknown Error calling module to do task. Retry Process. Error: ${err.message}`);
    }
  }
  return taskResp;
}

function extractStatusAndAttributes(moduleResponse, task, taskResponse) {
  if (IsStatusSuccess(moduleResponse)) {
    // completed successfully
    // get file as well
    if (moduleResponse.file) {
      // save file
      taskResponse.Status = TaskStatusEnum.Completed.name;
      taskResponse.error = undefined;
      task.TaskQueueAttributes.S3SchemaFile = moduleResponse.file;
    } else {
      taskResponse.Status = TaskStatusEnum.Error.name;
      taskResponse.error = new Error('Json Schema Save returned Success, but S3SchemaFile Name is missing.');
    }
  } else {
    // throw an error
    taskResponse.Status = TaskStatusEnum.Error.name;
    taskResponse.error = new Error(`Saving Schema Failed. Retry Process. Error: ${moduleResponse.error}`);
  }
}

function getInput(task) {
  const s3KeySchemaFile = task.getTaskAttributeValue('Prefix.SchemaFile');
  const indexOfPrefix = s3KeySchemaFile.lastIndexOf('/');
  const schemaFilePrefix = s3KeySchemaFile.substr(indexOfPrefix + 1, s3KeySchemaFile.length - indexOfPrefix);

  const input = {
    Datafile: task.getTaskAttributeValue('S3DataFile').replace('https://s3-us-west-2.amazonaws.com/', 's3://'),
    FilePrefix: schemaFilePrefix,
    Output: `s3://${task.getTaskAttributeValue('S3SchemaFileBucketName')}/${s3KeySchemaFile.replace(schemaFilePrefix, '')}`,
    Overwrite: 'yes',
  };

  return input;
}

function getStatusMessage(resp) {
  if (resp && resp.status && resp.status.message) {
    return resp.status.message.toUpperCase();
  }
  return '';
}

function IsStatusSuccess(resp) {
  return getStatusMessage(resp) === 'SUCCESS';
}
