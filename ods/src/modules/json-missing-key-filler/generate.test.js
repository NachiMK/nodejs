import moment from 'moment'
import { s3FileExists } from '../s3'
import { JsonMissingKeyFiller } from './index'
import event from './event.json'

describe('Json Missing Key Filler - Unit Tests', () => {
  it('Json Missing Key Filler should normalize data successfully', async () => {
    const objModule = new JsonMissingKeyFiller(event)
    //expect.assertions(1)
    await objModule.getUniformJsonData()
    expect(objModule.Output.status.message).toBe('success')
    expect(objModule.Output.UniformJsonData).toBeDefined()
  })
  it.only('Json Missing Key Filler should create a file in s3', async () => {
    event.S3OutputBucket = `${process.env.STAGE || 'dev'}-ods-data`
    event.S3OutputKey = `unit-test/${event.TableName}/test-${
      event.TableName
    }-UniformJson-${moment().format('YYYYMMDD_HHmmssSSS')}.json`
    const objModule = new JsonMissingKeyFiller(event)
    await objModule.getUniformJsonData()
    console.log(
      'S3UniformJsonFile File Path',
      JSON.stringify(objModule.Output.S3UniformJsonFile, null, 2)
    )
    expect(objModule.ModuleStatus).toBe('success')
    expect(objModule.Output.UniformJsonData).toBeUndefined()
    expect(objModule.S3UniformJsonFile).toBeDefined()
    const blnFileExists = await s3FileExists({
      Bucket: event.S3OutputBucket,
      Key: event.S3OutputKey,
    })
    console.log(`File ${objModule.Output.S3UniformJsonFile} exists check Result: ${blnFileExists}`)
    expect(blnFileExists).toBe(true)
  })
})
