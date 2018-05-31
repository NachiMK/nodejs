const delay = require('delay');
const AWS = require('aws-sdk');
const sleep = require('sleep');

const AwsDynamoDB = new AWS.DynamoDB({ region: 'us-west-2' });
let TableList = [];

export const getTablesFromDB = async (params, TableNameFilter = '') => {
  const currentParams = params || {
    ExclusiveStartTableName: TableNameFilter || 'dev',
    Limit: 100,
  };
  const items = await AwsDynamoDB.listTables(currentParams).promise();
  TableList = TableList.concat(items.TableNames.filter(name => name.toLocaleLowerCase().includes(TableNameFilter.toLocaleLowerCase())));

  if (items.LastEvaluatedTableName) {
    currentParams.ExclusiveStartTableName = items.LastEvaluatedTableName;
    return getTablesFromDB(currentParams, TableNameFilter);
  }
  return TableList;
};

export const getTableMetaData = async (tablename) => {
  // let aws_dynamo = new AWS.DynamoDB(); 
  let descTableData;
  const params = {
    TableName: tablename,
  };
  try {
    descTableData = await AwsDynamoDB.describeTable(params).promise();
    if (descTableData) {
      console.log(descTableData);
      return descTableData;
    }
  } catch (err) {
    console.warn(`Error finding Table info for Table: ${tablename}`);
    console.warn(`Error:${err}`);
  }
  return descTableData;
};

export const getTableRowCount = async (tablename) => {
  const descTableData = await getTableMetaData(tablename);
  if (descTableData) {
    if (descTableData.Table && descTableData.Table.ItemCount) {
      return descTableData.Table.ItemCount;
    }
  }
  return -1;
};

export const getAttributeCount = async (tablename) => {
  const descTableData = await getTableMetaData(tablename);
  if (descTableData) {
    if (descTableData.Table && descTableData.Table.AttributeDefinitions) {
      return descTableData.Table.AttributeDefinitions.length;
    }
  }
  return -1;
};

export const getTableInfo = async (tablename) => {
  const descTableData = await getTableMetaData(tablename);
  const retTblInfo =
        {
          TableName: tablename,
          CreationDateTime: '',
          AttributeCount: 0,
          GlobalSecondaryIndexesCount: 0,
          ItemCount: 0,
          KeySchemaCount: 0,
          LocalSecondaryIndexesCount: 0,
          LatestStreamArn: '',
          LatestStreamLabel: '',
          LastDecreaseDateTime: '',
          LastIncreaseDateTime: '',
          NumberOfDecreasesToday: '',
          ReadCapacityUnits: '',
          WriteCapacityUnits: '',
          StreamEnabled: '',
          StreamViewType: '',
          TableArn: '',
          TableId: '',
          TableSizeBytes: '',
          TableStatus: '',
        };

  if (descTableData) {
    if (descTableData.Table) {
      const tbl = descTableData.Table;
      retTblInfo.CreationDateTime = tbl.CreationDateTime;
      retTblInfo.AttributeCount = tbl.AttributeDefinitions.length;
      retTblInfo.ItemCount = tbl.ItemCount;
      retTblInfo.KeySchemaCount = tbl.KeySchema.length;
      retTblInfo.LatestStreamArn = tbl.LatestStreamArn;
      retTblInfo.LatestStreamLabel = tbl.LatestStreamLabel;
      retTblInfo.TableArn = tbl.TableArn;
      retTblInfo.TableId = tbl.TableId;
      retTblInfo.TableSizeBytes = tbl.TableSizeBytes;
      retTblInfo.TableStatus = tbl.TableStatus;
      if (tbl.ProvisionedThroughput) {
        retTblInfo.LastDecreaseDateTime = tbl.ProvisionedThroughput.LastDecreaseDateTime;
        retTblInfo.LastIncreaseDateTime = tbl.ProvisionedThroughput.LastIncreaseDateTime;
        retTblInfo.NumberOfDecreasesToday = tbl.ProvisionedThroughput.NumberOfDecreasesToday;
        retTblInfo.ReadCapacityUnits = tbl.ProvisionedThroughput.ReadCapacityUnits;
        retTblInfo.WriteCapacityUnits = tbl.ProvisionedThroughput.WriteCapacityUnits;
      }
      if (tbl.StreamSpecification) {
        retTblInfo.StreamEnabled = tbl.StreamSpecification.StreamEnabled;
        retTblInfo.StreamViewType = tbl.StreamSpecification.StreamViewType;
      }
      if (tbl.GlobalSecondaryIndexes) {
        retTblInfo.GlobalSecondaryIndexesCount = tbl.GlobalSecondaryIndexes.length;
      }
      if (tbl.LocalSecondaryIndexes) {
        retTblInfo.LocalSecondaryIndexesCount = tbl.LocalSecondaryIndexes.length;
      }
      console.log('Table Info retTblInfo:', JSON.stringify(retTblInfo, null, 2));
    }
  }
  return retTblInfo;
};

