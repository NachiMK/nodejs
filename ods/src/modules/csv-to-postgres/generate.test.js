import { CsvToPostgres } from './index'
import { getAndSetVarsFromEnvFile } from '../../../env'

describe('CsvToPostgres - Unit Tests', () => {
  it.only('CsvToPostgres - should Load testtable-1', async () => {
    await getAndSetVarsFromEnvFile(false)
    const event = require('./event.json')
    const obj = new CsvToPostgres(event[1])
    expect.assertions(3)
    const resp = await obj.LoadData()
    console.log('resp', JSON.stringify(resp, null, 2))
    expect(resp).toBeDefined()
    expect(resp.RowCount).toBeDefined()
    expect(resp.RowCount).toBeGreaterThan(0)
  })
  it.skip('CsvToPostgres should return Row Count', async () => {
    await getAndSetVarsFromEnvFile(false)
    const event = require('./event.json')
    // get connection string
    const key = `${process.env.STAGE}_odsdynamodb_PG`.toUpperCase()
    event[0].DBConnection = process.env[key]
    const obj = new CsvToPostgres(event[0])
    const resp = await obj.LoadData()
    console.log('resp', JSON.stringify(resp, null, 2))
    expect(resp).toBeDefined()
    expect(resp.RowCount).toBeDefined()
    expect(resp.RowCount).toBeGreaterThan(0)
  }, 20000)
  it.skip('CsvToPostgres should throw Validation Error', async () => {
    const event = require('./event.json')
    delete event[0].S3DataFilePath
    const obj = new CsvToPostgres(event[0])
    try {
      await obj.LoadData()
    } catch (err) {
      expect(err).toBeDefined()
    }
  })
})
