import * as dynamoTables from '../src/service/dbadmin/dynamo/table/index';
var fs = require('fs');

describe('Test DB Admin Functions', () => {

    it('Get All Tables', async () => {
        console.log("Get All Tables:");
        const resp = await dynamoTables.getTablesFromDB("", "dev");
        console.log("return list in test:" + JSON.stringify(resp,null,2));
        expect(resp.length === 0).toEqual(false);
    });
    
    it('Get Table Meta data', async () => {
        console.log("Get table Meta data:");
        const resp = await dynamoTables.getTableMetaData("dev-fundings");
        console.log("Metadata:" + JSON.stringify(resp,null,2));
        expect(typeof resp === undefined).toEqual(false);
    });

    it('Get Table Row Count', async () => {
        console.log("Get Table Row count:");
        const resp = await dynamoTables.getTableRowCount("dev-fundings");
        console.log("Row Count:" + JSON.stringify(resp,null,2));
        expect(resp >= 0).toEqual(true); //or ResourceNotFoundException
    });

    it('Get Table Attribute Count', async () => {
        console.log("Get Table Attribute count:");
        const resp = await dynamoTables.getAttributeCount("dev-fundings");
        console.log("Row Count:" + JSON.stringify(resp,null,2));
        expect(resp >= 0).toEqual(true); //or ResourceNotFoundException
    });

    it('Get Single Table Info', async () => {
        console.log("Get Single Table Info:");
        const resp = await dynamoTables.getTableInfo("dev-clients");
        console.log("Tbl Info:" + JSON.stringify(resp,null,2));
        expect(typeof resp !== undefined).toEqual(true); //or ResourceNotFoundException
    });

    it('Get Table Info All Tables', async () => {
        console.log("Get Table Info All Tables:");
        const resp = await dynamoTables.getTableInfoAllTables("prod");
        console.log("Tbl Info All Tables:" + JSON.stringify(resp,null,2));
        fs.writeFile("/Users/Nachi/Documents/myjunk/nodeoutput/ods/allTableInfo.json", JSON.stringify(resp,null,2));
        expect(typeof resp !== undefined).toEqual(true); //or ResourceNotFoundException
        expect(resp.length !== 0).toEqual(true); //or ResourceNotFoundException
    });

    it('Check has History', async () => {
        console.log("Check has History:");
        const resp = await dynamoTables.HasHistoryTable("dev-clients");
        console.log("History:" + JSON.stringify(resp,null,2));
        expect(resp.HistoryTableExists === "true").toEqual(true); //or ResourceNotFoundException
    });

    it('Get History info for all tables', async () => {
        console.log("Get History info for all tables:");
        const resp = await dynamoTables.getHistoryInfoAllTables("prod");
        console.log("History for all Tables:" + JSON.stringify(resp,null,2));
        fs.writeFile("/Users/Nachi/Documents/myjunk/nodeoutput/ods/history.json", JSON.stringify(resp,null,2));
        expect(resp.length >= 0).toEqual(true); //or ResourceNotFoundException
    });

    it('Create History Table', async () => {
        console.log("Create History Table:");
        const resp = await dynamoTables.createHistoryTable("dev-clients");
        console.log("Created?" + JSON.stringify(resp,null,2));
        expect(typeof resp === undefined).toEqual(false); //or ResourceNotFoundException
    });

  });
  