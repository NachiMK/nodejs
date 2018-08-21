import jsonSchemaSaver from '.';

describe('ods-schema-builder - Integration Tests', () => {
  it.only('ods-schema-builder should create schema file', async () => {
    const resp = await jsonSchemaSaver({
      Datafile: 's3://dev-ods-data/unit-test/clients/test-clients-Data-20180817_debug.json',
      Output: 's3://dev-ods-data/unit-test/clients/test-clients-Schema-',
      Overwrite: 'yes',
      S3RAWJsonSchemaFile: 's3://dev-ods-data/unit-test/dynamotableschema/clients-raw-schame-debug.json',
    });
    expect(resp.status.message).toBe('success');
    expect(resp.file).toBeDefined();
    console.log(JSON.stringify(resp.Schema, null, 2));
  });
});
