/**
 * Converts a given JSON to PSQL Table. Using following tasks
 * 
 * Process JSON to Postgres
 *  JSON History Data to JSON Schema
 *  JSON History to Flat JSON
 *  Flat JSON to CSV
 *  CSV to Pre-stage
 *  Pre-Stage to RAW
 *  RAW to Clean
 * 
 * Parameter:
 *  Source Entity (Dynamo Table Name)
 * 
 * Steps:
 *  - Query DB: Find which step to run
 *  - Based on Step name process.
 * 
 */
import odsLogger from '../../../modules/log/ODSLogger';
import { GetPendingPipeLineTask as DataGetPendingPipeLineTask } from '../../../data/ODSConfig/DataPipeLineTask/index';
import { DataPipeLineTaskConfigNameEnum as TaskConfigEnum } from '../../../modules/ODSConstants/index';
import { JsonToJsonSchema } from '../json-to-json-schema';
import { JsonToJsonNormalize } from '../json-to-json-normalize';
import { JsonToCSV } from '../json-to-csv';
import { PreStagetoRAW } from '../csv-to-pre-stage-psql';

export async function JsonToPSQL(event = {}) {
  ValidateParameter(event);
  const {
    TableName,
  } = event;
  try {
    odsLogger.log('info', `Processing JsonToPSQL for Table: ${TableName}`);
    const PendingTasks = await GetPendingPipeLineTasks({ TableName });
    if (PendingTasks) {
      while (PendingTasks.length > 0) {
        const task = PendingTasks.shift();
        await ProcessPipeLineTask(task);
      }
    } else {
      odsLogger.log('warn', `No Pending Steps for Table: ${TableName}, Resp:${PendingTasks}`);
    }
  } catch (err) {
    odsLogger.log('error', `Error Processing JSONToPSQL for Table: ${TableName} Error Message:${err.message}`);
  }
}

function ValidateParameter(event) {
  if (event) {
    if (!event.TableName) {
      throw new Error('Table Name is invalid.');
    }
  } else {
    throw new Error('Event details cannot be empty.');
  }
}

async function GetPendingPipeLineTasks(request) {
  const {
    TableName,
  } = request;
  let tasks;

  if (TableName) {
    // do something
    tasks = await DataGetPendingPipeLineTask(TableName);
  }
  return tasks;
}

async function ProcessPipeLineTask(Task) {
  if (Task) {
    odsLogger.log('info', `Processing Task: ${JSON.stringify(Task, null, 2)}`);
    // get step name
    // switch or call appropriate lambda/function for next step.
    const taskConfigName = Task.TaskConfigName;
    const taskParent = getTaskConfigParent(Task.TaskConfigName);
    if (taskParent.localeCompare(TaskConfigEnum.ProcessJSONToPostgres.name)) {
      try {
        switch (taskConfigName) {
          case TaskConfigEnum.JSONHistoryDataToJSONSchema.name:
            await JsonToJsonSchema(Task);
            break;
          case TaskConfigEnum.JSONHistoryToFlatJSON.name:
            await JsonToJsonNormalize(Task);
            break;
          case TaskConfigEnum.JsonToCSV.name:
            await JsonToCSV(Task);
            break;
          case TaskConfigEnum.CSVToPrestage.name:
            await JsonToCSV(Task);
            break;
          case TaskConfigEnum.PreStagetoRAW.name:
            await PreStagetoRAW(Task);
            break;
          // case TaskConfigEnum.RAWToClean:
          //   await RAWToClean(Task);
          //   break;
          default:
            throw new Error(`Unknown Task to process, Task:${Task}`);
        }
        // mark parent as complete if everything went fine
      } catch (err) {
        odsLogger.log('error', err.message);
        // update parent status
      }
    }
  } else {
    throw new Error('Parameter Task is null.');
  }
}
