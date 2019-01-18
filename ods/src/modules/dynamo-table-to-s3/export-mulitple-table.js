import _ from 'lodash'
import moment from 'moment'
import { invokeLambda } from '../aws-lambda/invoke-lambda'

export async function exportMultipleTables(event = {}) {
  try {
    const stg = event.STAGE || process.env.STAGE || 'dev'
    if (!_.isUndefined(event) && !_.isUndefined(event.Tables)) {
      const resp = await Promise.all(
        event.Tables.map((tableName) => {
          const [stgName, ...tblNameParts] = tableName.split('-')
          const tblName = tblNameParts.join('-')
          const exportParams = {
            DynamoTableName: tableName,
            S3OutputBucket: `${stg.toLowerCase()}-ods-data`,
            S3FilePrefix: `dynamodb/${tblName}/initial/${moment().format(`DDMMYYYY`)}/${tblName}-`,
            AppendDateTime: true,
            LogLevel: event.LogLevel || 'warn',
            RowsPerFile: event.RowsPerFile || 100,
            LambdaFunctionToSave: `ods-service-${stg.toLowerCase()}-queue-initial-import`,
            RecursionCount: 0,
            MaxRecursion: event.MaxRecursion || 500,
            ScanLimit: event.ScanLimit || 10000,
          }
          console.debug(`Processing Table: ${tableName}, Params:${exportParams}`)
          return invokeLambda(
            {
              FunctionName: `ods-service-${stg.toLowerCase()}-export-dynamo-table`,
              region: 'us-west-2',
            },
            exportParams
          )
        })
      )
      console.info(`Table export results: ${JSON.stringify(resp, null, 2)}`)
      return resp
    }
  } catch (err) {
    console.error(`Error in exporting mulitple tables to JSON. ${err.message}`)
  }
}
