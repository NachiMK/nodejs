import { GetJSONFromS3Path, SaveJsonToS3File } from './index';

describe('s3 - get or save json data', () => {
  it('should load data from S3', async () => {
    const jsonData = await GetJSONFromS3Path('s3://dev-ods-data/dynamotableschmea/test.json');
    expect(jsonData).toBeDefined();
  });

  it('should load environment variable', async () => {
    const jsonData = process.env.STAGE;
    console.log('env:', jsonData);
    expect(jsonData).toBeDefined();
  });

  it('should save or load json file in s3 bucket', async () => {
    const jsonData = {
      test: 'value',
    };
    const file = await SaveJsonToS3File('s3://dev-ods-data/dynamotableschmea/test-s3-upload-', jsonData);
    console.log('file:', file);
    expect(file).toBeDefined();
    const loadedJsonData = await GetJSONFromS3Path(file);
    expect(loadedJsonData).toBeDefined();
    expect(JSON.stringify(loadedJsonData, null, 2)).toEqual(JSON.stringify(jsonData, null, 2));
  });
});

// npm test -- -u -t="should load data from S3"
// npm test -- -u -t="should save or load json file in s3 bucket"
