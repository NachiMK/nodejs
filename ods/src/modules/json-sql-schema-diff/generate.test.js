import { SchemaDiff } from './index'
import { GetJSONFromS3Path } from '../s3ODS'
import { getAndSetVarsFromEnvFile } from '../../../env'
import { getConnectionString } from '../../data/psql/index'

const S3JsonSchemaPath =
  's3://dev-ods-data/unit-test/clients/test-clients-Schema-20180925_154121235.json'

describe('SchemaDiff - Unit Tests', () => {
  it.only('SchemaDiff - Table Not Exists', async () => {
    getAndSetVarsFromEnvFile(false)
    const event = require('./event.json')
    event.DBConnection = getConnectionString('odsdynamodb', process.env.STAGE)
    event.JsonSchema = await GetJSONFromS3Path(S3JsonSchemaPath)
    const objDiff = new SchemaDiff(event)

    try {
      expect.assertions(1)
      const resp = await objDiff.SQLScript()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log('error', err.message)
      expect(err).toBeUndefined()
    }
  })
})
