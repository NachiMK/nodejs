batchname="$1"
dataFile="$2"
stage="$3"
deleteServiceAreaforIssuer="$4"
username="$5"
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

if [ -z "${username}" ]; then 
    user='root'
else 
    user=${username}
fi

echo "Batchname:"$batch
echo "DataFile:"$dataFile
echo "Date:"$DATE
echo "CSV File:"$csvDataFile
echo "Delete for Issuer:"$deleteFlag
echo "Username:"$username

echo "Enter psql password for ${stage}:"
read password
export PGPASSWORD=$password

node ../../../../build/lib/convertExcelToCSV/index.js "$dataFile" true
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_create_planservicearea_stage_table('$batch');"
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "\copy public.stage_planservicearea_"$batch"_"$DATE" from $csvDataFile WITH DELIMITER ',' null as '' CSV"
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_clean_stage_planserviceareas();"
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_check_planservicearea_upload();"

if [ "${stagename}" != "prod" ]; then 
    psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT public.udf_update_planserviceareas($deleteFlag);"
else
    echo "Apply Changes to PROD (Type YES to apply)?"
    read applytoprod
     if [ "${applytoprod}" = "YES" ]; then 
        echo "Applying in Prod..."    
        psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT public.udf_update_planserviceareas($deleteFlag);"
     else
        echo "Run below command if all is good:"
        echo "psql -h rds.amazonaws.com -p 5432 -U ${user} -W -d plans_${stagename} -c \"SELECT public.udf_update_planserviceareas($deleteFlag);\""
    fi
fi

export PGPASSWORD=''