import moment from 'moment';
import { JsonToJsonFlattner } from './JsonToJsonFlattner';
import event from './event.json';
import { s3FileExists } from '../s3';

describe('JsonToJson Flattner - Process ANY DATA', () => {
  it('JsonToJson should Process one or Zero tasks successfully', async () => {
    console.log('event:', JSON.stringify(event, null, 2));
    const jsonFlatner = new JsonToJsonFlattner(event);
    await jsonFlatner.getNormalizedDataset();
    expect(jsonFlatner.Output.Status).toBe('success');
    expect(jsonFlatner.Output.NormalizedDataSet).toBeDefined();
    // console.log(JSON.stringify(jsonFlatner.Output.NormalizedDataSet, null, 2));
  });
  it.only('JsonToJson should create a file in s3', async () => {
    const S3Key = `unit-test/clients/test-clients-flat-${moment().format('YYYYMMDD_HHmmssSSS')}.json`;
    const event2 = {
      S3DataFilePath: 's3://dev-ods-data/unit-test/clients/test-clients-Data-20180817_debug.json',
      TableName: 'clients',
      BatchId: '25',
      OutputType: 'Save-to-S3',
      LogLevel: 'warn',
      S3Bucket: 'dev-ods-data',
      S3Key,
    };
    const jsonFlatner = new JsonToJsonFlattner(event2);
    await jsonFlatner.getNormalizedDataset();
    console.log('Nomralized File Path', JSON.stringify(jsonFlatner.Output.NormalizedS3Path, null, 2));
    expect(jsonFlatner.Output.Status).toBe('success');
    expect(jsonFlatner.Output.NormalizedDataSet).toBeDefined();
    expect(jsonFlatner.Output.NormalizedS3Path).toBeDefined();
    const blnFileExists = await s3FileExists({
      Bucket: event2.S3Bucket,
      Key: event2.S3Key,
    });
    console.log(`File ${jsonFlatner.Output.NormalizedS3Path} exists check Result: ${blnFileExists}`);
    expect(blnFileExists).toBe(true);
  });
});
