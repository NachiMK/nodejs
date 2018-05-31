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
    const tableHistoryRows = await dynamoservice.gethistory(dynamotablename, '', '', '');
    event.result = tableHistoryRows;
  },
  after,
);


export const getHistoryv1 = ware(
  before,
  // validateParams(path.join(__dirname, 'HistoryTableV1.json')),
  async (event) => {
    const v1dynamotablename = event.queryAndParams.DynamoTableName;
    const tableHistoryRows = await dynamoservice.gethistoryv1(v1dynamotablename, '', '');
    event.result = tableHistoryRows;
  },
  after,
);
