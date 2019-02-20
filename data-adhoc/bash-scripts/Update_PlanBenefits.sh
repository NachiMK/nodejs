batchname="$1"
dataFile="$2"
stage="$3"
username="$4"
DATE=`date -u +%Y%m%d`
csvDataFile="'${dataFile/xlsx/csv}'"
csvDataFileAU="${csvDataFile/.csv/-after-update.csv}"

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

if [ -z "${username}" ]; then 
    user='root'
else 
    user=${username}
fi

echo "Batchname:"$batch
echo "DataFile:"$dataFile
echo "Stage":$stagename
echo "Date:"$DATE
echo "CSV File:"$csvDataFile
echo "CSV After update File:"$csvDataFileAU

echo "Enter psql password for ${stage}:"
read password
export PGPASSWORD=$password

node ../../../../build/lib/convertExcelToCSV/index.js "$dataFile" true
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_create_planbenefits_stage_table('$batch');"
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "\copy public.stage_planbenefits_"$batch"_"$DATE" from $csvDataFile WITH DELIMITER ',' null as '' CSV"
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_clean_stage_planbenefits();"
psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_check_planbenefits_upload();"

if [ "${stagename}" != "prod" ]; then 
    psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_update_planbenefits();"
fi

echo "Apply Changes to PROD (Type YES to apply)?"
read applytoprod

if [ "${applytoprod}" = "YES" ]; then 
    echo "Applying in Prod..."
    psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "SELECT udf_update_planbenefits();"
    psql -h rds.amazonaws.com -p 5432 -U ${user} -d plans_${stagename} -c "\copy (SELECT * FROM vw_planbenefits_updates) TO $csvDataFileAU WITH DELIMITER ',' null as '' CSV HEADER"
else
    echo "Run below command if all is good:"
    echo "psql -h rds.amazonaws.com -p 5432 -U ${user} -W -d plans_${stagename} -c \"SELECT udf_update_planbenefits();\""
    echo "psql -h rds.amazonaws.com -p 5432 -U ${user} -W -d plans_${stagename} -c \"\copy (SELECT * FROM vw_planbenefits_updates) TO $csvDataFileAU WITH DELIMITER ',' null as '' CSV HEADER\""
fi

export PGPASSWORD=''