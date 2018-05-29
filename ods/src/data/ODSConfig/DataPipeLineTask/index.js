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
        let sqlQuery = getQuery(TableName, RowCount);
        let dbName = getDBName("ODSConfig");
        let batchKey = 1;
        let params = {
            "Query" : sqlQuery,
            "DBName" : dbName,
            "BatchKey" : batchKey,
        }
        let retRS = await executeQueryRS(params);
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