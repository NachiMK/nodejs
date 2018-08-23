import { GetDynamoTableSchema } from './index'

describe('Dynamo Schema Builder - Integration Tests', () => {
  it.only('Dynamo Schema Bulder should create schema file', async () => {
    const resp = await GetDynamoTableSchema({ TableName: 'prod-clients' })
    expect(resp.Status).toBe('success')
    expect(resp.Schema).toBeDefined()
    console.log(JSON.stringify(resp.Schema, null, 2))
  })
})
