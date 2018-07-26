import { DynamoStreamEventsToS3 } from './index';

const eventData = require('./event.json');

const StreamEventsToS3Param = {
  DynamoStreamEvent: eventData,
  KeyName: 'unit-test/clients/test-clients-data-',
  S3BucketName: 'dev-ods-data',
  AppendDateTime: true,
  DateTimeFormat: 'YYYYMMDD_HHmmssSSS',
  TableName: 'clients',
};

DynamoStreamEventsToS3(StreamEventsToS3Param)
  .then(res => console.log(res))
  .catch(res => console.log(res));

// npm run build && clear && node lib/modules/dynamo-stream-to-s3/generate-test.js
