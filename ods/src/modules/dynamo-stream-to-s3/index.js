import moment from 'moment';
import { unmarshalItem } from 'dynamodb-marshaler';
import {
  uploadFileToS3,
} from '../s3';
import InvalidParameterError from '../ODSErrors/InvalidParameterError';
// import ODSError from '../ODSErrors/ODSError';
import {
  GetDefaultOdsResponse,
  SetOdsResponseStatusToSuccess,
  SetOdsResponseStatusToError,
} from '../ODSResponse';
import odsLogger from '../log/ODSLogger';

const awsSDK = require('aws-sdk');
const _ = require('lodash');
const uuidv4 = require('uuid/v4');

export async function DynamoStreamEventsToS3(StreamEventsToS3Param = {}) {
  const eventReceivedDtTm = new Date().toISOString();

  const defaultResp = await GetDefaultOdsResponse();
  const saveStatus = {
    ...defaultResp,
  };

    // validate params here
  await ValidateParams(StreamEventsToS3Param);

  const {
    DynamoStreamEvent,
    KeyName = KeyName || '',
    S3BucketName,
    AppendDateTime = AppendDateTime || true,
    DateTimeFormat = DateTimeFormat || 'YYYYMMDD_HHmmssSSS',
    TableName = TableName || '',
  } = StreamEventsToS3Param;

  const firstElement = _.head(DynamoStreamEvent.Records);
  const CurTableName = TableName || ((typeof firstElement !== 'undefined') ? firstElement.eventSourceARN.split(':')[5].split('/')[1] : 'UNKNOWN_');
  const TableKeyName = KeyName || CurTableName;

  // Parse the triggering tablename (Ex: dev-table-name) from the eventSourceARN
  let changedRecords;
  try {
    changedRecords = await Promise.all(
      DynamoStreamEvent.Records.map(async (record) => {
        const item = record.dynamodb.NewImage;
        if (item) {
          const itemParams = {
            Item: {
              HistoryId: record.eventID,
              HistoryAction: record.eventName,
              HistoryDate: eventReceivedDtTm.slice(0, 10).replace(/-/g, ''),
              HistoryCreated: eventReceivedDtTm,
              Rowkey: getRowKey(item),
              SourceTable: TableName,
              RecordSeqNumber: record.dynamodb.SequenceNumber,
              ApproximateCreationDateTime: (new Date(record.dynamodb.ApproximateCreationDateTime * 1000)).toISOString(),
            },
          };
          Object.assign(itemParams.Item, UnmarshallStreamImage(item));
          return itemParams;
        }
        return undefined;
      }),
    );
  } catch (err) {
    const RetError = new Error(`Error Reading from Stream Events ${TableKeyName} 
                         to save to S3 bucket: ${S3BucketName} 
                         error:${JSON.stringify(err, null, 2)}`);
    console.warn(`${JSON.stringify(RetError, null, 2)}`);
    await SetOdsResponseStatusToError(saveStatus, RetError);
    return saveStatus;
  }
  // if no errors so far then save to s3. they could be errors in saving to s3 which is different.
  odsLogger.log('info', 'About to put file to s3');
  const saveToS3Status = await SaveDynamoRowsToS3(changedRecords, TableKeyName, S3BucketName, AppendDateTime, DateTimeFormat);
  Object.assign(saveStatus, saveToS3Status);

  return saveStatus;
}

export async function SaveDynamoRowsToS3(Rows, KeyName, S3BucketName, AppendDateTime = true, DateTimeFormat = 'YYYYMMDD_HHmmssSSS') {
  let RetError;
  const S3DataFile = '';
  const RowCount = _.isArray(Rows) ? Rows.length : 0;
  const defaultResp = await GetDefaultOdsResponse();

  KeyName = await getJSONFileKeyName(KeyName, AppendDateTime, DateTimeFormat);
  const saveStatus = {
    ...defaultResp,
    S3DataFile,
    S3BucketName,
    KeyName,
    RowCount,
  };
  odsLogger.log('info', `Saving File:${JSON.stringify(saveStatus, null, 2)}`);
  try {
    await uploadFileToS3({
      Bucket: S3BucketName,
      Key: KeyName,
      Body: (RowCount === 0) ? JSON.stringify({}, null, 2) : JSON.stringify(Rows, null, 2),
    });
    saveStatus.S3DataFile = `https://s3-us-west-2.amazonaws.com/${S3BucketName}/${KeyName}`;
    await SetOdsResponseStatusToSuccess(saveStatus);
  } catch (err) {
    RetError = new Error(`Error saving Changes for Key ${KeyName} 
                         # of Rows: ${RowCount}
                         to S3 bucket: ${S3BucketName} 
                         error:${JSON.stringify(err, null, 2)}`);
    console.warn(`${JSON.stringify(RetError, null, 2)}`);
    await SetOdsResponseStatusToError(saveStatus, RetError);
  }
  odsLogger.log('info', 'Done Saving File to S3');
  return saveStatus;
}

