batch=$1
csvFile=$2
stageinput=$3

ORANGE="\033[0;33m"
CYAN="\033[0;36m"
NONE="\033[0m"

DATE=$(date -u +%m%d%Y_%H%M%S)
outfile="Upload_${batch}_${DATE}.log"
dtToCheckAU=$(date -u +%Y%m%d)
afterUpdate="Report-PlansAndRates-${dtToCheckAU}"

echo "Batch Name: ${batch}"
echo "CSV File To Upload: ${csvFile}"
echo "Stage: ${stageinput}"
echo "Outfile: ${outfile}"

if [ -z "${batch}" ]; then 
    echo -e "${ORANGE}First Parameter, Batch Name is required${NONE}"
    echo -e "${ORANGE}Usage ./Upload_PlansAndRates Unique_BATCH_ID /Users/Nachi/FileName.csv prod${NONE}"
    exit 1
fi

if [ -z "${csvFile}" ]; then 
    echo -e "${ORANGE}Second Parameter, CSV File Name is required${NONE}"
    echo -e "${ORANGE}Usage ./Upload_PlansAndRates Unique_BATCH_ID /Users/Nachi/FileName.csv prod${NONE}"
    exit 2
fi

if [ -z "${stageinput}" ]; then 
    stage='dev'
else
    stage=${stageinput}
fi

csvFileName=$(basename -- "$csvFile")
s3bucket="${stage}-bucket-name"
s3BucketWithFolder="s3://${s3bucket}/sub-key-name/"
s3fullPath="${s3BucketWithFolder}${csvFileName}"
payload="{
  \"body\": {
    \"BatchName\": \"${batch}\",
    \"S3FilePath\": \"${s3fullPath}\",
    \"UploadOptions\": {
      \"FileType\": \"csv\",
      \"HasHeader\": \"TRUE\"
    }
  }
}"

echo "Uploading File..."
echo $(aws s3 cp ${csvFile} ${s3BucketWithFolder})

echo "Is the File in S3 after uplading?"
echo $(aws s3 ls ${s3fullPath} --summarize --human-readable | rg ${csvFileName})

echo -e "${CYAN}Proced with invoking Lambda? (Enter Y for Yes or any character to skip):${NONE}"
read runLambda

if [ "${runLambda}" = "Y" ]; then 
    echo "Invoking Lambda..."
    echo $(aws lambda invoke --function-name ${stage}name-of-lambda --payload "${payload}" "${outfile}")

    echo "Lambda Results:"
    echo $(less -FX ${outfile})

    echo "Input File in S3 after Submission:"
    echo $(aws s3 ls ${s3fullPath} --summarize --human-readable | rg ${csvFileName})
    echo "Error File in S3 after Submission (if any) for batch(${batch}):"
    echo $(aws s3 ls ${s3BucketWithFolder}${batch} --summarize --human-readable)
    echo "After Update File in S3 after Submission (if any) for Today(${afterUpdate}):"
    echo $(aws s3 ls ${s3BucketWithFolder}${afterUpdate} --summarize --human-readable)
    
else
    echo "Run below command if all is good:"
    echo "aws lambda invoke --function-name ${stage}name-of-lambda --payload "${payload}" "${outfile}""
fi
