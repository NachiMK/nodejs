import { handler } from './index';
import ODSLogger from '../../../../modules/log/ODSLogger';

const eventjson = require('./event.json');

handler(eventjson, null)
  .then(res => processHandlerResp(res))
  .then(() => console.log('Done'))
  .catch(e => console.log('error', e));

const processHandlerResp = async (res) => {
  await ODSLogger.log('info', 'res in processHandlerResp %j', res);
  console.log('test:');
};
