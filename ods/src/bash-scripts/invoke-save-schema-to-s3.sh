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

# ./src/bash-scripts/invoke-save-schema-to-s3.sh application-submission-workflows prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh benefit-change-events prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh benefits prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh bundle-event-offers-log prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh bundle-event-offers prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh bundle-events prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh carrier-messages prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh client-benefits prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh client-census prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh client-price-points prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh clients prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh enrollment-events prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh enrollment-questions prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh enrollment-responses prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh enrollments prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh locations prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh modeling-census prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh modeling-configuration prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh modeling-group-plans prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh modeling-price-points prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh modeling-scenarios prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh notes prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh payroll-deductions prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh persons prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh platform-authorization-events prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh prospect-census-models prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh prospect-census-profiles prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh prospects prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh tags prod &&
# ./src/bash-scripts/invoke-save-schema-to-s3.sh waived-benefits prod