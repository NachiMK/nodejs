import { GetDynamoTableSchema } from './index'

describe('Dynamo Schema Builder - Integration Tests', () => {
  it.only('Dynamo Schema Bulder should create schema file', async () => {
    //DATA-742
    expect.assertions(2)
    const resp = await GetDynamoTableSchema({ TableName: 'int-carrier-messages' })
    expect(resp.Status).toBe('success')
    expect(resp.Schema).toBeDefined()
    console.log(JSON.stringify(resp.Schema, null, 2))
  })
})
