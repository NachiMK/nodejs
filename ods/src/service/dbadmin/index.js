import { createHistoryTable, EnableStreaming, LinkTableToTrigger } from '.';

const delay = require('delay');

export * from '../dbadmin/dynamo';
export * from '../dbadmin/lambda';

export const enableHistory = async (tablename, envStage = '') => {
  const retStatus = {
    TableName: tablename,
    IsHistoryCreated: '',
    IsStreamEnabled: '',
    IsTriggerLinked: '',
  };
  const mystage = envStage || process.env.STAGE;

  const createhistStatus = await createHistoryTable(tablename);
  if ((createhistStatus) && (createhistStatus.TableStatus.localeCompare('UNKNOWN') !== 0)) {
    retStatus.IsHistoryCreated = true;
    const enableStreamStatus = await EnableStreaming(tablename);
    if ((enableStreamStatus) && (enableStreamStatus === true)) {
      retStatus.IsStreamEnabled = true;
      await delay(18000);
      const linkStatus = await LinkTableToTrigger(tablename, mystage);
      retStatus.IsTriggerLinked = ((linkStatus) && (linkStatus === true));
    }
  }

  return retStatus;
};

export const enableStreamingAndLinkTrigger = async (tablename, envStage = '') => {
  const retStatus = {
    TableName: tablename,
    IsHistoryCreated: '',
    IsStreamEnabled: '',
    IsTriggerLinked: '',
  };
  const mystage = envStage || process.env.STAGE;

  const enableStreamStatus = await EnableStreaming(tablename);
  if ((enableStreamStatus) && (enableStreamStatus === true)) {
    retStatus.IsStreamEnabled = true;
    await delay(18000);
    const linkStatus = await LinkTableToTrigger(tablename, mystage);
    retStatus.IsTriggerLinked = ((linkStatus) && (linkStatus === true));
  }
  return retStatus;
};
