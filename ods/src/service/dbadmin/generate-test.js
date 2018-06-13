import { enableStreamingAndLinkTrigger } from './index';
import ODSLogger from '../../modules/log/ODSLogger';

enableStreamingAndLinkTrigger('dev-clients', 'dev')
  .then(res => processHandlerResp(res))
  .catch(e => console.log('error', e));

const processHandlerResp = async (res) => {
  await ODSLogger.log('info', 'res in processHandlerResp %j', res);
};

// npm run build && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/service/dbadmin/generate-test.js
