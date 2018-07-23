
# cd ../../../../../
npm run build
clear
export odsloglevel=info
export STAGE=dev
export log_dbname=ODSLog
export DEV_ODSLOG_PG='postgres://odslog_user:H!xme_0ds_ah_dev1@localhost/odslog_dev'
export DEV_ODSCONFIG_PG='postgres://odsconfig_user:H!xme_0ds_ah_dev1@localhost/odsconfig_dev'
# odsloglevel=info STAGE=dev log_dbname=ODSLog DEV_ODSLOG_PG='postgres://odslog_user:H!xme_0ds_ah_dev1@localhost/odslog_dev' DEV_ODSCONFIG_PG='postgres://odsconfig_user:H!xme_0ds_ah_dev1@localhost/odsconfig_dev'
node lib/service/dbadmin/dynamo/schema/generate-test.js
# npm test -- -u -t="should create schema and returns success"
