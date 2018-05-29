stage="$1"
if [ -z "${stage}" ]; then 
    stagename='dev'
else 
    stagename=${stage}
fi

echo "Deploying to stage:"$stagename

psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_$stagename -f udf_create_planservicearea_stage_table.sql
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_$stagename -f udf_clean_stage_planservicearea.sql
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_$stagename -f udf_check_planservicearea_upload.sql
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_$stagename -f udf_update_planservicearea.sql
