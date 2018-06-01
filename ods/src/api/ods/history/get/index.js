import ware from 'warewolf';
// import path from 'path';
// import { validateParams } from '@hixme/validator-middleware';
import { before, after } from '@hixme/before-after-middleware';
import * as dynamoservice from '../../../../service/ods/history';
// require('../get/HistoryTable.json');

export const getHistory = ware(
  before,
  // validateParams(path.join(__dirname, 'HistoryTable.json')),
  async (event) => {
    const dynamotablename = event.queryAndParams.DynamoTableName;
    const params = {
      DynamoTableName: dynamotablename,
      StartDate: '',
      EndDate: '',
    };
    const tableHistoryRows = await dynamoservice.getHistory(params);
    event.result = tableHistoryRows;
  },
  after,
);


export const getHistoryv1 = ware(
  before,
  // validateParams(path.join(__dirname, 'HistoryTableV1.json')),
  async (event) => {
    const v1dynamotablename = event.queryAndParams.DynamoTableName;
    const params = {
      DynamoTableName: v1dynamotablename,
      EventDate: '',
    };
    const tableHistoryRows = await dynamoservice.getHistoryv1(params);
    event.result = tableHistoryRows;
  },
  after,
);
