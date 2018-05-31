import * as dynamoData from '../../../data/dynamo/history';

// export { getHistory, getHistoryv1 } from '../../data/dynamo';

export async function getHistory(options = {}) {
  let {
    StartDate = '',
    EndDate = '',
  } = options;

  const DynamoTableName = options.DynamoTableName;

  if (StartDate) {
    StartDate = new Date(Date.now() - 864e5);
    const s1 = `${StartDate.getUTCFullYear()}-${StartDate.getUTCMonth() + 1}-${StartDate.getUTCDate()}`;
    StartDate = new Date(s1);
  }

  if (EndDate) {
    EndDate = Date.now();
  }

  const params = {
    tableName: DynamoTableName,
    startDate: StartDate,
    endDate: EndDate,
  };

  const historyRows = await dynamoData.getHistory(params);
  return historyRows;
}

export async function getHistoryv1(options = {}) {
  const {
    DynamoTableName = '',
    EventDate = '',
  } = options;

  const params = {
    tableName: DynamoTableName,
    eventDate: EventDate,
  };

  const historyRows = await dynamoData.getHistoryv1(params);
  return historyRows;
}
