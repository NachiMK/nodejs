import ODSLogger from '../../../../modules/log/ODSLogger';
import { GetDynamoTableSchema } from '../../../../modules/dynamo-schema/index';
import { uploadFileToS3 } from '../../../../modules/s3/index';
import { GetDynamoTablesToRefreshSchema as dataGetTableToRefresh
  , UpdateSchemaFile as dataUpdateSchemaFile } from '../../../../data/ODSConfig/DynamoTableSchema/index';

export const handler = async (event) => {
  // do something
  ODSLogger.log('info', event);
  // get list of Tables for which we need to create schema
  const tableList = await GetTableList();
  // loop through the tables and create schema
  if (tableList) {
    tableList.forEach(item => CreateSchema(item));
  }
};

const GetTableList = async () => {
  let tablelist;
  try {
    tablelist = dataGetTableToRefresh();
  } catch (err) {
    tablelist = [];
    ODSLogger.log('error', 'Error getting tables for refreshing schema.', err.message);
  }
  return tablelist;
};

const CreateSchema = async (tableRequest) => {
  ODSLogger.log('info', `Creating Schema for Table: ${tableRequest}`);
  const {
    TableName,
    S3Path,
    Prefix,
  } = tableRequest;

  if (tableRequest) {
    const schemaResp = await GetDynamoTableSchema(TableName);
    if (schemaResp && schemaResp.Status && schemaResp.Status === 'success') {
      const s3Resp = await saveSchemaToS3(S3Path, Prefix, schemaResp.Schema);
      if (s3Resp && s3Resp.Status && s3Resp.Status === 'success' && s3Resp.S3FilePath) {
        const dbResp = await dataUpdateSchemaFile(TableName, s3Resp.S3FilePath);
        if (!dbResp) throw new Error('Error saving S3 file path to database.', dbResp);
        ODSLogger.log('info', 'Schema File Saved', dbResp);
      } else {
        throw new Error('Error saving schema to S3.', s3Resp);
      }
    } else {
      throw new Error('Error Creating schema for Table.', schemaResp);
    }
  } else {
    throw new Error('Invalid Parameter for Creating Schema', tableRequest);
  }
};

async function saveSchemaToS3(S3Path, Prefix, data) {
  const resp = {};
  try {
    await uploadFileToS3(S3Path, Prefix, data);
    resp.Status = 'success';
    resp.S3FilePath = `${S3Path}${Prefix}`;
  } catch (err) {
    resp.Status = 'Error';
    resp.error = err;
    resp.S3FilePath = undefined;
  }
}
