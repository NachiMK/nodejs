#!/bin/bash
stage="$1"
hosttodeploy="$2"
reset="$3"
createdb="$4"

if [ -z "${stage}" ]; then 
    stagename='dev'
else 
    stagename=${stage}
fi
echo "Params:"
echo "First Param: stage (can be dev, int, or prod):"${stage}
echo "Second Param: Set to rds/rds2 if you want to deploy to auror instance or else localhost or empty string:"${hosttodeploy}
echo "Third Param: Set to ResetData:TRUE if you want to drop all tables and recreate it:"${reset}
echo "Fourth Param: Set to CreateDB:TRUE if you want to drop existing DB and recreate it:"${createdb}

if [ -z "${reset}" ]; then 
    resetdata='no'
else 
    resetdata=${reset}
fi

if [ -z "${createdb}" ]; then 
    create='No'
else 
    create=${createdb}
fi

if [ -z "${hosttodeploy}" ]; then 
    dbhostname='localhost'
else 
    dbhostname=${hosttodeploy}
fi

if [ "${dbhostname}" = "rds" ]; then 
    dbhostname='-h primary-01.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root'
    echo "Enter psql password for RDS Server ${stage}:"
    read password
    export PGPASSWORD=$password
elif [ "${dbhostname}" = "rds2" ]; then 
    dbhostname='-h datalake-try.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U hixme_root'
    echo "Enter psql password for RDS Server ${stage}:"
    read password
    export PGPASSWORD=$password
else
    dbhostname='-h localhost -p 5432'
fi

echo "Stage:"$stage
echo "Reset:"$resetdata
echo "Create:"$create
echo "HostName: (Type rds if deploying to Aurora)"$dbhostname

if [ "${create}" = "CreateDB:TRUE" ]; then 
    echo "Creating Database:odsarchive_${stagename}"
    echo "Create:"$create
    psql ${dbhostname} -d postgres -c "DROP DATABASE IF EXISTS odsarchive_${stagename};"
    psql ${dbhostname} -d postgres -c "CREATE DATABASE odsarchive_${stagename} WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';"
    psql ${dbhostname} -d odsarchive_${stagename} -c "CREATE SCHEMA IF NOT EXISTS arch;"
    psql ${dbhostname} -d odsarchive_${stagename} -c "CREATE EXTENSION tablefunc;"
    psql ${dbhostname} -d odsarchive_${stagename} -c "CREATE EXTENSION ""uuid-ossp"";"
    
    resetdata="ResetData:TRUE"

    for filename in Tables/*.sql; do
        [ -e "$filename" ] || continue
        echo "Deploying Table:" $filename
        psql ${dbhostname} -d odsarchive_${stagename} -f "$filename"
    done
else
    echo "Not Creating DB. To Create send param CreateDB:TRUE"
fi

if [ "${resetdata}" = "ResetData:TRUE" ]; then 
    for filename in Data/*.sql; do
        [ -e "$filename" ] || continue
        echo "Deploying Data:" $filename
        psql ${dbhostname} -d odsarchive_${stagename} -f "$filename"
    done
else
    echo "Not Resetting Data. To Reset send param ResetData:TRUE"
fi

for filename in Types/*.sql; do
    echo "Deploying Type:" $filename
    psql ${dbhostname} -d odsarchive_${stagename} -f "$filename"
done

for filename in Functions/*.sql; do
    echo "Deploying Function:" $filename
    psql ${dbhostname} -d odsarchive_${stagename} -f "$filename"
done

for filename in Views/*.sql; do
    [ -e "$filename" ] || continue
    echo "Deploying View:" $filename
    psql ${dbhostname} -d odsarchive_${stagename} -f "$filename"
done

export PGPASSWORD=''