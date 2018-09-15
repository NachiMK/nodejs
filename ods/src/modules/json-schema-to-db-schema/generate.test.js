import { JsonSchemaToDBSchema } from './index'

describe('JsonSchemaToDBSchema - Unit Tests', () => {
  it.skip('JsonSchemaToDBSchema should return DB Schema', async () => {
    const event = require('./event.json')
    const obj = new JsonSchemaToDBSchema(event)
    try {
      const resp = await obj.getDBScriptFromS3Schema()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
  it.only('JsonSchemaToDBSchema should save DB Schema', async () => {
    const event = require('./event.json')
    const obj = new JsonSchemaToDBSchema(event)
    try {
      const resp = await obj.saveDBSchema()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
})
