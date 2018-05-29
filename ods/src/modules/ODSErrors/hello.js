var AWS = require('aws-sdk');
var s3 = new AWS.S3();
// Bucket names must be unique across all S3 users
var myBucket = 'ods-data-dev';
var myKey = 'dynamodb/test.json';
var params = { Bucket: myBucket, Key: myKey, Body: 'Hello!' };
s3.putObject(params, function (err, data) {
    if (err) {
        console.log(err)
    } else {
        console.log("Successfully uploaded data to myBucket/myKey");
    }
});

params = { Bucket: myBucket, Key: myKey };
s3.getObject(params, function (err, data) {
    if (err) {
        console.log(err)
    } else {
        console.log("Successfully retrieved data from myBucket/myKey");
        let objdata = data.Body.toString('utf-8');
        console.log(JSON.stringify(data, null, 2));
        console.log(JSON.stringify(objdata, null, 2));
    }
});
