import { GetJSONFromS3Path, SaveJsonToS3File, copyS3, ArchiveS3File, deleteS3 } from './index'

describe('ODS S3 Helper Function Unit Tests', () => {
  it.skip('should load data from S3', async () => {
    const jsonData = await GetJSONFromS3Path('s3://dev-ods-data/dynamotableschema/test.json')
    expect(jsonData).toBeDefined()
  })

  it.skip('should load environment variable', async () => {
    const jsonData = process.env.STAGE
    console.log('env:', jsonData)
    expect(jsonData).toBeDefined()
  })
  it.skip('should save or load json file in s3 bucket', async () => {
    const jsonData = {
      test: 'value',
    }
    const file = await SaveJsonToS3File(jsonData, {
      S3OutputBucket: 'dev-ods-data',
      S3OutputKey: `dynamotableschema/test-s3-upload-`,
    })
    console.log('file:', file)
    expect(file).toBeDefined()
    const loadedJsonData = await GetJSONFromS3Path(file)
    expect(loadedJsonData).toBeDefined()
    expect(JSON.stringify(loadedJsonData, null, 2)).toEqual(JSON.stringify(jsonData, null, 2))
  })
  it('s3ODS copy file to bucket', async () => {
    const params = {
      SourceFullPath:
        's3://dev-ods-data/unit-test/clients/test-clients-Schema-20180925_154121235.json',
      TargetBucket: 'dev-archive-ods-data',
      TargetKey: 'unit-test/clients/101/test-clients-Schema-20180925_154121235.json',
    }
    const resp = await copyS3(params)
    console.log('resp:', resp)
    expect(resp).toBe(
      `${params.TargetBucket}/unit-test/clients/101/test-clients-Schema-20180925_154121235.json`
    )
  })
  it('s3ODS should archive file', async () => {
    const params = {
      SourceFullPath:
        's3://dev-archive-ods-data/unit-test/clients/101/test-clients-Schema-20180925_154121235.json',
      TargetBucket: 'dev-archive-ods-data',
    }
    const resp = await ArchiveS3File(params)
    console.log('resp:', resp)
    expect(resp).toBeDefined()
    expect(resp).toBe(
      `${params.TargetBucket}/unit-test/clients/test-clients-Schema-20180925_154121235.json`
    )
  })
  it('s3ODS Delete archive file', async () => {
    const params = {
      SourceFullPath:
        's3://dev-archive-ods-data/unit-test/clients/test-clients-Schema-20180925_154121235.json',
    }
    const resp = await deleteS3(params)
    console.log('resp:', resp)
    expect(resp).toBeDefined()
    expect(resp.S3FullPath).toBe(
      'dev-archive-ods-data/unit-test/clients/test-clients-Schema-20180925_154121235.json'
    )
    expect(resp.Deleted).toEqual(true)
  })
})

// npm test -- -u -t="should load data from S3"
// npm test -- -u -t="should save or load json file in s3 bucket"
