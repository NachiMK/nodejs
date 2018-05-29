'use strict';
var AWS = require('aws-sdk');
const table = require('@hixme/tables');
import {getTablesFromDB} from '../table/index';

var _ = require('lodash');

const aws_dynamo = new AWS.DynamoDB({region: "us-west-2"});   

export const getTablesWithNoStreams = async (TableNameSubString="dev") => {
    let tables = await getStreamSpecAllTables();
    if (tables){
        let tbls = tables.map((tablespec) => {
            let tablename  = tablespec.TableName;
            if ((!tablespec.StreamEnabled) && (tablename.includes(TableNameSubString))){
                // stream IS NOT enabled so return it.
                return tablespec.TableName;
            }
        });
        return tbls.filter( table => !_.isUndefined(table));
    }
    return;
}

const getStreamSpecAllTables = async (stage_name) => {
    let params = {
        ExclusiveStartTableName: stage_name,
        Limit: 100
      };
    const tables = await(getTablesFromDB(params));
    const tableStreamSpecs = await Promise.all(tables.map(async (tablename) => {
        //
        const streamingTable = await getStreamSpecification(tablename);
        return streamingTable;
    }));
    console.log("Tables:" + JSON.stringify(tableStreamSpecs,null,2));
    return tableStreamSpecs;
}

const getStreamSpecification = async (tablename) => {
    //let aws_dynamo = new AWS.DynamoDB(); 
    var params = {
        TableName: tablename
      };

    let streamdetail = {
        "TableName": tablename,
        "StreamEnabled": false,
        "StreamViewType": ""
    }
    try{
        const descTableData = await aws_dynamo.describeTable(params).promise();
        if (descTableData){
            if (descTableData.Table.hasOwnProperty("StreamSpecification")){
                streamdetail.StreamEnabled = descTableData.Table.StreamSpecification.StreamEnabled;
                streamdetail.StreamViewType = descTableData.Table.StreamSpecification.StreamViewType;
            }
            else
            {
                console.log("Table :" + tablename + " has no streams enabled");
                streamdetail.StreamEnabled = false;
            }
            console.log(`Table: ${tablename}, stream details:${streamdetail}`);
        }
    }
    catch(err){
        console.warn(`Error in finding Stream status for table ${tablename}, Error: ${err}`);
        console.warn(`Error:${JSON.stringify(err, null, 2)}`);
        streamdetail.StreamEnabled = undefined;
    }
    return streamdetail;
};

export const EnableStreaming = async (tablename, streamtype="NEW_AND_OLD_IMAGES") => {
    var params = {
        "StreamSpecification": { 
            "StreamEnabled": true,
            "StreamViewType": streamtype || "NEW_AND_OLD_IMAGES"
         },
         "TableName": tablename
      };
    try{
        let streanstatus = await getStreamSpecification(tablename);
        console.log(`Table: ${tablename}, Stream Status: ${JSON.stringify(streanstatus,null,2)}`);
        if ((streanstatus) && (streanstatus.StreamEnabled) && (streanstatus.StreamEnabled == true)){
            console.log("Stream Already Enabled for Table!");
            return streanstatus.StreamEnabled;
        }
        const updateTableResults = await aws_dynamo.updateTable(params).promise();
        console.log("Update Response:" + JSON.stringify(updateTableResults,null,2));
        if (updateTableResults){
            //check if streaming was enabled
            if (updateTableResults.hasOwnProperty("TableDescription")
                && updateTableResults.TableDescription.hasOwnProperty("StreamSpecification")){
                    return updateTableResults.TableDescription.StreamSpecification.StreamEnabled;
            }
        }
    }
    catch(err){
        console.warn(err);
    }
    return false;
};

export const DisableStreaming = async (tablename) => {
    var params = {
        "StreamSpecification": { 
            "StreamEnabled": false
         },
         "TableName": tablename
      };
    const updateTableResults = await aws_dynamo.updateTable(params).promise();
    console.log("Delete Stream Response:" + JSON.stringify(updateTableResults,null,2));
    if (updateTableResults){
        //check if streaming was enabled
        if (updateTableResults.hasOwnProperty("TableDescription")){
            if (!updateTableResults.TableDescription.hasOwnProperty("StreamSpecification")){
                return true;
            }
            else{
                let streamspec = updateTableResults.TableDescription.StreamSpecification;
                if (!streamspec.hasOwnProperty("StreamEnabled")){
                    return streamspec.StreamEnabled;
                }
            }
        }
    }
    return false;
};

export const EnableStreamingOnTables = async (TableList, streamtype="NEW_AND_OLD_IMAGES") => {
    let params = {};
    if (TableList){
        let objRetArray = await Promise.all(TableList.map(async (tablename) => {
            let streamEnabledStatus = await EnableStreaming(tablename, streamtype);
            let objRet = {
                "TableName": tablename,
                "StreamEnabled": streamEnabledStatus
            }
            return objRet;
        }));
        return objRetArray;
    }
    return;
}

export default getStreamSpecAllTables;