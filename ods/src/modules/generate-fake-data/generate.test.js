import isArray from 'lodash/isArray'
import { FakeDataGenerator } from './index'

describe('GenerateFakeData - Integration Tests', () => {
  it.skip('GenerateFakeData should generate Fake data', async () => {
    const event = require('./event.json')
    delete event.S3OutputBucket
    delete event.S3OutputKey
    const objGenerator = new FakeDataGenerator(event)
    objGenerator
      .getFakeData()
      .then((result) => {
        console.log('Output', JSON.stringify(result, null, 2))
        expect(result).toBeDefined()
        expect(isArray(result)).toBe(true)
        expect(result.length).toBeGreaterThan(0)
      })
      .catch((err) => console.log('error:', err.message))
  })
  it.only('GenerateFakeData should save Fake data', async () => {
    const event = require('./event.json')
    console.log(JSON.stringify(event, null, 2))
    const objGenerator = new FakeDataGenerator(event)
    const filename = await objGenerator.SaveFakeJsonData()
    console.log('s3 File saved:', filename)
    expect(filename).toBeDefined()
    expect(filename.includes(event.S3OutputKey)).toBe(true)
  })
})
