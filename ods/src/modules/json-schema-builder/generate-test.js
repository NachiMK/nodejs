import jsonSchemaSaver from '.';

jsonSchemaSaver({
  Datafile: 's3://ods-files/persons-etl.json',
  Output: 's3://ods-files/complete/',
  FilePrefix: 'persons',
  Overwrite: 'yes',
})
  .then(res => console.log('res', res))
  .catch(e => console.log('error', e));
