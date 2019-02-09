tableName=$1
stageinput=$2

ORANGE="\033[0;33m"
NONE="\033[0m"

DATE=$(date -u +%m%d%Y_%H%M%S)
outfile="Upload_${tableName}_${DATE}.log"

echo "Dynamo Table Name: ${tableName}"
echo "Stage: ${stageinput}"
echo "Outfile: ${outfile}"

if [ -z "${tableName}" ]; then 
    echo -e "${ORANGE}First Parameter, Dynamo Table Name is required${NONE}"
    echo -e "${ORANGE}Usage ./invoke-json-to-psql client-price-points int${NONE}"
    exit 1
fi

if [ -z "${stageinput}" ]; then 
    stage='dev'
else
    stage=${stageinput}
fi

s3bucket="${stage}-dev-data"
payload="{
  \"TableName\": \"${tableName}\"
}"

echo "Invoking Lambda..."
echo $(aws lambda invoke --function-name ods-service-${stage}-json-to-psql --payload "${payload}" "${outfile}")

echo "Lambda Results:"
echo $(less -FX ${outfile})
