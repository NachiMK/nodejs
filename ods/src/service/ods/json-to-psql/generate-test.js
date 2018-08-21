import { JsonToPSQL } from '.';

const event = require('./event.json');

function TestJsonToPSQL() {
  try {
    console.log(`Event:${JSON.stringify(event, null, 2)}`);
    return JsonToPSQL(event);
  } catch (err) {
    console.log(err.message);
    console.log(JSON.stringify(err, null, 2));
  }
}

TestJsonToPSQL();

/*
npm run build\
 && Clear
 && odsloglevel=info\
 STAGE=dev\
 log_dbname=ODSLog\
 DEV_ODSLOG_PG='postgres://odslog_user:<Password>@localhost/odslog_dev'\
 DEV_ODSCONFIG_PG='postgres://odsconfig_user:<Password>@localhost/odsconfig_dev'\
 node lib/service/ods/json-to-psql/generate-test.js
*/
