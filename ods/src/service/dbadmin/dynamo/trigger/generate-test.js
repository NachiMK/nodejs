import {handler} from './index';

let eventjson = require('./event.json');
handler(eventjson, null)
.then(res => console.log('res', res))
.catch(e => console.log('error', e));
