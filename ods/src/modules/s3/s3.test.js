import moment from 'moment'
import { s3FileParser, uploadFileToS3, copyS3toS3, moveS3toS3 } from './index'

describe('s3 - get bucket', () => {
  it('should find bucket name', () => {
    const { Bucket, Key } = s3FileParser('s3://dev-ods-data/dynamotableschema/test.json')
    expect(Bucket).toBe('dev-ods-data')
    expect(Key).toBe('dynamotableschema/test.json')
  })

  it('should upload file to bucket', async () => {
    const { Bucket, Key } = s3FileParser(
      `s3://dev-ods-data/dynamotableschema/test-${moment().format('YYYYMMDD_HHmissSSS')}.json`
    )
    const resp = await uploadFileToS3({ Bucket, Key, Body: '{test:"value"}' })
    console.log('resp:', resp)
    expect(resp).toHaveProperty('ETag')
  })

  it('should copy file to bucket', async () => {
    const params = {
      SourceBucket: 'dev-ods-data',
      SourceKey: 'unit-test/clients/test-clients-Schema-20180925_154121235.json',
      TargetBucket: 'dev-archive-ods-data',
    }
    const resp = await copyS3toS3(params)
    console.log('resp:', resp)
    expect(resp).toHaveProperty('ETag')
  })

  it('should move file', async () => {
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
