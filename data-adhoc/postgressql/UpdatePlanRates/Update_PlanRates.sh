batchname="$1"
dataFile="$2"
stage="$3"
DATE=`date -u +%Y%m%d`
csvDataFile="'${dataFile/.xlsx/.csv}'"
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

echo "Batchname:"$batch
echo "DataFile:"$dataFile
echo "Date:"$DATE
echo "CSV File:"$csvDataFile
echo "CSV After Update File:"$csvDataFileAU

echo "Enter psql password for ${stage}:"
read password

export PGPASSWORD=$password
#node ../convertExcelToCSV/index.js "$dataFile" true
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_create_planrates_stage_tables('$batch');"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "\copy public.stage_planrates_raw_"$batch"_"$DATE" from $csvDataFile WITH DELIMITER ',' null as '' CSV"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_clean_stage_planrates();"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_check_planrates_upload();"

if [ "${stagename}" != "prod" ]; then 
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_update_planrates('$batch');"
else
    echo "Apply Changes to PROD (Type YES to apply)?"
    read applytoprod

    if [ "${applytoprod}" = "YES" ]; then 
        echo "Applying in Prod..."    
        psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "SELECT udf_update_planrates('$batch');"
        psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "\copy (SELECT * FROM vw_planrates_updates) TO $csvDataFileAU WITH DELIMITER ',' null as '' CSV HEADER"
    else
        echo "Run below command if all is good:"
        echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c \"SELECT udf_update_planrates('$batch');\""
        echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c \"\copy (SELECT * FROM vw_plansrates_updates) TO $csvDataFileAU WITH DELIMITER ',' null as '' CSV HEADER\""
    fi
fi

export PGPASSWORD=''