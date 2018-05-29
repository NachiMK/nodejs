import { createHistoryTable, EnableStreaming, LinkTableToTrigger } from '.';
import { link } from 'fs';
var delay = require('delay');

export * from '../dbadmin/dynamo';
export * from '../dbadmin/lambda';

export const enableHistory = async (tablename, envStage="") => {

    let retStatus = {
        "TableName": tablename,
        "IsHistoryCreated" : "",
        "IsStreamEnabled" : "",
        "IsTriggerLinked" : ""
    }
    let s = "".localeCompare("", )
    let mystage = envStage || process.env.STAGE;

    let createhistStatus = await createHistoryTable(tablename);
    if ((createhistStatus) && (createhistStatus.TableStatus.localeCompare("UNKNOWN") !== 0)){
        retStatus.IsHistoryCreated = true;
        let enableStreamStatus = await EnableStreaming(tablename);
        if ((enableStreamStatus) && (enableStreamStatus == true)){
            retStatus.IsStreamEnabled = true;
            await delay(18000);
            let linkStatus = await LinkTableToTrigger(tablename, mystage);
            retStatus.IsTriggerLinked = ((linkStatus) && (linkStatus == true));
        }
    }
    
    return retStatus;
}