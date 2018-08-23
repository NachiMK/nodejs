import { handler } from './index'
import ODSLogger from '../../../../modules/log/ODSLogger'

const eventjson = require('./event.json')

handler(eventjson, null)
  .then((res) => processHandlerResp(res))
  .then(() => console.log('Done'))
  .catch((e) => console.log('error', e))

const processHandlerResp = async (res) => {
  await ODSLogger.log('info', 'res in processHandlerResp %j', res)
}

// npm run build && odsloglevel=info STAGE=DEV log_dbname=ODSLog node lib/service/dbadmin/dynamo/trigger/generate-test.js
