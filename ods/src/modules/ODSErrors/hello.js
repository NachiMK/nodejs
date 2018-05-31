const AWS = require('aws-sdk');

const s3 = new AWS.S3();
// Bucket names must be unique across all S3 users
const myBucket = 'ods-data-dev';
const myKey = 'dynamodb/test.json';
let params = { Bucket: myBucket, Key: myKey, Body: 'Hello!' };
s3.putObject(params, (err, data) => {
  if (err) {
    console.log(err);
  } else {
    console.log('Successfully uploaded data to myBucket/myKey');
    console.log(JSON.stringify(data, null, 2));
  }
});

params = { Bucket: myBucket, Key: myKey };
s3.getObject(params, (err, data) => {
  if (err) {
    console.log(err);
  } else {
    console.log('Successfully retrieved data from myBucket/myKey');
    const objdata = data.Body.toString('utf-8');
    console.log(JSON.stringify(data, null, 2));
    console.log(JSON.stringify(objdata, null, 2));
  }
});
