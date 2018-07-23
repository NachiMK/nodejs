import jsonSchemaSaver from '.';

jsonSchemaSaver({
  Datafile: 's3://dev-ods-data/persons-etl.json',
  Output: 's3://dev-ods-data/complete/',
  FilePrefix: 'clients',
  Overwrite: 'yes',
  RAWJsonSchemaFile: 's3://dev-ods-data/dynamotableschema/clients-20180723_161417408.json',
})
  .then(res => console.log('res', res))
  .catch(e => console.log('error', e));
