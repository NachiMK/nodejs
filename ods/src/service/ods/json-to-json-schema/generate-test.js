import { JsonToJsonSchema } from './index';

const task = {
  DataPipeLineTaskQueueId: 3,
  Status: 'On Hold',
  RunSequence: 2020,
  TaskConfigName: 'JSON History to Flat JSON',
  TableName: 'clients',
};
console.log(task);
JsonToJsonSchema(task)
  .then(res => console.log('res', res))
  .catch(e => console.log('error', e));

/*
npm run build && odsloglevel=info STAGE=dev log_dbname=ODSLog DEV_ODSLOG_PG='postgres://odslog_user:H!xme_0ds_ah_dev1@localhost
/odslog_dev' DEV_ODSCONFIG_PG='postgres://odsconfig_user:H!xme_0ds_ah_dev1@localhost/odsconfig_dev' node lib/service/ods/json-to-json-schema/generate-test.js
*/
