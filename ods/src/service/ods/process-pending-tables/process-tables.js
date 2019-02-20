import odsLogger from '../../../modules/log/ODSLogger'
import { GetPendingPipeLineTables } from '../../../data/ODSConfig/PendingTables/getPendingTables'
import { invokeLambda } from '../../../modules/aws-lambda/invoke-lambda'

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
    await Promise.all(
      pendingTables.map((tableName) => {
        const payLoad = {
          TableName: tableName,
        }
        // find the lambda to invoke
        const lambdaParams = {
          FunctionName: `ods-service-${stg.toLowerCase()}-json-to-psql`,
          region: 'us-west-2',
        }
        odsLogger.log(
          'info',
          ` Now Processing Table: ${tableName} by invoking Lambda: ${JSON.stringify(
            lambdaParams,
            null,
            2
          )}`
        )
        // invoke submit lambda
        return invokeLambda(lambdaParams, payLoad)
      })
    )
    odsLogger.log('info', `Completed Invoking Lambda for All given Tables.`)
  } catch (err) {
    odsLogger.log('error', `Error getting pending tables from DB: ${err.message}`)
    throw err
  }
}
