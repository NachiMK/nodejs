//@ts-check
import { SchemaDiff } from './index'
import { GetJSONFromS3Path } from '../s3ODS'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { getConnectionString } from '../../data/psql/index'

const S3JsonSchemaPath =
  's3://dev-ods-data/unit-test/clients/test-clients-Schema-20180925_154121235.json'

async function testSchemaDiff() {
  getAndSetVarsFromEnvFile(false)
  //@ts-ignore
  const event = require('./event.json')
  event.DBConnection = getConnectionString('odsdynamodb', process.env.STAGE)
  event.JsonSchema = await GetJSONFromS3Path(S3JsonSchemaPath)
  const objDiff = new SchemaDiff(event)

  try {
    const resp = await objDiff.SQLScript()
    console.log('resp', JSON.stringify(resp, null, 2))
    return resp
  } catch (err) {
    console.log('error', err.message)
    throw new Error(err.message)
  }
}

testSchemaDiff()
  .then((res) => {
    console.log('results:', JSON.stringify(res, null, 2))
  })
  .catch((err) => {
    console.log('Error:', JSON.stringify(err.message, null, 2))
  })
