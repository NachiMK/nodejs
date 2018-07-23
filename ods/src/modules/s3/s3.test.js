import moment from 'moment';
import { s3FileParser, uploadFileToS3 } from './index';

describe('s3 - get bucket', () => {
  it('should find bucket name', () => {
    const { Bucket, Key } = s3FileParser('s3://dev-ods-data/dynamotableschmea/test.json');
    expect(Bucket).toBe('dev-ods-data');
    expect(Key).toBe('dynamotableschmea/test.json');
  });

  it('should upload file to bucket', async () => {
    const { Bucket, Key } = s3FileParser(`s3://dev-ods-data/dynamotableschmea/test-${moment().format('YYYYMMDD_HHmissSSS')}.json`);
    const resp = await uploadFileToS3({ Bucket, Key, Body: '{test:"value"}' });
    console.log('resp:', resp);
    expect(resp).toHaveProperty('ETag');
  });
});
