import odsLogger from '../../../modules/log/ODSLogger'
import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
import { TaskStatusEnum } from '../../../modules/ODSConstants'

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

export function ODSPipeLineFactory(childTaskFunction) {
  // this returns a pointer to a function that takes a parameter named
  // task. Once this pointer is returned, the caller calls this function.
  return async (task) => {
    let childResp
    odsLogger.log('debug', 'Parameter:', task)
    const dataPipeLineTaskQueue = task
    const resp = {
      Status: 'Unknown',
      error: undefined,
    }
    try {
      // Valid parameter
      ValidateParameter(dataPipeLineTaskQueue)
      // Pickup Task
      const processStatusResp = await dataPipeLineTaskQueue.PickUpTask(true)
      odsLogger.log(
        'debug',
        `Value after Picking Task: ${JSON.stringify(dataPipeLineTaskQueue, null, 2)}`
      )

      if (processStatusResp && processStatusResp.Picked) {
        childResp = await childTaskFunction(dataPipeLineTaskQueue)
        odsLogger.log('info', 'Response and Task details:', childResp, dataPipeLineTaskQueue)
        // update DB
        await UpdateStatusInDB(childResp, dataPipeLineTaskQueue)
        // set return response
        UpdateReturnResponse(childResp, resp)
      } else {
        resp.Status =
          processStatusResp && processStatusResp.ExistingStatus
            ? processStatusResp.ExistingStatus
            : 'UNKNOWN.2'
      }
    } catch (err) {
      resp.Status = 'Error'
      resp.error = err
      odsLogger.log('error', `Error Processing Task: ${task}, messages: ${err.message}`, err)
      // rare cases we may get error before or right after we call ChildTask function
      // so those cases let us update the DB status
      await UpdateStatusInDB(
        {
          // for now setting to onhold for unknown error.
          // in future this should be an error as well.
          Status: TaskStatusEnum.OnHold.name,
          error: new Error(`Error before calling actual task. ${err.message}`),
        },
        dataPipeLineTaskQueue
      )
    }
    return resp
  }

  async function UpdateStatusInDB(childResp, dataPipeLineTaskQueue) {
    if (childResp && childResp.Status !== TaskStatusEnum.Processing.name) {
      // save status
      await dataPipeLineTaskQueue.updateTaskStatus(
        childResp.Status,
        childResp.error,
        dataPipeLineTaskQueue.TaskQueueAttributes
      )
    }
  }

  function UpdateReturnResponse(childResp, resp) {
    if (childResp.Status === TaskStatusEnum.Completed.name) {
      resp.Status = 'success'
    } else {
      resp.Status = childResp.Status || 'Error'
      resp.error = childResp.error || new Error('Task didnt complete nor did it throw an Error.')
    }
  }
}

function ValidateParameter(task) {
  if (task && task instanceof DataPipeLineTaskQueue) {
    if (!task.TableName) {
      throw new Error('Table Name is invalid.')
    }
    if (!task.DataPipeLineTaskQueueId) {
      throw new Error('DataPipeLineTaskQueueId is invalid.')
    }
  } else {
    throw new Error('Task should be of Type DataPipeLineTaskQueue.')
  }
}
