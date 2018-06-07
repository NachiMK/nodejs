import moment from 'moment';
import { executeQueryRS, executeCommand } from '../../psql/index';
import { CreatingDataPipeLineTaskError } from '../../../modules/ODSErrors/DataPipeLineTaskQueueError';
import ODSLogger from '../../../modules/log/ODSLogger';

export {
  createDynamoDBToS3PipeLineTask,
  UpdatePipeLineTaskStatus,
};

async function createDynamoDBToS3PipeLineTask(TableName, RowCount) {
  let DataFilePrefix;
  let S3DataFileFolderPath;
  let DataPipeLineTaskQueueId;

  try {
    const sqlQuery = getQuery(TableName, RowCount);
    const dbName = getDBName('ODSConfig');
    const batchKey = `${TableName}_${RowCount}_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      DataFilePrefix = retRS.rows[0].DataFilePrefix;
      S3DataFileFolderPath = retRS.rows[0].S3DataFileFolderPath;
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
    S3DataFileFolderPath,
    DataPipeLineTaskQueueId,
  };

  return RetResp;
}

async function UpdatePipeLineTaskStatus(DataPipeLineTaskQueueId, SaveStatus = {}) {
  try {
    const params = {
      Query: getUpdateQuery(DataPipeLineTaskQueueId, SaveStatus),
      DBName: getDBName('ODSConfig'),
      BatchKey: DataPipeLineTaskQueueId,
    };
    await executeCommand(params);
    return true;
  } catch (err) {
    ODSLogger.log('warn', 'Error updating DataPipeLinetaskQueue status: %j', err);
  }
  return false;
}

function getQuery(TableName, RowCount) {
  return `SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('${TableName}', ${RowCount})`;
}

function getDBName(DBName) {
  return ((typeof DBName === 'undefined') || (DBName.Length === 0)) ? 'ODSConfig' : DBName;
}

function getUpdateQuery(Id, SaveStatus) {
  const status = SaveStatus.Status || 'Unknown';
  const statusError = SaveStatus.Error || {};
  return `SELECT * FROM ods."udf_UpdateDataPipeLineTaskQueueStatus"(${Id}, '${status}', '${JSON.stringify(statusError, null, 2)}')"`;
}
