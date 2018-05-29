import { pick } from 'lodash';
import uuid from 'uuid';
import { validateAjv } from '@hixme/validator-middleware';
import * as dynamoData from '../../../data/dynamo/history';

//export { getHistory, getHistoryv1 } from '../../data/dynamo';

export async function getHistory(options = {}){
    const {
        DynamoTableName = "",
        StartDate = "",
        EndDate = "",
        PathToStorefile = ""
    } = options;

    if (StartDate){
        StartDate = new Date(Date.now() - 864e5); 
        let s1 = StartDate.getUTCFullYear() + '-' + (StartDate.getUTCMonth()+1) + '-' + StartDate.getUTCDate();
        StartDate = new Date(s1);
    }
    
    if (EndDate){
        EndDate = Date.now();
    }

    const params = {
        "table_name": DynamoTableName,
        "start_date": StartDate,
        "end_date": EndDate
    };
    
    let historyRows = await dynamoData.getHistory(params);
    return historyRows;
}

export async function getHistoryv1(options={}) {
    const {
        DynamoTableName = "",
        EventDate = "",
        PathToStorefile = ""
    } = options;
    
    const params = {
        "table_name": tablename,
        "event_date": event_date
    };
    
    let historyRows = await dynamoData.getHistoryv1(params);
    return historyRows;
}
