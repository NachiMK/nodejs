import {
  GetDefaultOdsResponse,
  SetOdsResponseStatusToError,
  IsResponseSuccess,
} from '../../../../modules/ODSResponse';
import {
  DynamoStreamEventsToS3,
} from '../../../../modules/dynamo-stream-to-s3';

import {
  createDynamoDBToS3PipeLineTask,
  UpdatePipeLineTaskStatus,
} from '../../../../data/ODSConfig/DataPipeLineTask';

import InvalidParameterError from '../../../../modules/ODSErrors/InvalidParameterError';
// import ODSError from '../../../../modules/ODSErrors/ODSError';

// dependencies
const _ = require('lodash');
// let AWS = require('aws-sdk');

exports.handler = async (event, context, callback) => {
  let RetError;
  const S3FilePath = '';
  let S3BucketName;
  const RowCount = _.isArray(event.Records) ? event.Records.length : 0;
  const AppendDateTime = true;
  const DateTimeFormat = 'YYYYMMDD_HHmmssSSS';
  let FilePrefix;
  const defaultResp = await GetDefaultOdsResponse();

  // Parse the triggering tablename (Ex: dev-table-name) from the eventSourceARN
  const firstElement = _.head(event.Records);
  const tableName = (typeof firstElement !== 'undefined') ? firstElement.eventSourceARN.split(':')[5].split('/')[1] : undefined;

  const saveStatus = {
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
    S3BucketName = pipeLineTaskResp.S3DataFileFolderPath || 'dev-ods-data';
  } catch (err) {
    RetError = new Error(`Error creating DatapipeLine Task for ${tableName} 
                    so data was not saved to S3 bucket.
                    error:${JSON.stringify(err, null, 2)}`);
    console.warn(`${JSON.stringify(RetError, null, 2)}`);
    await SetOdsResponseStatusToError(saveStatus, RetError);
    return saveStatus;
  }

  const DynamoStreamEvent = event;
  const StreamEventsToS3Params = {
    DynamoStreamEvent,
    KeyName: FilePrefix,
    S3BucketName,
    AppendDateTime,
    DateTimeFormat,
    TableName: tableName,
  };

  let saveStreamToS3Resp;
  try {
    saveStreamToS3Resp = await DynamoStreamEventsToS3(StreamEventsToS3Params);
    Object.assign(saveStatus, saveStreamToS3Resp);
  } catch (err) {
    if (err instanceof InvalidParameterError) {
      await SetOdsResponseStatusToError(saveStatus, JSON.stringify(err, null, 2));
    } else {
      RetError = new Error(`Unhandled error in calling DynamoStreamEventsToS3 for ${tableName} 
                      to S3 bucket: ${S3BucketName} 
                      with FilePrefix:${FilePrefix}
                      error:${JSON.stringify(err, null, 2)}`);
      console.warn(`${JSON.stringify(RetError, null, 2)}`);
    }
    await SetOdsResponseStatusToError(saveStatus, RetError);
  }
  const updateResp = await UpdatePipeLineTaskStatus(pipeLineTaskResp.DataPipeLineTaskQueueId, saveStatus);

  if ((updateResp) && (IsResponseSuccess(saveStatus))) {
    // let nextStepResp = createDataPipeLineTask_ProcessHistory(tableName, saveStatus);
  }

  return saveStatus;
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
