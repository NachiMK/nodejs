import odsLogger from '../../../modules/log/ODSLogger';
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue';
import { TaskStatusEnum } from '../../../modules/ODSConstants';

/**
 * Validate Parameter
 * Pick Up Task 
 *    Get my Current Status:
 *      If Ready => Proceed
 *      If On Hold, Processing, or Error => Just return. NO ERRORS.
 *        The parent or caller should do whatever is necessary.
 *        At this point this task cannot proceed.
 *    Get Task Values (Id)
 *    Update Status as Processing
 *    Get Task Attributes
 * Do the requested Task 
 *    Parse Input, Do Task, Parse and send output back
 * Update Status (with attribute outcome)
 * Prepare return values
 */

export async function ODSTaskFactory(childTaskFunction) {
  // this returns a pointer to a function that takes a parameter named
  // task. Once this pointer is returned, the caller calls this function.
  return async (task) => {
    odsLogger.log('debug', 'Parameter:', task);
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
        const childResp = await childTaskFunction(dataPipeLineTaskQueue);
        odsLogger.log('info', 'Response and Task details:', childResp, dataPipeLineTaskQueue);

        if (childResp && (childResp.Status !== TaskStatusEnum.Processing.name)) {
        // save status
          await dataPipeLineTaskQueue.updateTaskStatus(childResp.Status, childResp.error
            , dataPipeLineTaskQueue.TaskQueueAttributes);
        }

        if (childResp.Status === TaskStatusEnum.Completed.name) {
          resp.Status = 'success';
          resp.error = undefined;
        } else {
          resp.Status = childResp.Status || 'Error';
          resp.error = childResp.error || new Error('Task didnt complete nor did it throw an Error.');
        }
      } else {
        resp.Status = (processStatusResp && processStatusResp.ExistingStatus) ? processStatusResp.ExistingStatus : 'UNKNOWN.2';
        resp.error = undefined;
      }
    } catch (err) {
      resp.Status = 'Error';
      resp.error = err;
      odsLogger.log('error', `Error Processing Task: ${task}, messages: ${err.message}`, err);
    }
    return resp;
  };
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
