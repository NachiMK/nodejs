import { JsonDataNormalizer } from './index'

const event = require('./event-int.json')

describe('Json Normalizer - Integration Tests', () => {
  it.only('Json Normalizer should create a file in s3', async () => {
    expect.assertions(3)
    const resp = await JsonDataNormalizer(event)
    console.log('Output', JSON.stringify(resp, null, 2))
    expect(resp.status.message).toBe('success')
    expect(resp.S3UniformJSONFile).toBeDefined()
    expect(resp.S3FlatJsonFile).toBeDefined()
  })
})
