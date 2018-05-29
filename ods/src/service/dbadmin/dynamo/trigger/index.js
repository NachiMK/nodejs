"use strict";
import moment from 'moment';
import {
  getDefaultODSResponse,
  setODSResponseStatus_Error,
  setODSResponseStatus_Success,
  IsResponseSuccess
} from '../../../../modules/ODSResponse';
import {
  DynamoStreamEventsToS3
} from '../../../../modules/dynamo-stream-to-s3';

import {
  createDynamoDBToS3PipeLineTask,
  UpdatePipeLineTaskStatus
} from '../../../../data/ODSConfig/DataPipeLineTask';

import InvalidParameterError from '../../../../modules/ODSErrors/InvalidParameterError';
import ODSError from '../../../../modules/ODSErrors/ODSError';

const _ = require('lodash');


// dependencies
var AWS = require("aws-sdk");
exports.handler = async (event, context, callback) => {

  let RetError;
  let S3FilePath = "";
  let S3BucketName;
  let RowCount = _.isArray(event.Records) ? event.Records.length : 0;
  let AppendDateTime = true;
  let DateTimeFormat = "YYYYMMDD_HHmmssSSS";
  let FilePrefix;
  let defaultResp = await getDefaultODSResponse();

  // Parse the triggering tablename (Ex: dev-table-name) from the eventSourceARN
  let firstElement = _.head(event.Records);
  let tableName = (typeof firstElement !== undefined) ? firstElement.eventSourceARN.split(":")[5].split("/")[1] : undefined;

  let saveStatus = {
    ...defaultResp,
    S3FilePath,
    S3BucketName,
    tableName,
    RowCount,
  };

  let pipeLineTaskResp;
  try {
    pipeLineTaskResp = await createDynamoDBToS3PipeLineTask(tableName, RowCount);
    FilePrefix = pipeLineTaskResp.DataFilePrefix || `dynamodb/${tableName}`;
    S3BucketName = pipeLineTaskResp.S3DataFileFolderPath || "dev-ods-data";
  }
  catch(err){
    RetError = new Error(`Error creating DatapipeLine Task for ${tableName} 
                    so data was not saved to S3 bucket.
                    error:${JSON.stringify(err, null, 2)}`);
    console.warn(`${JSON.stringify(RetError, null, 2)}`);
    await setODSResponseStatus_Error(saveStatus, RetError);
    return saveStatus;
  }

  let DynamoStreamEvent = event;
  let StreamEventsToS3Params = {
    DynamoStreamEvent,
    "KeyName" : FilePrefix,
    S3BucketName,
    AppendDateTime,
    DateTimeFormat,
    "TableName" : tableName,
  };

  let saveStreamToS3Resp;
  try {
    saveStreamToS3Resp = await DynamoStreamEventsToS3(StreamEventsToS3Params);
    Object.assign(saveStatus, saveStreamToS3Resp);
  }
  catch (err) {
    if (err instanceof InvalidParameterError) {
      await setODSResponseStatus_Error(saveStatus, JSON.stringify(err, null, 2));
    } else {
      RetError = new Error(`Unhandled error in calling DynamoStreamEventsToS3 for ${tableName} 
                      to S3 bucket: ${S3BucketName} 
                      with FilePrefix:${FilePrefix}
                      error:${JSON.stringify(err, null, 2)}`);
      console.warn(`${JSON.stringify(RetError, null, 2)}`);
    }
    await setODSResponseStatus_Error(saveStatus, RetError);
  }
  let updateResp = await UpdatePipeLineTaskStatus(pipeLineTaskResp.DataPipeLineTaskQueueId, saveStatus);

  if ((updateResp) && (IsResponseSuccess(saveStatus))){
    //let nextStepResp = createDataPipeLineTask_ProcessHistory(tableName, saveStatus);
  }

};

// async function saveRowsToS3(TableName, Rows, S3BucketName = "", ODSConfig = {}) {
//   try{
//     let filePrefix = await getDefaultFilePrefix(TableName, RowCount);

//     // create batch only if needed
//     if (odsconfig.CreateTaskQueue === true){
//       let resp = await createDynamoDBToS3PipeLineTask(TableName, RowCount);
//       filePrefix = resp.DataFilePrefix;
//       bucketName = resp.S3DataFileFolderPath;
//     }

//     //save file
//     let keyName = await getJSONFileKeyName(filePrefix);
//     try{
//       uploadFileToS3({
//         "Bucket": bucketName,
//         "Key": keyName,
//         "Body": (RowCount === 0) ? JSON.stringify({}, null, 2) : JSON.stringify(Rows, null, 2)
//       });
//       saveStatus.S3FilePath = `${bucketName}/${keyName}`;
//       saveStatus.S3BucketName = bucketName;
//       await setODSResponseStatus_Success(saveStatus);
//     }
//     catch(err){
//       RetError = new Error(`Error saving Changes for Table ${TableName} 
//                        for Rows: ${RowCount}
//                        to S3 bucket: ${bucketName} 
//                        with key:${keyName}
//                        error:${JSON.stringify(err, null, 2)}`);
//       console.warn(`Error:${JSON.stringify(RetError, null, 2)}`);
//       await setODSResponseStatus_Error(saveStatus, RetError);
//     }
//     if ((odsconfig)){

//     }

//   }
//   catch(err){

//   }

//   return saveStatus;
// }
