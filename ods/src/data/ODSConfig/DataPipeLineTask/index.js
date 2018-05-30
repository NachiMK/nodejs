"use strict";
import { executeQueryRS, executeCommand, executeScalar } from '../../psql/index.js';
import { CreatingDataPipeLineTaskError } from '../../../modules/ODSErrors/DataPipeLineTaskQueueError';
export {
    createDynamoDBToS3PipeLineTask,
    UpdatePipeLineTaskStatus
};

async function createDynamoDBToS3PipeLineTask(TableName, RowCount){
    let DataFilePrefix = undefined;
    let S3DataFileFolderPath = undefined;
    let DataPipeLineTaskQueueId = undefined;

    try {
        let sqlQuery = await getQuery(TableName, RowCount);
        let dbName = await getDBName("ODSConfig");
        let batchKey = 1;
        let params = {
            "Query": sqlQuery,
            "DBName": dbName,
            "BatchKey": batchKey,
        }
        let retRS = await executeQueryRS(params);
        console.log(`create DataPipeLinetaskQueue status: ${JSON.stringify(retRS)}`);
    }
    catch(err){
        let msg = `Issue creating DataPipeLineTaskQueueId for Table: ${TableName} with Rows: ${RowCount}`;
        let er = new CreatingDataPipeLineTaskError(msg, err);
        throw er;
    }

    let RetResp = {
        DataFilePrefix,
        S3DataFileFolderPath,
        DataPipeLineTaskQueueId,
    };

    return RetResp;
}

async function UpdatePipeLineTaskStatus(DataPipeLineTaskQueueId, Status, StatusError={}){

}

async function getQuery(TableName, RowCount){
    return `SELECT * FROM ods."udf_createDynamoDBToS3PipeLineTask"('${TableName}', ${RowCount})`;
}

async function getDBName(DBName){
    return ((typeof DBName === undefined) || (DBName.Length === 0)) ? "ODSConfig" : DBName;
}