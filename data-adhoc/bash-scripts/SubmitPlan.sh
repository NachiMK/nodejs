planID=$1
planyear=$2
stageinput=$3

DATE=$(date -u +%m%d%Y_%H%M%S)
outfile="LambdaOutFile_${DATE}.log"

echo "Plan ID: ${planID}"
echo "Plan Year: ${planYear}"
echo "Stage: ${stageinput}"
echo "Outfile: ${outfile}"

if [ -z "${planyear}" ]; then 
    plan_year='2019'
else
    plan_year=${planyear}
fi

if [ -z "${stageinput}" ]; then 
    stage='dev'
else
    stage=${stageinput}
fi

echo "Plan ID: ${planID}"
echo "Plan Year: ${plan_year}"
echo "Stage: ${stage}"

if [ -z "${planID}" ]; then 
    echo "Please enter Plan ID"
    echo "Usage ./SubmitPlan 7d1b2a3c-3cbd-4d8a-aee2-68dacd8c9a3d 2019 prod"
else 
    payload="{\"body\": { \"Year\": ${plan_year}, \"PlanID\": \"${planID}\" } }"
    echo "Count in Axene Input Summary before Submission:"
    echo $(aws s3 ls s3://bucket-name/input/ --summarize | rg Total)
    
    echo "Invoking Function:"
    echo "aws lambda invoke --function-name axene-service-${stage}-submit-plans --payload "${payload}" "${outfile}""
    echo $(aws lambda invoke --function-name axene-service-${stage}-submit-plans --payload "${payload}" "${outfile}")

    echo "Count in Axene Input Summary After Submission:"
    echo $(aws s3 ls s3://bucket-name/input/ --summarize | rg Total)
fi
