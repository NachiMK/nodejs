import { executeQueryRS, executeCommand } from '../../psql/index';
import { CreatingDataPipeLineTaskError } from '../../../modules/ODSErrors/DataPipeLineTaskQueueError';

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
    const batchKey = 1;
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
    console.log(`create DataPipeLinetaskQueue status: ${JSON.stringify(retRS)}`);
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

async function UpdatePipeLineTaskStatus(DataPipeLineTaskQueueId, Status, StatusError = {}) {
  try {
    const params = {
      Status,
      StatusError,
      Query: '',
      DBName: '',
      BatchKey: DataPipeLineTaskQueueId,
    };
    await executeCommand(params);
  } catch (err) {
    console.log(`Error Updating Task Status: ${JSON.stringify(err, null, 2)}`);
  }
}

function getQuery(TableName, RowCount) {
  return `SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('${TableName}', ${RowCount})`;
}

function getDBName(DBName) {
  return ((typeof DBName === 'undefined') || (DBName.Length === 0)) ? 'ODSConfig' : DBName;
}
