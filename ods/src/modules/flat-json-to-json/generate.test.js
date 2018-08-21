import { JsonToJsonFlattner } from './JsonToJsonFlattner';
import event from './event.json';
import { s3FileParser, s3FileExists } from '../s3';

describe('JsonToJson Flattner - Process ANY DATA', () => {
  it('JsonToJson should Process one or Zero tasks successfully', async () => {
    console.log('event:', JSON.stringify(event, null, 2));
    const jsonFlatner = new JsonToJsonFlattner(event);
    await jsonFlatner.getNormalizedDataset();
    expect(jsonFlatner.ModuleStatus).toBe('success');
    expect(jsonFlatner.Output.NormalizedDataSet).toBeDefined();
    // console.log(JSON.stringify(jsonFlatner.Output.NormalizedDataSet, null, 2));
  });

  it.only('JsonToJson should create a file in s3', async () => {
    event.OutputType = 'Save-to-S3';
    event.S3Bucket = 'dev-ods-data';
    event.S3Key = 'unit-test/clients/test-clients-flat-';

    const jsonFlatner = new JsonToJsonFlattner(event);
    await jsonFlatner.SaveNormalizedData();

    console.log('Nomralized File Path', JSON.stringify(jsonFlatner.Output.NormalizedS3Path, null, 2));

    expect(jsonFlatner.ModuleStatus).toBe('success');
    expect(jsonFlatner.Output.NormalizedDataSet).toBeUndefined();
    expect(jsonFlatner.Output.NormalizedS3Path).toBeDefined();

    const { Bucket, Key } = s3FileParser(jsonFlatner.Output.NormalizedS3Path);
    const blnFileExists = await s3FileExists({
      Bucket,
      Key,
    });
    console.log(`File ${jsonFlatner.Output.NormalizedS3Path} exists check Result: ${blnFileExists}`);
    expect(blnFileExists).toBe(true);
  });
});
