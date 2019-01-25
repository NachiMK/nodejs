import { JsonObjectArrayToS3CSV } from './index'
let event = require('./event.json')

describe('JsonObjectArrayToS3CSV - Unit Tests', () => {
  it.only('JsonObjectArrayToS3CSV should create CSV Files', async () => {
    let curEvent = event[1]
    const objJsonToCSV = new JsonObjectArrayToS3CSV(curEvent)
    expect.assertions(3)
    await objJsonToCSV.CreateFiles()
    expect(objJsonToCSV.ModuleStatus).toBe('success')
    expect(objJsonToCSV.Output.keyStatus.length).toBeGreaterThan(0)
    console.log(
      'files array with object name:',
      JSON.stringify(objJsonToCSV.ProcessedKeyAndFiles(), null, 2)
    )
    const NoOfTransformedObjects = objJsonToCSV.Output.keyStatus.filter(
      (keystat) => keystat.status !== 'success'
    ).length
    expect(NoOfTransformedObjects).toBe(0)
  })
  it.skip('JsonObjectArrayToS3CSV should use defaults and process one object', async () => {
    let devEvent = event[0]
    delete devEvent['Options']
    devEvent.Options = {}
    devEvent.Options.keysToProcess = 'clients'
    const objJsonToCSV = new JsonObjectArrayToS3CSV(devEvent)
    expect.assertions(3)
    await objJsonToCSV.CreateFiles()
    expect(objJsonToCSV.ModuleStatus).toBe('success')
    expect(objJsonToCSV.Output.keyStatus.length).toBeGreaterThan(0)
    // most keys should be ignored except only one should be marked as success
    const NoOfTransformedObjects = objJsonToCSV.Output.keyStatus.filter(
      (keystat) => keystat.status === 'success'
    ).length
    console.log(
      'files array with object name:',
      JSON.stringify(objJsonToCSV.ProcessedKeyAndFiles(), null, 2)
    )
    expect(NoOfTransformedObjects).toBe(1)
  })
  it.skip('JsonObjectArrayToS3CSV should throw error', async () => {
    let devEvent = event[0]
    delete devEvent['S3DataFilePath']
    const objJsonToCSV = new JsonObjectArrayToS3CSV(devEvent)
    expect.assertions(3)
    await objJsonToCSV.CreateFiles()
    expect(objJsonToCSV.ModuleStatus).toBe('error')
  })
})
