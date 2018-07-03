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

export async function JsonToPSQL(event = {}) {
  ValidateParameter();
  const {
    TableName,
  } = event;
  try {
    odsLogger.log(`Processing JsonToPSQL for Table: ${TableName}`);
    const PendingTasks = await GetPendingPipeLineTasks({ TableName });
    if (PendingTasks) {
      while (PendingTasks) {
        await ProcessPipeLineTask(PendingTasks.shift());
      }
    } else {
      odsLogger.warn(`No Pending Steps for Table: ${TableName}, Resp:${PendingTasks}`);
    }
  } catch (err) {
    odsLogger.log('error', `Error Processing JSONToPSQL for Table: ${TableName}`, err.message);
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
  const tasks = [
    {
      DataPipeLineTaskQueueId: 12312,
      Name: 'JSON History Data to JSON Schema',
      RunSequence: 2010,
      Status: 'Ready',
    },
  ];

  if (TableName) {
    // do something
  }
  return tasks;
}

async function ProcessPipeLineTask(Task) {
  if (Task) {
    // do something
    // get step name
    // switch or call appropriate lambda/function for next step.
  } else {
    throw new Error('Parameter Task is null.');
  }
}
