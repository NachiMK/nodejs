import { FakeDataUploader } from './index'

describe('FakeDataUploader - Integration Tests', () => {
  it('FakeDataUploader should upload Fake data', async () => {
    const event = require('./event.json')
    const objUploader = new FakeDataUploader(event)
    const resp = await objUploader.BatchUpload()
    expect(resp).toBeDefined()
    expect(resp.ItemCountInInput).toBeGreaterThan(0)
    expect(resp.ItemsUpdated).toBe(resp.ItemCountInInput)
    expect(resp.BatchErrors.length).toBe(0)
  })
  it.skip('FakeDataUploader should throw error', async () => {
    const event = require('./event.json')
    delete event.S3DataFilePath
    const objUploader = new FakeDataUploader(event)
    expect(() => {
      objUploader.BatchUpload().catch((err) => {
        throw new Error(err.message)
      })
    }).toThrow()
  })
})
