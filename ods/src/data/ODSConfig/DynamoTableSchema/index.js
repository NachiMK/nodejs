import moment from 'moment'
import { executeQueryRS, executeCommand } from '../../psql'
import ODSLogger from '../../../modules/log/ODSLogger'
import { DataBaseError } from '../../../modules/ODSErrors/ODSError'

export async function GetDynamoTablesToRefreshSchema(params = {}) {
  const { RefreshAll, RefreshTableList } = params
  let refreshTableList
  try {
    const sqlQuery = getTablesToRefreshSchema(RefreshAll, RefreshTableList)
    const dbName = getDBName()
    const batchKey = `RefreshSchema_${moment().format('YYYYMMDD_HHmmssSSS')}`
    const queryParams = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    }
    const retRS = await executeQueryRS(queryParams)
    if (retRS.rows.length > 0) {
      refreshTableList = await Promise.all(
        retRS.rows.map(async (dataRow) => {
          const retVal = {
            DynamoTableSchemaId: dataRow.DynamoTableSchemaId,
            DataPipeLineTaskId: dataRow.DataPipeLineTaskId,
            DynamoTableName: dataRow.DynamoTableName,
            S3JsonSchemaPath: dataRow.S3JsonSchemaPath,
          }
          return retVal
        })
      )
    } else {
      ODSLogger.log('warn', 'There are NO Tables to refresh:, DB Call returned 0 rows.')
    }
    ODSLogger.log('info', `No Of Tables to Refresh ${refreshTableList.length}`)
    ODSLogger.log(
      'debug',
      `Pendings Tables to Refresh ${JSON.stringify(refreshTableList, null, 2)}`
    )
  } catch (err) {
    refreshTableList = []
    const msg = 'Getting list of tables to refresh schema failed.'
    ODSLogger.log('warn', err.message)
    const er = new DataBaseError(msg, err)
    throw er
  }

  return refreshTableList
}

export async function UpdateSchemaFile(dynamoTableSchemaId, s3Path) {
  try {
    const params = {
      Query: getUpdateQuery(dynamoTableSchemaId, s3Path),
      DBName: getDBName(),
      BatchKey: dynamoTableSchemaId,
    }
    const executeResp = await executeCommand(params)
    if (executeResp && executeResp.error) {
      throw new Error(executeResp.error.message)
    }
    return executeResp.completed
  } catch (err) {
    ODSLogger.log('warn', 'Error updating Dynamo Table Schema: %j', err)
    throw new DataBaseError(`Error updating Dynamo Table Schema: ${err.message}`)
  }
}

function getTablesToRefreshSchema(RefreshAll, RefreshTableList) {
  const refreshall = RefreshAll === true
  const tablelist =
    RefreshTableList && RefreshTableList.length && RefreshTableList.length > 0
      ? RefreshTableList
      : ''
  return `SELECT * FROM ods."udf_GetDynamoTablesToRefresh"('${tablelist}', ${refreshall})`
}

function getUpdateQuery(dynamoTableSchemaId, s3Path) {
  return `SELECT ods."udf_UpdateDynamTableSchemaPath"('${dynamoTableSchemaId}', '${s3Path}')`
}

function getDBName(DBName = '') {
  return typeof DBName === 'undefined' || DBName.length === 0 ? 'ODSConfig' : DBName
}
