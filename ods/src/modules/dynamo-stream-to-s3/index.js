import moment from 'moment';
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
              HistoryId: {
                S: record.eventID,
              },
              HistoryAction: {
                S: record.eventName,
              },
              HistoryDate: {
                S: eventReceivedDtTm.slice(0, 10).replace(/-/g, ''),
              },
              HistoryCreated: {
                S: eventReceivedDtTm,
              },
              Rowkey: {
                S: getRowKey(item),
              },
              SourceTable: {
                S: TableName,
              },
              RecordSeqNumber: {
                S: record.dynamodb.SequenceNumber,
              },
              ApproximateCreationDateTime: {
                S: (new Date(record.dynamodb.ApproximateCreationDateTime * 1000)).toISOString(),
              },
            },
          };
          Object.assign(itemParams.Item, item);
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
  const S3FilePath = '';
  const RowCount = _.isArray(Rows) ? Rows.length : 0;
  const defaultResp = await GetDefaultOdsResponse();

  KeyName = await getJSONFileKeyName(KeyName, AppendDateTime, DateTimeFormat);
  const saveStatus = {
    ...defaultResp,
    S3FilePath,
    S3BucketName,
    KeyName,
    RowCount,
  };
  odsLogger.log('info', `Saving File:${JSON.stringify(saveStatus, null, 2)}`);
  try {
    uploadFileToS3({
      Bucket: S3BucketName,
      Key: KeyName,
      Body: (RowCount === 0) ? JSON.stringify({}, null, 2) : JSON.stringify(Rows, null, 2),
    });
    saveStatus.S3FilePath = `s3://us-west-2.amazonaws.com/${S3BucketName}/${KeyName}`;
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

async function getRowKey(item) {
  let retVal;
  try {
    if ((!_.isUndefined(item)) && (!_.isUndefined(item.Id))) { retVal = item.Id[Object.keys(item.Id)[0]].toString(); } else { retVal = uuidv4(); }
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
    return `${FilePrefix}_${await getDataTimeStamp(DateTimeFormat)}.json`.replace('__', '_');
  }

  return `${FilePrefix}.json`;
}
