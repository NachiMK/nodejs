import moment from 'moment'
import { executeQueryRS } from '../../psql'
import ODSLogger from '../../../modules/log/ODSLogger'

export async function GetPendingPipeLineTables(maxTables = 5) {
  let pendingTables
  try {
    const sqlQuery = getPendingTablesQuery(maxTables)
    const dbName = getDBName()
    const batchKey = `PendingTables_${moment().format('YYYYMMDD_HHmmssSSS')}`
    const params = {
      Query: sqlQuery,
      DBName: dbName,
      BatchKey: batchKey,
    }
    const retRS = await executeQueryRS(params)
    if (retRS.rows.length > 0) {
      pendingTables = await Promise.all(
        retRS.rows.map(async (dataRow) => {
          return dataRow.SourceEntity
        })
      )
    } else {
      ODSLogger.log('warn', `There are NO Pending Tables, DB Call returned 0 rows.`)
    }
    ODSLogger.log(
      'info',
      `No Of Pendings Tables ${pendingTables && pendingTables.length ? pendingTables.length : 0}`
    )
    ODSLogger.log('debug', `Pendings Tables ${JSON.stringify(pendingTables, null, 2)}`)
  } catch (err) {
    pendingTables = []
    const msg = `Error getting Pending Tables, error: ${err.message}`
    ODSLogger.log('warn', msg)
    const er = new Error(msg)
    throw er
  }
  return pendingTables
}

function getPendingTablesQuery(maxTables = 5) {
  const intMax = !isNaN(parseInt(maxTables)) ? parseInt(maxTables) : 5
  return `SELECT * FROM ods."udf_GetPendingPipeLineTables"(${intMax}) as "SourceEntity";`
}

function getDBName(DBName = '') {
  return typeof DBName === 'undefined' || DBName.length === 0 ? 'ODSConfig' : DBName
}
