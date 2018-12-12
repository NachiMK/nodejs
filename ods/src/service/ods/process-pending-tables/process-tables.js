import odsLogger from '../../../modules/log/ODSLogger'
import { invokeLambda } from '../../../modules/aws-lambda/invoke-lambda'

import { GetPendingPipeLineTables } from '../../../data/ODSConfig/PendingTables/getPendingTables'

export async function processPendingTables(event = {}) {
  try {
    const maxTables = event.TableLimit || process.env.TableLimit || 5
    const stg = event.STAGE || process.env.STAGE || 'dev'
    const pendingTables = await GetPendingPipeLineTables(maxTables)
    odsLogger.log(
      'info',
      `Pending Table list returned by DB: ${JSON.stringify(
        pendingTables,
        null,
        2
      )}, now processing them`
    )
    // process these tables
    pendingTables.forEach(async (tableName) => {
      const payLoad = {
        TableName: tableName,
      }
      const params = {
        FunctionName: `ods-service-${stg.toLowerCase()}-json-to-psql`,
        Region: 'us-west-2',
      }
      odsLogger.log(
        'info',
        ` Now Processing Table: ${tableName} by invoking Lambda: ${JSON.stringify(params, null, 2)}`
      )
      await invokeLambda(params, payLoad)
    })
  } catch (err) {
    odsLogger.log('error', `Error getting pending tables from DB: ${err.message}`)
    throw err
  }
}
