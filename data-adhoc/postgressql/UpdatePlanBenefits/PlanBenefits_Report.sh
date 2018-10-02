year="$1"
state="$2"
batchname="$3"
stage="$4"
DATE=`date -u +%Y%m%d`

if [ -z "${batchname}" ]; then 
    batch=''
else 
    batch=${batchname}
fi

csvReportFile="'/Users/Nachi/Documents/work/Projects/PlanBenefits/PlanBenefits_${year}_${state}_${batch}${DATE}.csv'"

if [ -z "${stage}" ]; then 
    stagename='prod'
else 
    stagename=${stage}
fi

echo "Year:"$year
echo "State:"$state
echo "Batch:"$batch
echo "Stage":$stagename
echo "CSV File:"$csvReportFile

echo "Enter psql password for ${stage}:"
read password
export PGPASSWORD=$password

echo "Generating Report in ..."
psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -d plans_${stagename} -c "\copy (SELECT * FROM udf_Report_PlanBenefits($year, '$state')) TO $csvReportFile WITH DELIMITER ',' null as '' CSV HEADER"

export PGPASSWORD=''