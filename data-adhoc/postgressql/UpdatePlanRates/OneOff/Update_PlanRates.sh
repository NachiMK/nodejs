batchname="$1"
dataFile="$2"
stage="$3"
date=`date -u +%Y%m%d`
csvDataFile="'${dataFile/.xlsx/.csv}'"

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
echo "Date:"$date
echo "CSV File:"$csvDataFile

#node ../convertExcelToCSV/index.js "$dataFile" true
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c "DROP TABLE IF EXISTS public.stage_planrates_$batch"_"$date;"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c 'DROP TABLE IF EXISTS public."PlanRates_'$batch'_'$date'_BAK";'
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -f "Update Plan Rates - Create table.sql"
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c "\copy public.stage_planrates_$batch"_"$date from $csvDataFile WITH DELIMITER ',' null as '' CSV"
#psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -f "Update Plan Rates.sql"

if [ "${stagename}" != "prod" ]; then 
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -f "Update Plan Rates.sql"
else
    echo "Run below command if all is good:"
    echo "psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -f \"Update Plan Rates.sql\""
fi

#psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c "SELECT udf_create_plan_av_stage_table('$batch');"
#psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c "\copy public.stage_plans_av_raw_"$batch"_"$DATE" from $csvDataFile WITH DELIMITER ',' null as '' CSV"
#psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c "SELECT udf_clean_stage_plan_av();"
#psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -c "SELECT udf_check_plan_av_upload();"