async function ValidateParams(StreamEventsToS3Param = {}) {
  const errorMessage = `Invalid Values Passed in for StreamEventsToS3Param = {${JSON.stringify(StreamEventsToS3Param, null, 2)}}`;
  let hasErrors = false;
  let errorList = '';
  if (_.isUndefined(StreamEventsToS3Param)) {
    hasErrors = true;
    errorList = 'Parameter StreamEventsToS3Param is empty null. Please pass in valid values';
  }

  if (hasErrors === true) {
    throw new InvalidParameterError(`${errorMessage}, Error List: ${errorList}`, 'Error');
  }
}

export function UnmarshallStreamImage(newImage) {
  // implemented with help of blog
  // https://read.acloud.guru/using-the-dynamodb-document-client-with-dynamodb-streams-from-aws-lambda-6957b6c81112

  // if AWS changes there SDK this portion is going to fail.
  // to protect we could include our version of SDK that we want to
  // use but for now I don't know how to do.

  // Another option is to use npm module call dynamodb-unmarshaler.
  // https://www.npmjs.com/package/dynamodb-marshaler
  if (newImage) {
    try {
      const docClient = new awsSDK.DynamoDB.DocumentClient();
      // Create a Translator object, which comes from the DocumentClient
      const dynamodbTranslator = docClient.getTranslator();

      // It needs a SDK 'shape'. The individual Items in the Stream record
      // are themselves the same Item shape as we see in a getItem response
      const ItemShape = docClient.service.api.operations.getItem.output.members.Item;

      // Let's just replace, in-place each Item with a 'translated' version
      return dynamodbTranslator.translateOutput(newImage, ItemShape);
    } catch (err) {
      return UnmarshallByAlternateLibrary(newImage);
    }
  }
}

export function UnmarshallByAlternateLibrary(newImage) {
  // If above function UnmarshallDynamodb doesnt work
  // with SDK then we will use the npm
  return unmarshalItem(newImage);
}

function getRowKey(item) {
  let retVal;
  try {
    if ((!_.isUndefined(item)) && (!_.isUndefined(item.Id))) {
      retVal = item.Id[Object.keys(item.Id)[0]].toString();
      console.log('id from object', JSON.stringify(retVal));
    } else {
      retVal = uuidv4();
      console.log('uuid', JSON.stringify(retVal));
    }
  } catch (err) {
    console.log(`Error in Finding "Id" column for Object:.${JSON.stringify(item, null, 2)}`);
  }
  return retVal;
}
/*
async function getDefaultFilePrefix(FileNamePrefix, RowCount = 0) {
  FileNamePrefix = _.isEmpty(FileNamePrefix) ? 'Unknown' : FileNamePrefix;
  RowCount = _.isUndefined(RowCount) ? 0 : RowCount;
  const defaultprefix = `${FileNamePrefix}_${RowCount}_`;
  return defaultprefix;
}
*/
async function getDataTimeStamp(timeformat = 'YYYYMMDD_HHmmssSSS') {
  timeformat = (_.isEmpty(timeformat) || _.isUndefined(timeformat)) ? 'YYYYMMDD_HHmmssSSS' : timeformat;
  return moment().format(timeformat);
}

export async function getJSONFileKeyName(FilePrefix, AppendDtTm = true, DateTimeFormat = 'YYYYMMDD_HHmmssSSS') {
  FilePrefix = (_.isUndefined(FilePrefix) || _.isEmpty(FilePrefix)) ? 'UNKNOWN_' : FilePrefix.replace('.json', '');
  FilePrefix = ((FilePrefix.charAt(0) === '/') ? FilePrefix.substring(1) : FilePrefix);
  if (AppendDtTm) {
    return `${FilePrefix}_${await getDataTimeStamp(DateTimeFormat)}.json`.replace('__', '_').replace('-_', '-');
  }

  return `${FilePrefix}.json`;
}
