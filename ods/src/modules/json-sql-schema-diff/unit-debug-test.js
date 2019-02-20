//@ts-check
import { SchemaDiff } from './index'
import { GetJSONFromS3Path } from '../s3ODS'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { getConnectionString } from '../../data/psql/index'
import { getPreStageDefaultCols } from '../../modules/ODSConstants'

const S3JsonSchemaPath =
  's3://int-ods-data/dynamodb/carrier-messages/10353/10354-10355-carrier-messages-Schema-20190205_145403047.json'

async function testSchemaDiff() {
  getAndSetVarsFromEnvFile(false)
  //@ts-ignore
  const event = require('./event.json')
  event.DBConnection = getConnectionString('odsdynamodb', process.env.STAGE)
  event.JsonSchema = await GetJSONFromS3Path(S3JsonSchemaPath)
  const objDiff = new SchemaDiff(event)

  try {
    const resp = await objDiff.SQLScript({
      AddTrackingCols: true,
      AdditionalColumns: getPreStageDefaultCols(),
    })
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
