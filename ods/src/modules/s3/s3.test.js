import moment from 'moment'
import { s3FileParser, uploadFileToS3, copyS3toS3, moveS3toS3, s3FileExists } from './index'

describe('s3 - get bucket', () => {
  it('should find bucket name', () => {
    const { Bucket, Key } = s3FileParser('s3://dev-ods-data/dynamotableschema/test.json')
    expect(Bucket).toBe('dev-ods-data')
    expect(Key).toBe('dynamotableschema/test.json')
  })

  it('should Check File exists - Not Exists', async () => {
    // expect.assertions(1)
    const blnExists = await s3FileExists({ Bucket: 'dev-ods-data', Key: 'test.json' })
    expect(blnExists).toBe(false)
  })
  it('should Check File exists - Invalid Bucket', async () => {
    // expect.assertions(1)
    const blnExists = await s3FileExists({ Bucket: 'dev-data', Key: 'test.json' })
    expect(blnExists).toBe(false)
  })
  it('should Check File exists - File Exists', async () => {
    // expect.assertions(1)
    const blnExists = await s3FileExists({
      Bucket: 'dev-ods-data',
      Key: 'dynamotableschema/clients-20180906_132212919.json',
    })
    expect(blnExists).toBe(true)
  })

  it.skip('should upload file to bucket', async () => {
    const { Bucket, Key } = s3FileParser(
      `s3://dev-ods-data/dynamotableschema/test-${moment().format('YYYYMMDD_HHmissSSS')}.json`
    )
    const resp = await uploadFileToS3({ Bucket, Key, Body: '{test:"value"}' })
    console.log('resp:', resp)
    expect(resp).toHaveProperty('ETag')
  })

  it.skip('should copy file to bucket', async () => {
    const params = {
      SourceBucket: 'dev-ods-data',
      SourceKey: 'unit-test/clients/test-clients-Schema-20180925_154121235.json',
      TargetBucket: 'dev-archive-ods-data',
    }
    const resp = await copyS3toS3(params)
    console.log('resp:', resp)
    expect(resp).toHaveProperty('ETag')
  })

  it.skip('should move file', async () => {
    const params = {
      SourceBucket: 'dev-archive-ods-data',
      SourceKey: 'unit-test/clients/test-archive.json',
      TargetBucket: 'dev-archive-ods-data',
      TargetKey: 'dynamodb/clients/test-clients-Schema-20180925_154121235.json',
    }
    const resp = await moveS3toS3(params)
    console.log('resp:', resp)
    expect(resp).toBeDefined()
    expect(resp).toHaveProperty('ETag')
  })
})
