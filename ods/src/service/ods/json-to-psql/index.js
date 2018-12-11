import { DataPipeLineTaskQueue } from '../../../modules/ODSConfig/DataPipeLineTaskQueue'
/**
 * Converts a given JSON to PSQL Table. Using following tasks
 *
 * Process JSON to Postgres
 *  JSON History Data to JSON Schema
 *  JSON History to Flat JSON
 *  Flat JSON to CSV
 *  CSV to Pre-stage
 *  Pre-Stage to Stage
 *  Stage to Clean
 *
 * Parameter:
 *  Source Entity (Dynamo Table Name)
 *
 * Steps:
 *  - Query DB: Find which step to run
 *  - Based on Step name process.
 *
 * This function may take longer than 5 minutes to run. So
 * be cautious on hosting it in a lambda/api
 *
 */
import odsLogger from '../../../modules/log/ODSLogger'
import { GetPendingPipeLineTask as DataGetPendingPipeLineTask } from '../../../data/ODSConfig/DataPipeLineTask'
import {
  DataPipeLineTaskConfigNameEnum as TaskConfigEnum,
  TaskStatusEnum,
} from '../../../modules/ODSConstants'
import { DoTaskSaveJsonSchema } from '../json-to-json-schema'
import { DoTaskJsonToJsonNormalize } from '../json-to-json-normalize'
import { DoTaskJsonToCSV } from '../json-to-csv'
import { DoTaskCsvToPreStage } from '../csv-to-pre-stage'
import { DoTaskPreStageToStage } from '../psql-pre-stage-to-stage'
import { DoTaskStageToClean } from '../psql-stage-to-clean'
import { ODSPipeLineFactory } from '../PipeLineTaskFactory/index'

const ChildTaskFunctions = {
  [TaskConfigEnum.ProcessJSONToPostgres.name]: ProcessParent,
  [TaskConfigEnum.JSONHistoryDataToJSONSchema.name]: ODSPipeLineFactory(DoTaskSaveJsonSchema),
  [TaskConfigEnum.JSONHistoryToFlatJSON.name]: ODSPipeLineFactory(DoTaskJsonToJsonNormalize),
  [TaskConfigEnum.FlatJSONToCSV.name]: ODSPipeLineFactory(DoTaskJsonToCSV),
  [TaskConfigEnum.CSVToPrestage.name]: ODSPipeLineFactory(DoTaskCsvToPreStage),
  [TaskConfigEnum.PreStagetoStage.name]: ODSPipeLineFactory(DoTaskPreStageToStage),
  [TaskConfigEnum.StageToClean.name]: ODSPipeLineFactory(DoTaskStageToClean),
  default: defaultNotImplementedFunction,
}

export async function JsonToPSQL(event = {}) {
  const { TableName } = event
  const RetResp = {
    Status: 'Started',
    TasksToProcess: -1,
    RemainingTasks: -1,
    error: undefined,
  }
  let PendingTasks
  try {
    ValidateParameter(event)
    odsLogger.log('info', `Processing JsonToPSQL for Table: ${TableName}`)
    // get list of all pending tasks
    PendingTasks = await GetPendingPipeLineTasks({ TableName })
    RetResp.TasksToProcess = PendingTasks && PendingTasks.length ? PendingTasks.length : 0
    if (RetResp.TasksToProcess > 0) {
      // loop through them and process it
      while (PendingTasks.length > 0) {
        const task = PendingTasks.shift()
        task.TableName = TableName
        // process each task
        const resp = await ProcessPipeLineTask(task)
        odsLogger.info(`Response for Processing Task: ${task}, Resp:${resp}`)
        if (resp && resp.Status && resp.Status.toLowerCase() === 'success') {
          // Mark Next step as Ready.
          if (PendingTasks.length > 0) {
            await PendingTasks[0].updateTaskStatus(TaskStatusEnum.Ready.name, undefined)
          }
        } else {
          // quit
          odsLogger.log('warn', `Task: ${task}, didnt complete successfully.`)
          break
        }
      }
      RetResp.Status = 'success'
    } else {
      RetResp.Status = 'warning'
      odsLogger.log('warn', `No Pending Steps for Table: ${TableName}, Resp:${PendingTasks}`)
    }
    RetResp.RemainingTasks = PendingTasks && PendingTasks.length ? PendingTasks.length : 0
  } catch (err) {
    RetResp.RemainingTasks = PendingTasks && PendingTasks.length ? PendingTasks.length : 0
    RetResp.error = err
    RetResp.Status = 'error'
    odsLogger.log(
      'error',
      `Error Processing JSONToPSQL for Table: ${TableName} Error Message:${err.message}`
    )
  }
  return RetResp
}

function ValidateParameter(event) {
  if (event) {
    if (!event.TableName) {
      throw new Error('Table Name is invalid.')
    }
  } else {
    throw new Error('Event details cannot be empty.')
  }
}

async function GetPendingPipeLineTasks(request) {
  const { TableName } = request
  let tasks

  if (TableName) {
    // do something
    tasks = (await DataGetPendingPipeLineTask(TableName)) || []
  }
  return tasks.map((task) => new DataPipeLineTaskQueue(task))
}

async function ProcessPipeLineTask(Task) {
  let resp

  if (Task) {
    odsLogger.log('info', `Processing Task: ${JSON.stringify(Task, null, 2)}`)
    // IF THE parent task is Json-to-psql proceed.
    if (ChildTaskFunctions[Task.TaskConfigName]) {
      try {
        // process child tasks
        // odsLogger.log('info', `ChildTaskFunctions: ${JSON.stringify(ChildTaskFunctions, null, 2)}, Task.TaskConfigName: ${Task.TaskConfigName}`);
        // odsLogger.log('info', `Type Of : ${typeof ChildTaskFunctions[Task.TaskConfigName]}`);
        resp = await (ChildTaskFunctions[Task.TaskConfigName] || ChildTaskFunctions.default)(Task)
      } catch (err) {
        odsLogger.log('error', err.message)
        throw new Error(
          `Error Processing Child Task: ${Task.TaskConfigName} Error Message: ${err.message}`
        )
        // update parent status to Error
      }
    } else {
      throw new Error('Task Config not implemented.', Task)
    }
  } else {
    throw new Error('Parameter Task is null.')
  }
  return resp
}

async function ProcessParent(Task) {
  const resp = {}
  const dataPipeLineTaskQueue = Task
  try {
    // mark as picked up.
    const processStatusResp = await dataPipeLineTaskQueue.PickUpTask()
    if (processStatusResp.Picked) {
      resp.Status = 'success'
      resp.error = undefined
    } else {
      resp.Status = processStatusResp.ExistingTaskStatus || 'UNKNOWN.3'
      resp.error = undefined
    }
  } catch (Err) {
    resp.Status = 'Error'
    resp.error = Err
  }
  return resp
}

async function defaultNotImplementedFunction(Task) {
  throw new Error(`Task Type is invalid: ${Task}`)
}
