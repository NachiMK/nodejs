'use strict';
var AWS = require('aws-sdk');
const table = require('@hixme/tables');
var _ = require('lodash');
var delay = require('delay');

const aws_dynamo = new AWS.DynamoDB({region: "us-west-2"});
let TableList = [];

export const getTablesFromDB = async (params, TableNameFilter="") => {
    var currentParams = params || {
        ExclusiveStartTableName: TableNameFilter || "dev",
        Limit: 100
      };
      const items = await aws_dynamo.listTables(currentParams).promise();
      TableList = TableList.concat(items.TableNames.filter( (name) => name.toLocaleLowerCase().includes(TableNameFilter.toLocaleLowerCase())));

      if (items.LastEvaluatedTableName) {
          currentParams.ExclusiveStartTableName = items.LastEvaluatedTableName;
          return getTablesFromDB(currentParams, TableNameFilter);
      }
      return TableList;
}

export const getTableMetaData = async (tablename) => {
    //let aws_dynamo = new AWS.DynamoDB(); 
    var params = {
        TableName: tablename
      };
    try {
        const descTableData = await aws_dynamo.describeTable(params).promise();
        if (descTableData) {
            console.log(descTableData);
            return descTableData;
        }
    }
    catch (err) {
        console.warn(`Error finding Table info for Table: ${tablename}`);
        console.warn(`Error:${err}`);
    }
    return;
};

export const getTableRowCount = async (tablename) => {
    const descTableData = await getTableMetaData(tablename);
    if (descTableData){
        if (descTableData.hasOwnProperty("Table") && descTableData.Table.hasOwnProperty("ItemCount")){
            return descTableData.Table.ItemCount;
        }
    }
    return;
};

export const getAttributeCount = async (tablename) => {
    const descTableData = await getTableMetaData(tablename);
    if (descTableData){
        if (descTableData.hasOwnProperty("Table") &&
            descTableData.Table.hasOwnProperty("AttributeDefinitions")){
            return descTableData["Table"].AttributeDefinitions.length;
        }
    }
    return;
}

export const getTableInfo = async (tablename) => {
    const descTableData = await getTableMetaData(tablename);
    let retTblInfo = 
        {
            "TableName": tablename,
            "CreationDateTime":"",
            "AttributeCount": 0,
            "GlobalSecondaryIndexesCount": 0,
            "ItemCount": 0,
            "KeySchemaCount" : 0,
            "LocalSecondaryIndexesCount" : 0,
            "LatestStreamArn": "",
            "LatestStreamLabel": "",
            "LastDecreaseDateTime": "",
            "LastIncreaseDateTime": "",
            "NumberOfDecreasesToday": "",
            "ReadCapacityUnits": "",
            "WriteCapacityUnits": "",
            "StreamEnabled": "",
            "StreamViewType": "",
            "TableArn": "",
            "TableId": "",
            "TableSizeBytes": "",
            "TableStatus": ""
        }

    if (descTableData){
        if (descTableData.hasOwnProperty("Table")){
            let tbl = descTableData["Table"];
            retTblInfo["CreationDateTime"]=tbl.CreationDateTime;
            retTblInfo["AttributeCount"]=tbl.AttributeDefinitions.length;
            retTblInfo["ItemCount"]=tbl.ItemCount;
            retTblInfo["KeySchemaCount"]=tbl.KeySchema.length;
            retTblInfo["LatestStreamArn"]=tbl.LatestStreamArn;
            retTblInfo["LatestStreamLabel"]=tbl.LatestStreamLabel;
            retTblInfo["TableArn"]=tbl.TableArn;
            retTblInfo["TableId"]=tbl.TableId;
            retTblInfo["TableSizeBytes"]=tbl.TableSizeBytes;
            retTblInfo["TableStatus"]=tbl.TableStatus;
            if (tbl.hasOwnProperty("ProvisionedThroughput")){
                retTblInfo["LastDecreaseDateTime"]=tbl["ProvisionedThroughput"].LastDecreaseDateTime;
                retTblInfo["LastIncreaseDateTime"]=tbl["ProvisionedThroughput"].LastIncreaseDateTime;
                retTblInfo["NumberOfDecreasesToday"]=tbl["ProvisionedThroughput"].NumberOfDecreasesToday;
                retTblInfo["ReadCapacityUnits"]=tbl["ProvisionedThroughput"].ReadCapacityUnits;
                retTblInfo["WriteCapacityUnits"]=tbl["ProvisionedThroughput"].WriteCapacityUnits;
            }
            if (tbl.hasOwnProperty("StreamSpecification")){
                retTblInfo["StreamEnabled"]=tbl["StreamSpecification"].StreamEnabled;
                retTblInfo["StreamViewType"]=tbl["StreamSpecification"].StreamViewType;
            }
            if (tbl.hasOwnProperty("GlobalSecondaryIndexes")){
                retTblInfo["GlobalSecondaryIndexesCount"]=tbl.GlobalSecondaryIndexes.length;
            }
            if (tbl.hasOwnProperty("LocalSecondaryIndexes")){
                retTblInfo["LocalSecondaryIndexesCount"]=tbl.LocalSecondaryIndexes.length;
            }
            console.log("Table Info retTblInfo:", JSON.stringify(retTblInfo,null,2));
        }
    }
    return retTblInfo;
}

