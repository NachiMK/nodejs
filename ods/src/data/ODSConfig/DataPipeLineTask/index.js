import moment from 'moment';
import _ from 'lodash';
import { executeQueryRS, executeCommand, executeScalar } from '../../psql';
import { CreatingDataPipeLineTaskError, GettingPendingTaskError, GetTaskAttributeError } from '../../../modules/ODSErrors/DataPipeLineTaskQueueError';
import ODSLogger from '../../../modules/log/ODSLogger';
import { DataBaseError } from '../../../modules/ODSErrors/ODSError';

export {
  createDynamoDBToS3PipeLineTask,
  UpdatePipeLineTaskStatus,
  createDataPipeLineTaskProcessHistory,
};

async function createDynamoDBToS3PipeLineTask(TableName, RowCount) {
  let DataFilePrefix;
  let S3DataFileBucketName;
  let DataPipeLineTaskQueueId;

  try {
    const sqlQuery = getQuery(TableName, RowCount);
    const dbName = getDBName();
    const batchKey = `${TableName}_${RowCount}_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      DataFilePrefix = retRS.rows[0].DataFilePrefix;
      S3DataFileBucketName = retRS.rows[0].S3DataFileBucketName;
      DataPipeLineTaskQueueId = retRS.rows[0].DataPipeLineTaskQueueId;
    } else {
      throw new Error('Error creating DataPipeLineTaskQueue, DB Call returned 0 rows.');
    }
    ODSLogger.log('info', 'create DataPipeLinetaskQueue status: %j', retRS);
  } catch (err) {
    const msg = `Issue creating DataPipeLineTaskQueueId for Table: ${TableName} with Rows: ${RowCount}`;
    const er = new CreatingDataPipeLineTaskError(msg, err);
    throw er;
  }

  const RetResp = {
    DataFilePrefix,
    S3DataFileBucketName,
    DataPipeLineTaskQueueId,
  };

  return RetResp;
}

async function UpdatePipeLineTaskStatus(DataPipeLineTaskQueueId, SaveStatus = {}) {
  try {
    const params = {
      Query: getUpdateQuery(DataPipeLineTaskQueueId, SaveStatus),
      DBName: getDBName(),
      BatchKey: DataPipeLineTaskQueueId,
    };
    const executeResp = await executeCommand(params);
    if (executeResp && executeResp.error) {
      throw new Error(executeResp.error.message);
    }
    return executeResp.completed;
  } catch (err) {
    ODSLogger.log('warn', 'Error updating DataPipeLinetaskQueue status: %j', err);
    throw new DataBaseError(`Error updating DataPipeLinetaskQueue status: ${err.message}`);
  }
}

async function createDataPipeLineTaskProcessHistory(TableName, S3DataPipeLineTaskQueueId) {
  let NewIds = {};
  try {
    const sqlQuery = getProcessHistoryQuery(TableName, S3DataPipeLineTaskQueueId);
    const dbName = getDBName();
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: S3DataPipeLineTaskQueueId,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      NewIds = retRS.rows;
    } else {
      throw new Error('Error creating DataPipeLineTaskQueue for Processing History, DB Call returned 0 rows.');
    }
    ODSLogger.log('info', 'create DataPipeLinetaskQueue status: %j', retRS);
  } catch (err) {
    const msg = `Issue creating DataPipeLineTaskQueueId for Table: ${TableName} with S3DataPipeLineTaskQueueId: ${S3DataPipeLineTaskQueueId}`;
    const er = new CreatingDataPipeLineTaskError(msg, err);
    throw er;
  }

  const RetResp = {
    DataPipeLineTaskQueueID: NewIds,
  };

  return RetResp;
}

export async function GetPendingPipeLineTask(TableName) {
  let pendingTasks;
  try {
    const sqlQuery = getPendingTaskQuery(TableName);
    const dbName = getDBName();
    const batchKey = `${TableName}_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      pendingTasks = await Promise.all(retRS.rows.map(async (dataRow) => {
        const retVal = {
          DataPipeLineTaskQueueId: dataRow.DataPipeLineTaskQueueId,
          Status: dataRow.Status,
          RunSequence: dataRow.RunSequence,
          TaskConfigName: dataRow.TaskConfigName,
        };
        return retVal;
      }));
    } else {
      ODSLogger.log('warn', `There are NO Pending DataPipeLineTask for Table:${TableName}, DB Call returned 0 rows.`);
    }
    ODSLogger.log('info', `No Of Pendings Tasks ${(pendingTasks && pendingTasks.length) ? pendingTasks.length : 0} for Table: ${TableName}`);
    ODSLogger.log('debug', `Pendings Tasks ${JSON.stringify(pendingTasks, null, 2)} for Table: ${TableName}`);
  } catch (err) {
    pendingTasks = [];
    const msg = `Table: ${TableName}`;
    ODSLogger.log('warn', err.message);
    const er = new GettingPendingTaskError(msg, err);
    throw er;
  }
  // sort the array just in case.
  if (pendingTasks) {
    pendingTasks.sort(compareTask);
  }
  return pendingTasks;
}

