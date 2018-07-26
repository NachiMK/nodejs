import jsonSchemaSaver from '.';

jsonSchemaSaver({
  Datafile: 's3://dev-ods-data/unit-test/clients/test-clients-data-20180725_114740006.json',
  Output: 's3://dev-ods-data/unit-test/clients/test-clients-Schema-',
  Overwrite: 'yes',
  S3RAWJsonSchemaFile: 's3://dev-ods-data/unit-test/dynamotableschema/clients-20180723_161417408.json',
})
  .then(res => console.log('res', res))
  .catch(e => console.log('error', e));