export const getTableInfoAllTables = async (stagename) => {
    let tablelist = [];
    var currentParams = {
        ExclusiveStartTableName: stagename,
        Limit: 100
      };
    let tbls = await getTablesFromDB(currentParams);
    
    tablelist = await Promise.all(tbls.map(async (tablename) => {
        const tblInfo = await getTableInfo(tablename);
        return tblInfo;
    }));
    console.log("Table Info All Tables:" + JSON.stringify(tablelist,null,2));
    return tablelist;
}

export const HasHistoryTable = async (tablename) => {
    let resp = {
        HistoryTableExists : "false",
        HistoryTableName : "",
        HistoryTableVersion: "",
        TableName : tablename
    }
    // if real table
    const descTableData = await getTableMetaData(tablename);
    if (descTableData){
        // check for history
        let v1HistTableName = tablename.substring(0, tablename.length-1) + "-history";
        try{
            const descV1TableData = await getTableMetaData(v1HistTableName);
            if (descV1TableData){
                resp["HistoryTableExists"] = "true";
                resp["HistoryTableName"] = v1HistTableName;
                resp["HistoryTableVersion"] ="1";
                return resp;
            }
        }
        catch(err){
        }
        try{
            let v2HistTableName = tablename.substring(0, tablename.length-1) + "-history-v2";
            const descV1TableData = await getTableMetaData(v2HistTableName);
            if (descV1TableData){
                resp["HistoryTableExists"] = "true";
                resp["HistoryTableName"] = v2HistTableName;
                resp["HistoryTableVersion"] ="2";
                return resp;
            }
        }
        catch(err2){
        }
    }
    return resp;
}

export const getHistoryInfoAllTables = async (stagename) => {
    let tablelist = [];
    var currentParams = {
        ExclusiveStartTableName: stagename,
        Limit: 100
      };
    let tbls = await getTablesFromDB(currentParams);
    
    tablelist = await Promise.all(tbls.map(async (tablename) => {
        const histInfo = await HasHistoryTable(tablename);
        return histInfo;
    }));
    console.log("History Info All Tables:" + JSON.stringify(tablelist,null,2));

    return tablelist;
}

export const EnableHistoryOnTables = async (TableList) => {
    if (TableList){
        let objRetArray = await Promise.all(TableList.map(async (tablename) => {
            let historyStatus = await createHistoryTable(tablename);
            let objRet = {
                "TableName": tablename
            }
            Object.assign(objRet, historyStatus);
            return objRet;
        }));
        return objRetArray;
    }
    return;
}

