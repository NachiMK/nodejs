import table from '@hixme/tables';

const aws = require('aws-sdk');

aws.config.update({ region: 'us-west-2' });

export async function migrateHistory2(options = {}) {
  const {
    sourceTable = '',
    destinationTable = '',
  } = options;
  let sourceCnt = 0;
  let destCnt = 0;

  const historytable = createTable(sourceTable);
  const historyRows = await historytable.getAll();

  if ((historyRows) && (historyRows.length > 0)) {
    sourceCnt = historyRows.length;
    destCnt = await migrateToDestination(historyRows, destinationTable);
  }

  const resp = {
    source_count: sourceCnt,
    destination_count: destCnt,
  };

  return resp;
}

function createTable(tableName) {
  // const stage = process.env.STAGE;

  table.config({
    tablePrefix: '',
    debug: false,
  });

  return table.create(tableName);
}

export async function migrateHistory(options = {}) {
  const {
    sourceTable = '',
    destinationTable = '',
  } = options;

  const params = {
    TableName: sourceTable,
  };

  const resp = await migrateRowsInBatch(params, destinationTable);
  return resp;
}

async function migrateRowsInBatch(options = {}, destinationTable) {
  const resp = {
    source_count: 0,
    destination_count: 0,
  };

  try {
    const docClient = new aws.DynamoDB.DocumentClient();
    const dynamoDataObj = await docClient.scan(options).promise();

    if (dynamoDataObj) {
      resp.source_count += dynamoDataObj.Count;
      // migrate rows
      resp.destination_count += await migrateToDestination(dynamoDataObj.Items, destinationTable);
      // continue scanning if we have more items
      if (typeof dynamoDataObj.LastEvaluatedKey !== 'undefined') {
        console.log('Scanning for more...');
        options.ExclusiveStartKey = dynamoDataObj.LastEvaluatedKey;
        const resp2 = await migrateRowsInBatch(options);
        resp.source_count += resp2.source_count;
        resp.destination_count += resp2.destination_count;
      }
    }
  } catch (err) {
    console.warn(`Error migrating rows:${JSON.stringify(options, null, 2)}`);
    console.warn(`Error:${err}`);
  }

  return resp;
}


async function migrateToDestination(rowsToMigrate, destTable) {
  let rowCnt = 0;
  const docClient = new aws.DynamoDB.DocumentClient();
  rowCnt = rowsToMigrate.reduce((totalRowCount, e) => {
    const item = {
      HistoryId: e.Id,
      HistoryAction: e.eventName,
      HistoryDate: e.created.slice(0, 10).replace(/-/g, ''),
      HistoryCreated: e.created,
      Rowkey: e.key,
    };
    Object.assign(item, e.eventRecord);
    try {
      const params = {
        TableName: destTable,
        Item: item,
      };
      docClient.put(params).promise();
      totalRowCount += 1;
    } catch (err) {
      console.warn(`Error migrating record:${JSON.stringify(item, null, 2)}`);
    }
    return totalRowCount;
  }, 0);

  return rowCnt;
}