export const getTableInfoAllTables = async (stagename) => {
  let tablelist = [];
  const currentParams = {
    ExclusiveStartTableName: stagename,
    Limit: 100,
  };
  const tbls = await getTablesFromDB(currentParams);

  tablelist = await Promise.all(tbls.map(async (tablename) => {
    const tblInfo = await getTableInfo(tablename);
    return tblInfo;
  }));
  console.log(`Table Info All Tables:${JSON.stringify(tablelist, null, 2)}`);
  return tablelist;
};

export const HasHistoryTable = async (tablename) => {
  const resp = {
    HistoryTableExists: 'false',
    HistoryTableName: '',
    HistoryTableVersion: '',
    TableName: tablename,
  };
  // if real table
  const descTableData = await getTableMetaData(tablename);
  if (descTableData) {
    // check for history
    const v1HistTableName = `${tablename.substring(0, tablename.length - 1)}-history`;
    try {
      const descV1TableData = await getTableMetaData(v1HistTableName);
      if (descV1TableData) {
        resp.HistoryTableExists = 'true';
        resp.HistoryTableName = v1HistTableName;
        resp.HistoryTableVersion = '1';
        return resp;
      }
    } catch (err) {
      console.log(`Error getting V1histTable meta data, Table: ${v1HistTableName}, Error:${JSON.stringify(err, null, 2)}`);
    }
    const v2HistTableName = `${tablename.substring(0, tablename.length - 1)}-history-v2`;
    try {
      const descV1TableData = await getTableMetaData(v2HistTableName);
      if (descV1TableData) {
        resp.HistoryTableExists = 'true';
        resp.HistoryTableName = v2HistTableName;
        resp.HistoryTableVersion = '2';
        return resp;
      }
    } catch (err2) {
      console.log(`Error getting v2HistTable meta data, Table: ${v2HistTableName}, Error:${JSON.stringify(err2, null, 2)}`);
    }
  }
  return resp;
};

export const getHistoryInfoAllTables = async (stagename) => {
  let tablelist = [];
  const currentParams = {
    ExclusiveStartTableName: stagename,
    Limit: 100,
  };
  const tbls = await getTablesFromDB(currentParams);

  tablelist = await Promise.all(tbls.map(async (tablename) => {
    const histInfo = await HasHistoryTable(tablename);
    return histInfo;
  }));
  console.log(`History Info All Tables:${JSON.stringify(tablelist, null, 2)}`);

  return tablelist;
};

export const EnableHistoryOnTables = async (EnableTableList) => {
  if (EnableTableList) {
    const objRetArray = await Promise.all(EnableTableList.map(async (tablename) => {
      const historyStatus = await createHistoryTable(tablename);
      const objRet = {
        TableName: tablename,
      };
      Object.assign(objRet, historyStatus);
      return objRet;
    }));
    return objRetArray;
  }
};

