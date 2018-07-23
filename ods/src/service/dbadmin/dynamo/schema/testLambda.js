import _ from 'lodash';
import { handler as lambdaToCreateSchema } from '.';
import { s3FileExists, s3FileParser } from '../../../../modules/s3';

const event = require('./event.json');

export async function testlambdaToCreateSchema() {
  try {
    console.log('Processing event:', event);
    const resp = await lambdaToCreateSchema(event);
    console.log(JSON.stringify(resp, null, 2));
    let filesRefreshed = false;
    if (resp && _.isArray(resp)) {
      resp.forEach((item) => {
        console.log('Checking item:', JSON.stringify(item, null, 2));
        if (item && item.S3FilePath) {
          console.log('S3 File Path Exists:', item.S3FilePath);
          console.log('Checking if file really exists in S3');
          const {
            Bucket,
            Key,
          } = s3FileParser(item.S3FilePath);
          filesRefreshed = s3FileExists(Bucket, Key);
          console.log('File Exists Check Results:', JSON.stringify(filesRefreshed, null, 2));
        }
      });
      return ((filesRefreshed) ? 'FILE REFRESH DONE.' : 'ERROR');
    }
    console.log('NO schema fiels were created or nothing is available for Refresh.');
    return 'NOTHING TO REFRESH.';
  } catch (err) {
    console.log('Some error:', JSON.stringify(err, null, 2));
    throw err.message;
  }
}

// npm run build && clear && odsloglevel=info STAGE=dev log_dbname=ODSLog DEV_ODSLOG_PG='postgres://odslog_user:H!xme_0ds_ah_dev1@localhost
// /odslog_dev' DEV_ODSCONFIG_PG='postgres://odsconfig_user:H!xme_0ds_ah_dev1@localhost/odsconfig_dev' node lib/service/dbadmin/dynamo/schema/generate-test.js
