import table from '@hixme/tables';
let aws = require('aws-sdk');
aws.config.update({region: "us-west-2"});

export async function migrateHistory2(options = {}) {
    
    const {
        source_table = "",
        destination_table = "",
    } = options;
    let source_cnt = 0;
    let dest_cnt = 0;

  const historytable = createTable(source_table);
  const historyRows = await historytable.getAll();

    if ((historyRows) && (historyRows.length > 0)){
        source_cnt = historyRows.length;
        dest_cnt = await migrateToDestination(historyRows, destination_table);
    }

    let resp = {
        "source_count" : source_cnt,
        "destination_count" : dest_cnt
    };

    return resp;
}

function createTable(table_name) {
  //const stage = process.env.STAGE;

  table.config({
    tablePrefix: "",
    debug: false,
  });

  return table.create(table_name);
}

export async function migrateHistory(options = {}) {
    const {
        source_table = "",
        destination_table = "",
    } = options;
    
    let params = {
        "TableName":source_table,
    };
    
    let resp = await migrateRowsInBatch(params, destination_table);
    return resp;
}

async function migrateRowsInBatch(options={}, destination_table){

    let resp = {
        "source_count" : 0,
        "destination_count" : 0
    };

    try{
        let docClient = new aws.DynamoDB.DocumentClient();
        let dynamoDataObj = await docClient.scan(options).promise();

        if (dynamoDataObj){
            resp.source_count += dynamoDataObj.Count;
            // migrate rows
            resp.destination_count += await migrateToDestination(dynamoDataObj.Items, destination_table);
            // continue scanning if we have more items
            if (typeof dynamoDataObj.LastEvaluatedKey != "undefined") {
                console.log("Scanning for more...");
                options.ExclusiveStartKey = dynamoDataObj.LastEvaluatedKey;
                let resp2 = await migrateRowsInBatch(options);
                resp.source_count += resp2.source_count;
                resp.destination_count += resp2.destination_count;
            }
        }
    }
    catch(err){
        console.warn(`Error migrating rows:${JSON.stringify(options,null,2)}`);
        console.warn(`Error:${err}`);
    }

    return resp;
}


async function migrateToDestination(rowsToMigrate, destTable){

    let rowCnt = 0;
    let docClient = new aws.DynamoDB.DocumentClient();
    rowCnt = rowsToMigrate.reduce((totalRowCount, e, idx) => {
        var item = {
            "HistoryId": e.Id,
            "HistoryAction": e.eventName,
            "HistoryDate": e.created.slice(0,10).replace(/-/g,""),
            "HistoryCreated":e.created,
            "Rowkey": e.key,
          };
          Object.assign(item, e.eventRecord);
          try{
            let params = {
                  TableName: destTable,
                  Item: item
            }
            docClient.put(params).promise();
            totalRowCount++;
          }
          catch(err){
              console.warn("Error migrating record:" + JSON.stringify(item, null, 2));
          }
          return totalRowCount;
    }, 0);

    return rowCnt;
  }
