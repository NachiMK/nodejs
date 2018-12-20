import _ from 'lodash'
import moment from 'moment'
import { invokeLambda } from '../aws-lambda/invoke-lambda'

export async function exportMultipleTables(event = {}) {
  const stg = event.STAGE || process.env.STAGE || 'dev'
  if (!_.isUndefined(event) && !_.isUndefined(event.Tables)) {
    const resp = await Promise.all(
      event.Tables.map((tableName) => {
        const [stgName, tblName] = tableName.split('-')
        const exportParams = {
          DynamoTableName: tableName,
          S3OutputBucket: `${stg.toLowerCase()}-ods-data`,
          S3FilePrefix: `/${tblName}/initial/${moment().format(`DDMMYYYY`)}/${tblName}-`,
          AppendDateTime: true,
          LogLevel: event.LogLevel || 'warn',
          ChunkSize: event.ChunkSize || 25,
          LambdaFunctionToSave: `ods-service-${stg.toLowerCase()}-queue-initial-import`,
        }
        console.log(`Processing Table: ${tableName}, Params:${exportParams}`)
        return invokeLambda(
          {
            FunctionName: `ods-service-${stg.toLowerCase()}-export-dynamo-table`,
            region: 'us-west-2',
          },
          exportParams
        )
      })
    )
    console.log(`Table export results: ${JSON.stringify(resp, null, 2)}`)
  }
}
