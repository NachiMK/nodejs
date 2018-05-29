import { s3FileParser } from './index'

describe('s3 - get bucket', () => {
  it('should find bucket name', () => {
    const { Bucket, Key } = s3FileParser('s3://ods-files/path/to/file')
    expect(Bucket).toBe('ods-files')
    expect(Key).toBe('path/to/file')
  })
})