export async function GetPipeLineTaskQueueAttribute(taskId) {
  let taskAttributes;
  try {
    const sqlQuery = getAttributeQuery(taskId);
    const dbName = getDBName();
    const batchKey = `${taskId}_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      taskAttributes = await Promise.all(retRS.rows.map(async (dataRow) => {
        const retVal = {
          AttributeName: dataRow.AttributeName,
          AttributeValue: dataRow.AttributeValue,
        };
        return retVal;
      }));
    } else {
      ODSLogger.log('warn', `There are NO Attributes for DataPipeLineTask :${taskId}, DB Call returned 0 rows.`);
    }
    ODSLogger.log('info', `No Of Task Attributs ${taskAttributes.length} for Task Id: ${taskId}`);
    ODSLogger.log('debug', `Task Attributes ${JSON.stringify(taskAttributes, null, 2)} for Task Id: ${taskId}`);
  } catch (err) {
    taskAttributes = [];
    const msg = `TaskId: ${taskId}`;
    ODSLogger.log('warn', err.message);
    const er = new GetTaskAttributeError(msg, err);
    throw er;
  }
  return taskAttributes;
}

export async function GetPipeLineTaskStatus(taskId) {
  let statusResp = 'Unknown';
  try {
    const sqlQuery = getCheckTaskStatusQuery(taskId);
    const dbName = getDBName();
    const batchKey = `${taskId}_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeScalar(params);
    ODSLogger.log('debug', `Status Response ${JSON.stringify(retRS, null, 2)} for Task Id: ${taskId}`);
    if (retRS && retRS.completed) {
      statusResp = retRS.scalarValue;
    } else {
      throw new Error(`Status for DataPipeLineTask :${taskId} couldnt be found. Response:${retRS}`);
    }
  } catch (err) {
    statusResp = 'Unknown';
    ODSLogger.log('warn', `Error getting Task Status: ${err.message}`);
    throw err;
  }
  return statusResp;
}

export async function SetPipeLineTaskQueueAttribute(taskId) {
  let taskAttributes;
  try {
    const sqlQuery = getSetAttributeQuery(taskId);
    const dbName = getDBName();
    const batchKey = `${taskId}_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      taskAttributes = await Promise.all(retRS.rows.map(async (dataRow) => {
        const retVal = {
          AttributeName: dataRow.AttributeName,
          AttributeValue: dataRow.AttributeValue,
        };
        return retVal;
      }));
    } else {
      ODSLogger.log('warn', `There are NO Attributes for DataPipeLineTask :${taskId}, DB Call returned 0 rows.`);
    }
    ODSLogger.log('info', `No Of Task Attributs ${taskAttributes.length} for Task Id: ${taskId}`);
    ODSLogger.log('debug', `Task Attributes ${JSON.stringify(taskAttributes, null, 2)} for Task Id: ${taskId}`);
  } catch (err) {
    taskAttributes = [];
    const msg = `TaskId: ${taskId}`;
    ODSLogger.log('warn', err.message);
    const er = new GetTaskAttributeError(msg, err);
    throw er;
  }
  return taskAttributes;
}

function getCheckTaskStatusQuery(taskId) {
  return `SELECT ods."udf_GetDataPipeLineTaskQueueStatus"('${taskId}') as "TaskStatus"`;
}

function getQuery(TableName, RowCount) {
  return `SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('${TableName}', ${RowCount})`;
}

function getDBName(DBName = '') {
  return ((typeof DBName === 'undefined') || (DBName.length === 0)) ? 'ODSConfig' : DBName;
}

function getUpdateQuery(Id, SaveStatus) {
  const status = SaveStatus.Status || 'Unknown';
  const statusError = {};
  if (SaveStatus.Error) {
    statusError.message = SaveStatus.Error.message;
    statusError.stack = SaveStatus.Error.stack;
  }
  // _.pick(SaveStatus, ['KeyName', 'S3BucketName', 'AppendDateTime', 'DateTimeFormat', 'S3DataFile', 'RowCount']);
  const attributes = _.omit(SaveStatus, ['Error', 'Status', 'Input']);
  return `SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(${Id}, '${status}'
  , '${JSON.stringify(statusError, null, 2)}'
  , '${JSON.stringify(attributes, null, 2)}')`;
}

function getSetAttributeQuery(taskId) {
  return `SELECT * FROM ods."udf_SetTaskQueueAttributeLog"(${taskId})`;
}

function getAttributeQuery(taskId, updateAttribute = true) {
  const update = (updateAttribute === true);
  return `SELECT * FROM ods."udf_GetPipeLineTaskQueueAttribute"(${taskId}, ${update})`;
}

function getProcessHistoryQuery(TableName, Id) {
  return `SELECT * FROM ods."udf_createDataPipeLine_ProcessHistory"('${TableName}', ${Id})`;
}

function getPendingTaskQuery(TableName) {
  return `SELECT * FROM ods."udf_GetPendingPipeLineTasks"('${TableName}')`;
}

function compareTask(TaskA, TaskB) {
  if (TaskA.RunSequence < TaskB.RunSequence) return -1;
  if (TaskA.RunSequence > TaskB.RunSequence) return 1;
  return 0;
}