export const createHistoryTable = async (tablename) => {
    let historyTable = tablename + "-history-v2";
    let retStatus = {
        "TableName": tablename,
        "HistoryTableName": historyTable,
        "TableStatus": "UNKNOWN",
        "IndexStatus" : ""
    };

    let currentParams = {
        TableName : historyTable,
        AttributeDefinitions: [       
            { AttributeName: "HistoryId", AttributeType: "S" },
            { AttributeName: "Rowkey", AttributeType: "S" }
        ],
        KeySchema: [       
            { AttributeName: "HistoryId", KeyType: "HASH"},  //Partition key
            { AttributeName: "Rowkey", KeyType: "RANGE" } //sort key
        ],
        ProvisionedThroughput: {       
            ReadCapacityUnits: 2, 
            WriteCapacityUnits: 2
        }
    };

    // create table if it doesnt exists
    let tblstatus = await getTableMetaData(tablename);
    if (tblstatus) {
        let histTableExists = await getTableMetaData(historyTable);
        console.log(`History Table ${historyTable} Exists Check Desc:${JSON.stringify(histTableExists, null, 2)}`);
        if (histTableExists) {
            console.log(`History Tables Exists:${historyTable}, Status: ${histTableExists.Table.TableStatus}`);
            retStatus.TableStatus = histTableExists.Table.TableStatus;
        }
        else {
            console.log(`Creating table: ${historyTable}`);
            const resp = await aws_dynamo.createTable(currentParams).promise();
            if ((resp) && (resp.hasOwnProperty("TableDescription"))) {
                if (resp.TableDescription.hasOwnProperty("TableStatus")) {
                    retStatus.TableStatus = resp.TableDescription.TableStatus;
                    await delay(18000);
                }
            }
            const indexresp = await create_row_key_index(historyTable);
            if ((indexresp) && (indexresp.hasOwnProperty("TableDescription"))) {
                if (indexresp.TableDescription.hasOwnProperty("TableStatus")) {
                    retStatus.IndexStatus = indexresp.TableDescription.TableStatus;
                    await delay(18000);
                }
            }
            console.log("History Table creation:" + JSON.stringify(resp, null, 2));
        }
    }
    else {
        retStatus.TableStatus = "NOT CREATED";
    }
    return retStatus;
}

const create_row_key_index = async (tablename) => {
    var params = {
        TableName : tablename,
        AttributeDefinitions: [       
            { AttributeName: "HistoryDate", AttributeType: "S" },
            { AttributeName: "HistoryCreated", AttributeType: "S" }
        ],
        GlobalSecondaryIndexUpdates: [
            {
                Create: {
                    IndexName: "Idx-RowKey-HistoryCreated",
                    KeySchema: [
                        {AttributeName: "HistoryDate", KeyType: "HASH"},
                        {AttributeName: "HistoryCreated", KeyType: "RANGE"}
                    ],
                    Projection: {
                        "ProjectionType": "ALL"
                    },
                    ProvisionedThroughput: {
                        "ReadCapacityUnits": 2,"WriteCapacityUnits": 2
                    }
                }
            }
        ]
    };
    const resp = await aws_dynamo.updateTable(params).promise();
    console.log("Index creation:" + JSON.stringify(resp,null,2));
    return resp;
}

export const isTableStatusActive = async (tablename, retryOnce=false, waitTimeInSecs = 10) => {
    let retVal = false;
    let checkTableParams = {
        TableName: tablename
    };

    try{
        let waitTblresp = await aws_dynamo.waitFor('tableExists', checkTableParams).promise();
        if ((waitTblresp) && (waitTblresp.hasOwnProperty("Table"))){
            if (waitTblresp.Table.TableStatus == "ACTIVE"){
                retVal = true;
            }
            else {
                let retryCnt = (retryOnce == true) ? 1 : 0;
                while (retryCnt > 0){
                    sleep.sleep(waitTimeInSecs);
                    let resp = await isTableStatusActive(tablename, false, waitTimeInSecs);
                    retryCnt--;
                }
                retVal = resp;
            }
        }
    }
    catch(err){
        console.warn("Error finding if table exists:" + tablename);
        console.warn(err);
        retVal = false;
    }
    return retVal;
}