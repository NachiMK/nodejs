#!/bin/bash
stage="$1"
dropFunctions="$2"

if [ -z "${stage}" ]; then 
    stagename='dev'
else 
    stagename=${stage}
fi

if [ -z "${dropFunctions}" ]; then 
    deleteFlag="false"
fi

if [ "${dropFunctions}" != "true" ]; then 
    deleteFlag="false"
else
    deleteFlag=${dropFunctions}
fi

echo "Enter psql password for ${stage}:"
read password
export PGPASSWORD=$password

echo "Deploying to stage:"$stagename
echo "Drop Functions:"$deleteFlag

if [ "${deleteFlag}" = "true" ]; then 
    echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c DROP FUNCTION IF EXISTS udf_create_plan_av_stage_table(varchar);"
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "DROP FUNCTION IF EXISTS udf_create_plan_av_stage_table(varchar);"

    echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c DROP FUNCTION IF EXISTS udf_clean_stage_plan_av();"
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "DROP FUNCTION IF EXISTS udf_clean_stage_plan_av();"

    echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c DROP FUNCTION IF EXISTS udf_check_plan_av_upload();"
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "DROP FUNCTION IF EXISTS udf_check_plan_av_upload();"

    echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c DROP FUNCTION IF EXISTS udf_update_plan_av_batchname(varchar(255));"
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "DROP FUNCTION IF EXISTS udf_update_plan_av_batchname(varchar(255));"
fi

for filename in *.sql; do
    [ -e "$filename" ] || continue
    echo "Deploying File:" $filename
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -f "$filename"
done

export PGPASSWORD=''