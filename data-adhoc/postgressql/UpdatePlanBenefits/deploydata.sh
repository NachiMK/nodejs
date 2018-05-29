#!/bin/bash
stage="$1"

if [ -z "${stage}" ]; then 
    stagename='dev'
else 
    stagename=${stage}
fi

echo "Stage:"$stage


for filename in *.sql; do
    [ -e "$filename" ] || continue
    echo "Deploying File:" $filename
    psql -h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root -W -d plans_${stagename} -f "$filename"
done
