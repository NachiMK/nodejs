import moment from 'moment';
import ODSLogger from '../../../../modules/log/ODSLogger';
import { GetDynamoTableSchema } from '../../../../modules/dynamo-schema-builder';
import { uploadFileToS3, s3FileParser } from '../../../../modules/s3';
import { GetDynamoTablesToRefreshSchema as dataGetTableToRefresh
  , UpdateSchemaFile as dataUpdateSchemaFile } from '../../../../data/ODSConfig/DynamoTableSchema';

export const handler = async (event) => {
  // do something
  ODSLogger.log('info', event);
  let respArray = [];

  const RefreshAll = event.RefreshAll || false;
  const RefreshTableList = event.RefreshTableList || '';

  // get list of Tables for which we need to create schema
  const tableList = await GetTableList({ RefreshAll, RefreshTableList });
  // loop through the tables and create schema
  if (tableList) {
    respArray = tableList.map(item => CreateSchema(item));
  }
  return respArray;
};

const GetTableList = async (params) => {
  let tablelist;
  try {
    tablelist = dataGetTableToRefresh(params);
  } catch (err) {
    tablelist = [];
    ODSLogger.log('error', 'Error getting tables for refreshing schema.', err.message);
  }
  return tablelist;
};

const CreateSchema = async (tableRequest) => {
  ODSLogger.log('info', `Creating Schema for Table: ${tableRequest}`);
  const {
    DynamoTableName,
    S3JsonSchemaPath,
  } = tableRequest;
  const pattern = /-+\d+_+\d+.json+/i;

  const {
    Bucket,
    Key,
  } = s3FileParser(S3JsonSchemaPath);
  const FileKey = (Key) ? Key.replace(pattern, `-${moment().format('YYYYMMDD_HHmmssSSS')}.json`)
    : `dynamotableschema/${DynamoTableName.replace(/[proddevint]+-+/i, '')}-${moment().format('YYYYMMDD_HHmmssSSS')}.json`;

  let s3Resp = {};
  try {
    if (tableRequest) {
      const schemaResp = await GetDynamoTableSchema({ TableName: DynamoTableName });
      if (schemaResp && schemaResp.Status && schemaResp.Status === 'success') {
        s3Resp = await saveSchemaToS3(Bucket, FileKey, schemaResp.Schema);
        if (s3Resp && s3Resp.Status && s3Resp.Status === 'success' && s3Resp.S3FilePath) {
          const dbResp = await dataUpdateSchemaFile(tableRequest.DynamoTableSchemaId, s3Resp.S3FilePath);
          if (!dbResp) throw new Error('Error saving S3 file path to database.', dbResp);
          ODSLogger.log('info', 'Schema File Saved', dbResp);
          Object.assign(s3Resp, dbResp);
        } else {
          throw new Error('Error saving schema to S3.', s3Resp);
        }
      } else {
        throw new Error('Error Creating schema for Table.', schemaResp);
      }
    } else {
      throw new Error('Invalid Parameter for Creating Schema', tableRequest);
    }
  } catch (err) {
    ODSLogger.log('error', `Error in CreateSchema for table ${DynamoTableName}, Error: ${err.message}`);
    throw err;
  }
  return s3Resp;
};

async function saveSchemaToS3(Bucket, FileKey, data) {
  const resp = {};
  try {
    ODSLogger.log('debug', 'Saving Schema to S3.', [Bucket, FileKey, data]);
    await uploadFileToS3({ Bucket, Key: FileKey, Body: data });
    resp.Status = 'success';
    resp.S3FilePath = `s3://${Bucket}/${FileKey}`;
  } catch (err) {
    resp.Status = 'Error';
    resp.error = err;
    resp.S3FilePath = undefined;
    ODSLogger.log('error', 'Error saving to s3', [err, resp]);
  }
  return resp;
}
