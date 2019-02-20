
# cd ../../../../../
npm run build
clear
export odsloglevel=info
export STAGE=int
export log_dbname=ODSLog
export INT_ODSLOG_PG='postgres://odslog_user:int_H!xme_0ds_ah@datalake.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com/odslog_int'
export INT_ODSCONFIG_PG='postgres://odsconfig_user:int_H!xme_0ds_ah@datalake.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com/odsconfig_int'
node lib/service/dbadmin/dynamo/schema/generate-test.js
