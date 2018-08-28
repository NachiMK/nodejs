import { JsonObjectArrayToS3CSV } from './index'
let event = require('./event.json')

describe('JsonObjectArrayToS3CSV - Unit Tests', () => {
  it('JsonObjectArrayToS3CSV should create CSV Files', async () => {
    const objJsonToCSV = new JsonObjectArrayToS3CSV(event)
    await objJsonToCSV.CreateFiles()
    expect(objJsonToCSV.ModuleStatus).toBe('success')
    expect(objJsonToCSV.Output.keyStatus.length).toBeGreaterThan(0)
    // expect(objJsonToCSV.Output.S3CSVFile).toBeDefined()
    // expect(objJsonToCSV.Output.csvData).toBeUndefined()
  })
  it('JsonObjectArrayToS3CSV should throw error', async () => {
    delete event['S3DataFilePath']
    const objJsonToCSV = new JsonObjectArrayToS3CSV(event)
    await objJsonToCSV.CreateFiles()
    expect(objJsonToCSV.ModuleStatus).toBe('error')
  })
  it.only('JsonObjectArrayToS3CSV should use defaults and process one object', async () => {
    delete event['Options']
    event.Options = {}
    event.Options.keysToProcess = 'clients'
    const objJsonToCSV = new JsonObjectArrayToS3CSV(event)
    await objJsonToCSV.CreateFiles()
    expect(objJsonToCSV.ModuleStatus).toBe('success')
    expect(objJsonToCSV.Output.keyStatus.length).toBeGreaterThan(0)
    // most keys should be ignored except only one should be marked as success
    const NoOfTransformedObjects = objJsonToCSV.Output.keyStatus.filter(
      (keystat) => keystat.status === 'success'
    ).length
    expect(NoOfTransformedObjects).toBe(1)
  })
})
