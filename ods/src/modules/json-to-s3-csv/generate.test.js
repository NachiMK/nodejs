import { JsonToS3CSV } from './index'
let event = require('./event.json')

describe('JsonToS3CSV - Unit Tests', () => {
  it('JsonToS3CSV should create CSV Files', async () => {
    const objJsonToCSV = new JsonToS3CSV(event)
    await objJsonToCSV.SaveCSVToS3()
    expect(objJsonToCSV.ModuleStatus).toBe('success')
    expect(objJsonToCSV.Output.S3CSVFile).toBeDefined()
  })
  it('JsonToS3CSV Throw Invalid Data error', async () => {
    delete event['JsonData']
    const objJsonToCSV = new JsonToS3CSV(event)
    await objJsonToCSV.SaveCSVToS3()
    expect(objJsonToCSV.ModuleStatus).toBe('error')
  })
  it('JsonToS3CSV Throw Invalid S3 Output Bucket not defined error', async () => {
    delete event['S3OutputBucket']
    const objJsonToCSV = new JsonToS3CSV(event)
    await objJsonToCSV.SaveCSVToS3()
    expect(objJsonToCSV.ModuleStatus).toBe('error')
  })
})
