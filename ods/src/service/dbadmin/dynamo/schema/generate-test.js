import { CreateSchema } from './index'
import { getAndSetVarsFromEnvFile } from '../../../../../env'

const params = {
  DynamoTableSchemaId: 888,
  DataPipeLineTaskId: 999,
  DynamoTableName: 'int-client-price-points',
  S3JsonSchemaPath: 's3://int-ods-data/dynamotableschema/client-price-points-schema-test.json',
}

getAndSetVarsFromEnvFile(false)
CreateSchema(params)
  .then((resp) => {
    console.log(`Resp: ${JSON.stringify(resp, null, 2)}`)
  })
  .catch((err) => {
    console.error(`Error: ${err.message}`)
  })
