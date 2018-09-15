import { CSVToPostgres } from './index'

describe('CSVToPostgres - Unit Tests', () => {
  it('CSVToPostgres should return Row Count', async () => {
    const event = require('./event.json')
    const obj = new CSVToPostgres(event)
    try {
      const resp = await obj.LoadData()
      console.log('resp', JSON.stringify(resp, null, 2))
      expect(resp).toBeDefined()
    } catch (err) {
      console.log(err.message)
    }
  })
  it.only('CSVToPostgres should throw Validation Error', async () => {
    const event = require('./event.json')
    delete event.S3DataFile
    const obj = new CSVToPostgres(event)
    try {
      await obj.LoadData()
    } catch (err) {
      console.log(err.message)
    }
  })
})
