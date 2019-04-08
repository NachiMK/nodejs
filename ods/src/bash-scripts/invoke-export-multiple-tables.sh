commaSeparatedTableNames=$1
stageinput=$2

ORANGE="\033[0;33m"
NONE="\033[0m"

DATE=$(date -u +%m%d%Y_%H%M%S)
outfile="multipletable_Export_${DATE}.log"

echo "Dynamo Tables to export: ${commaSeparatedTableNames}"
echo "Stage: ${stageinput}"
echo "Outfile: ${outfile}"

if [ -z "${commaSeparatedTableNames}" ]; then 
    echo -e "${ORANGE}First Parameter, Dynamo Table Names separated by comma is required${NONE}"
    echo -e "${ORANGE}Usage ./invoke-export-multiple-tables client-price-points,clients,benefits dev${NONE}"
    exit 1
fi

if [ -z "${stageinput}" ]; then 
    stage='dev'
else
    stage=${stageinput}
fi

tableNames="\"${stage}-${commaSeparatedTableNames//[,]/\",\"$stage-}\""

payload="{
    \"Tables\": [
        ${tableNames}
    ],
    \"LogLevel\": \"warn\",
    \"RowsPerFile\": 250,
    \"RecursionCount\": 0,
    \"MaxRecursion\": 750,
    \"ScanLimit\": 10000
}"

echo "Invoking Lambda..."
echo "payload... ${payload}"
echo $(aws lambda invoke --function-name ods-service-${stage}-export-mulitple-tables --payload "${payload}" "${outfile}")

echo "Lambda Results:"
echo $(less -FX ${outfile})

# # TABLES 1 TO 5
# ./src/bash-scripts/invoke-export-multiple-tables.sh benefit-change-events,benefits,bundle-event-offers,bundle-event-offers-log,bundle-events prod
# # TABLES 6 TO 10
# ./src/bash-scripts/invoke-export-multiple-tables.sh carrier-messages,client-benefits,client-census,client-price-points,clients prod
# # TABLES 11 TO 15
# ./src/bash-scripts/invoke-export-multiple-tables.sh enrollment-events,enrollment-questions,enrollment-responses,enrollments,locations prod
# # TABLES 16 TO 20
# ./src/bash-scripts/invoke-export-multiple-tables.sh modeling-census,modeling-configuration,modeling-group-plans,modeling-price-points,modeling-scenarios prod
# # TABLES 21 TO 25
# ./src/bash-scripts/invoke-export-multiple-tables.sh modeling-validation,models,notes,persons,platform-authorization-events prod
# # TABLES 26 TO 30
# ./src/bash-scripts/invoke-export-multiple-tables.sh prospect-census-models,prospect-census-profiles,prospects,tags,waived-benefits prod
