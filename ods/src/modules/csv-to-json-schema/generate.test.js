import { CSVToJsonSchema } from './index'

describe('CSVToJsonSchema - Unit Tests', () => {
  it('CSVToJsonSchema should return Json Schema', async () => {
    const event = require('./event.json')
    const obj = new CSVToJsonSchema(event)
    try {
      const resp = await obj.getJsonSchemaFromCSV()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
  it.only('CSVToJsonSchema should save Json Schema', async () => {
    const event = require('./event.json')
    const obj = new CSVToJsonSchema(event)
    try {
      const resp = await obj.saveJsonSchemaFromCSV()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
})
