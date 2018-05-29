batchname="$1"
dataFile="$2"
stage="$3"
deleteServiceAreaforIssuer="$4"
DATE=`date -u +%Y%m%d`
csvDataFile="'${dataFile/xlsx/csv}'"

if [ -z "${batchname}" ]; then 
    batch=''
else 
    batch=${batchname}
fi

if [ -z "${stage}" ]; then 
    stagename='dev'
else 
    stagename=${stage}
fi

if [ -z "${deleteServiceAreaforIssuer}" ]; then 
    deleteFlag="false"
fi

if [ "${deleteServiceAreaforIssuer}" != "true"]; then 
    deleteFlag="false"
else
    deleteFlag=${deleteServiceAreaforIssuer}
fi

echo "Batchname:"$batch
echo "DataFile:"$dataFile
echo "Date:"$DATE
echo "CSV File:"$csvDataFile
echo "Delete for Issuer:"$deleteFlag

echo "Enter psql password for ${stage}:"
read password
export PGPASSWORD=$password

node ../convertExcelToCSV/index.js "$dataFile" true
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_create_planservicearea_stage_table('$batch');"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "\copy public.stage_planservicearea_"$batch"_"$DATE" from $csvDataFile WITH DELIMITER ',' null as '' CSV"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_clean_stage_planserviceareas();"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_check_planservicearea_upload();"

if [ "${stagename}" != "prod" ]; then 
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_update_planserviceareas($deleteFlag);"
else
    echo "Apply Changes to PROD (Type YES to apply)?"
    read applytoprod
     if [ "${applytoprod}" = "YES" ]; then 
        echo "Applying in Prod..."    
        psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_update_planserviceareas($deleteFlag);"
     else
        echo "Run below command if all is good:"
        echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c \"SELECT udf_update_planserviceareas($deleteFlag);\""
    fi
fi

export PGPASSWORD=''