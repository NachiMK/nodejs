import { handler } from './index';

const eventjson = require('./event.json');

handler(eventjson, null)
  .then(res => console.log('res', res))
  .catch(e => console.log('error', e));
