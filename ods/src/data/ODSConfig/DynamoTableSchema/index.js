import moment from 'moment';
import { executeQueryRS, executeCommand } from '../../psql';
import ODSLogger from '../../../modules/log/ODSLogger';
import { DataBaseError } from '../../../modules/ODSErrors/ODSError';

export async function GetDynamoTablesToRefreshSchema() {
  let refreshTableList;
  try {
    const sqlQuery = getTablesToRefreshSchema();
    const dbName = getDBName();
    const batchKey = `RefreshSchema_${moment().format('YYYYMMDD_HHmmssSSS')}`;
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    };
    const retRS = await executeQueryRS(params);
    if (retRS.rows.length > 0) {
      refreshTableList = await Promise.all(retRS.rows.map(async (dataRow) => {
        const retVal = {
          DataPipeLineTaskId: dataRow.DataPipeLineTaskId,
          NextRefreshAt: dataRow.NextRefreshAt,
          ExistingS3Path: dataRow.ExistingS3Path,
        };
        return retVal;
      }));
    } else {
      ODSLogger.log('warn', 'There are NO Tables to refresh:, DB Call returned 0 rows.');
    }
    ODSLogger.log('info', `No Of Tables to Refresh ${refreshTableList.length}`);
    ODSLogger.log('debug', `Pendings Tables to Refresh ${JSON.stringify(refreshTableList, null, 2)}`);
  } catch (err) {
    refreshTableList = [];
    const msg = 'Getting list of tables to refresh schema failed.';
    ODSLogger.log('warn', err.message);
    const er = new DataBaseError(msg, err);
    throw er;
  }

  return refreshTableList;
}

export async function UpdateSchemaFile(taskId, tableName, s3Path) {
  try {
    const params = {
      Query: getUpdateQuery(tableName, s3Path),
      DBName: getDBName(),
      BatchKey: taskId,
    };
    const executeResp = await executeCommand(params);
    if (executeResp && executeResp.error) {
      throw new Error(executeResp.error.message);
    }
    return executeResp.completed;
  } catch (err) {
    ODSLogger.log('warn', 'Error updating Dynamo Table Schema: %j', err);
    throw new DataBaseError(`Error updating Dynamo Table Schema: ${err.message}`);
  }
}

function getTablesToRefreshSchema() {
  return 'SELECT * FROM ods."udf_GetDynamoTablesToRefresh"()';
}

function getUpdateQuery(tableName, s3Path) {
  return `SELECT ods.udf_UpdateDynamTableSchemaPath('${tableName}', '${s3Path}')`;
}

function getDBName(DBName = '') {
  return ((typeof DBName === 'undefined') || (DBName.length === 0)) ? 'ODSConfig' : DBName;
}
