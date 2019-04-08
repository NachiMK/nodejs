commaSeparatedTableNames=$1
stageinput=$2

ORANGE="\033[0;33m"
NONE="\033[0m"

DATE=$(date -u +%m%d%Y_%H%M%S)
outfile="SchematoS3_Export_${DATE}.log"

echo "Dynamo Tables to export: ${commaSeparatedTableNames}"
echo "Stage: ${stageinput}"
echo "Outfile: ${outfile}"

if [ -z "${commaSeparatedTableNames}" ]; then 
    echo -e "${ORANGE}First Parameter, Dynamo Table Names separated by comma is required${NONE}"
    echo -e "${ORANGE}Usage ./invoke-save-schema-to-s3 client-price-points,clients,benefits dev${NONE}"
    exit 1
fi

if [ -z "${stageinput}" ]; then 
    stage='dev'
else
    stage=${stageinput}
fi

tableNames="\"${commaSeparatedTableNames}\""

payload="{
  \"RefreshAll\": false,
  \"RefreshTableList\": ${tableNames}
}"

echo "Invoking Lambda..."
echo "payload... ${payload}"
echo $(aws lambda invoke --function-name ods-service-${stage}-dba-save-schema-to-s3 --payload "${payload}" "${outfile}")

echo "Lambda Results:"
echo $(less -FX ${outfile})

# Testing
# ./src/bash-scripts/invoke-save-schema-to-s3.sh modeling-census,modeling-price-points prod
