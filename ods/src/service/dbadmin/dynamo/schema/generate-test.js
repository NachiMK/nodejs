import { CreateSchema } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../../env'

const params = {
  DynamoTableSchemaId: 8,
  DataPipeLineTaskId: 107,
  DynamoTableName: 'int-client-benefits',
  S3JsonSchemaPath: 's3://int-ods-data/dynamotableschema/client-benefits-20190125_161542727.json',
}

getAndSetVarsFromEnvFile(false)
CreateSchema(params)
  .then((resp) => {
    console.log(`Resp: ${JSON.stringify(resp, null, 2)}`)
  })
  .catch((err) => {
    console.error(`Error: ${err.message}`)
  })
