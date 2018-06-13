import { asyncForEach } from '../../modules/asyncloop/index';
import { getTablesToDeploy } from './index';
import { enableStreamingAndLinkTrigger } from '../../service/dbadmin';

export async function DeployLinkTriggerOnTables(envStage = '') {
  console.log('Deploy History Streaming and Triggers for multiple tables:');
  const tbls = getTablesToDeploy(envStage);

  await asyncForEach(tbls, async (tablename) => {
    console.warn(`-----Table:${tablename}----`);
    console.warn(`-----Start:${Date.now}----`);
    const stageforFunc = envStage || process.env.STAGE;
    const resp = await enableStreamingAndLinkTrigger(tablename, stageforFunc);
    console.warn(`Results ${JSON.stringify(resp, null, 2)}`);
    console.warn(`-----End:${Date.now}----`);
  });
}
