import { GetJSONFromS3Path } from '../s3ODS'
import { generateSchema } from './generateJsonSchema'

const name = ''
// const data = require('./clients.json')

describe('ods-schema-builder - Unit Tests', () => {
  it.only('ods-schema-builder Unit test generate schema', async () => {
    const event = await GetJSONFromS3Path(
      's3://dev-ods-data/dynamodb/clients/49/49-clients-Data-20180823_183955032.json'
    )
    generateSchema(name, event)
      .then((res) => {
        console.log('schema:', JSON.stringify(res, null, 2))
        expect(res).toBeDefined()
      })
      .catch((err) => {
        console.log('err', err.message)
        expect(err.message).toBeUndefined()
      })
  })
})