export const createHistoryTable = async (tablename) => {
  const historyTable = `${tablename}-history-v2`;
  const retStatus = {
    TableName: tablename,
    HistoryTableName: historyTable,
    TableStatus: 'UNKNOWN',
    IndexStatus: '',
  };

  const currentParams = {
    TableName: historyTable,
    AttributeDefinitions: [
      { AttributeName: 'HistoryId', AttributeType: 'S' },
      { AttributeName: 'Rowkey', AttributeType: 'S' },
    ],
    KeySchema: [
      { AttributeName: 'HistoryId', KeyType: 'HASH' }, // Partition key
      { AttributeName: 'Rowkey', KeyType: 'RANGE' }, // sort key
    ],
    ProvisionedThroughput: {
      ReadCapacityUnits: 2,
      WriteCapacityUnits: 2,
    },
  };

    // create table if it doesnt exists
  const tblstatus = await getTableMetaData(tablename);
  if (tblstatus) {
    const histTableExists = await getTableMetaData(historyTable);
    console.log(`History Table ${historyTable} Exists Check Desc:${JSON.stringify(histTableExists, null, 2)}`);
    if (histTableExists) {
      console.log(`History Tables Exists:${historyTable}, Status: ${histTableExists.Table.TableStatus}`);
      retStatus.TableStatus = histTableExists.Table.TableStatus;
    } else {
      console.log(`Creating table: ${historyTable}`);
      const resp = await AwsDynamoDB.createTable(currentParams).promise();
      if ((resp) && (resp.TableDescription)) {
        if (resp.TableDescription.TableStatus) {
          retStatus.TableStatus = resp.TableDescription.TableStatus;
          await delay(18000);
        }
      }
      const indexresp = await CreateRowKeyIndex(historyTable);
      if ((indexresp) && (indexresp.TableDescription)) {
        if (indexresp.TableDescription.TableStatus) {
          retStatus.IndexStatus = indexresp.TableDescription.TableStatus;
          await delay(18000);
        }
      }
      console.log(`History Table creation:${JSON.stringify(resp, null, 2)}`);
    }
  } else {
    retStatus.TableStatus = 'NOT CREATED';
  }
  return retStatus;
};

const CreateRowKeyIndex = async (tablename) => {
  const params = {
    TableName: tablename,
    AttributeDefinitions: [
      { AttributeName: 'HistoryDate', AttributeType: 'S' },
      { AttributeName: 'HistoryCreated', AttributeType: 'S' },
    ],
    GlobalSecondaryIndexUpdates: [
      {
        Create: {
          IndexName: 'Idx-RowKey-HistoryCreated',
          KeySchema: [
            { AttributeName: 'HistoryDate', KeyType: 'HASH' },
            { AttributeName: 'HistoryCreated', KeyType: 'RANGE' },
          ],
          Projection: {
            ProjectionType: 'ALL',
          },
          ProvisionedThroughput: {
            ReadCapacityUnits: 2, WriteCapacityUnits: 2,
          },
        },
      },
    ],
  };
  const resp = await AwsDynamoDB.updateTable(params).promise();
  console.log(`Index creation:${JSON.stringify(resp, null, 2)}`);
  return resp;
};

export const isTableStatusActive = async (tablename, retryOnce = false, waitTimeInSecs = 10) => {
  let retVal = false;
  const checkTableParams = {
    TableName: tablename,
  };

  try {
    const waitTblresp = await AwsDynamoDB.waitFor('tableExists', checkTableParams).promise();
    if ((waitTblresp) && (waitTblresp.Table)) {
      if (waitTblresp.Table.TableStatus === 'ACTIVE') {
        retVal = true;
      } else {
        let retryCnt = (retryOnce === true) ? 1 : 0;
        let resp;
        if (retryCnt > 0) {
          sleep.sleep(waitTimeInSecs);
          resp = await isTableStatusActive(tablename, false, waitTimeInSecs);
          retryCnt -= 1;
        }
        retVal = resp;
      }
    }
  } catch (err) {
    console.warn(`Error finding if table exists:${tablename}`);
    console.warn(err);
    retVal = false;
  }
  return retVal;
}
;
