import {
  createDynamoDBToS3PipeLineTask,
} from './index';

createDynamoDBToS3PipeLineTask('clients', 10)
  .then(res => console.log('res', res))
  .catch(e => console.log('error', e));

// npm run build && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/service/data/ODSConfig/DataPipeLineTask/generate-test.js
