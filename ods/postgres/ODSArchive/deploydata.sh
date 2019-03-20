#!/bin/bash
while getopts ":drhe:s:u:c:" opt; do
  case $opt in
    e)
      echo "Stage (Environment) provided, Parameter: $OPTARG" >&2
      param_stage=$OPTARG
      ;;
    d)
      echo "dry run" >&2
      param_dryrun='-dry-run'
      ;;
    s)
      echo "Hostname (Server name) provided, Parameter: $OPTARG" >&2
      param_host=$OPTARG
      ;;
    u)
      echo "User to deploy provided, Parameter: $OPTARG" >&2
      param_deployUser=$OPTARG
      ;;
    r)
      echo "Reset Data provided" >&2
      param_resetData=$OPTARG
      ;;
    c)
      echo "Create Database provided" >&2
      param_createDB=$OPTARG
      ;;
    h)
      echo "Usage on how to run this script."
      echo "./deploydata.sh -e (Provide stage name) -d (for dry run) -s (Provide Postgres server name) -u (Provide Deploy user) -r (Set to Reset ALL data) -c (Set to DROP and CREATE database) -h help"
      exit 1
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ -z "${param_stage}" ]; then 
    stagename='dev'
else 
    stagename=${param_stage}
fi

if [ -z "${param_dryrun}" ]; then 
    dryrun=''
else 
    dryrun="-dry-run"
fi

if [ -z "${param_resetData}" ]; then 
    resetdb='no'
else 
    resetdb="ResetData:TRUE"
fi

if [ -z "${param_createDB}" ]; then 
    create='no'
elif [ "${param_createDB}" = "TRUE" ]; then
    create="CreateDB:TRUE"
else
    create='no'
fi

if [ -z "${param_deployUser}" ]; then 
    dbUserName='hixme_ods_root'
else 
    dbUserName=${param_deployUser}
fi

if [ -z "${param_host}" ]; then 
    dbhostname='localhost'
else 
    dbhostname=${param_host}
fi

echo "Params provided (or default assumed):"
echo "Stage (-e): Can be dev, int, or prod:${stagename}"
echo "Host Name (-s): Set to rds if you want to deploy to aurora instance or else localhost or empty string:${dbhostname}"
echo "Dry Run (-d): Set to -d if you want just see what scripts will be executed by this shell script:${dryrun}"
echo "Deplpy User (-u): Set to User name you want to use for this deployment.:${dbUserName}"
echo "Reset Data(-r): Set to -r if you want to reset data for all tables (dont do this in prod):${resetdb}"
echo "Drop & Create DB (-c): Set to -c TRUE if you want to DROP & CREATE the entire database (dont do this in prod):${create}"

new_deploy_role="ods_deploy_role_${stagename}"
new_deploy_user="ods_deploy_user_${stagename}"
app_role="odsarchive_app_role_${stagename}"
app_user="odsarchive_app_user_${stagename}"
db="odsarchive_${stagename}"

idxpw='1'
if [ "${stagename}" = "int" ]; then
    idxpw="2"
elif [ "${stagename}" = "prod" ]; then
    idxpw="4"
else
    idxpw='1'
fi

if [ "${dbhostname}" = "rds" ]; then 
    dbhostname='-h datalake.cwoqm2lwdsxk.us-west-2.rds.amazonaws.com -p 5432 -U '${dbUserName}
    if [ -z "${PGPASSWORD}" ]; then 
        echo "Enter psql password for user: ${dbUserName} to deploy in RDS Server ${stagename}:"
        read -s password
        export PGPASSWORD=$password
    else
        echo "Using PGPASSWORD Environment variable for User: ${dbUserName} Server: ${dbhostname}"
    fi
else
    dbhostname='-h localhost -p 5432'
fi

function deployFile {
    if [ "$dryrun" = "-dry-run" ]; then 
        echo "psql ${dbhostname} -d ${db} -f \"$1\""
    else
        echo 'Applying Script:' $1
        psql ${dbhostname} -d ${db} -f "$1"
    fi
}

function deployCmd {
    if [ "$dryrun" = "-dry-run" ]; then 
        echo "psql ${dbhostname} -d ${db} -c \"$1\""
    else
        echo 'Applying Script:' $1
        psql ${dbhostname} -d ${db} -c "$1"
    fi
}

function deployToPostgresCmd {
    if [ "$dryrun" = "-dry-run" ]; then 
        echo "psql ${dbhostname} -d postgres -c \"$1\""
    else
        echo 'Applying Script:' $1
        psql ${dbhostname} -d postgres -c "$1"
    fi
}

function grantPermissionToSchema {
    schema_permission='GRANT CONNECT ON DATABASE '${db}' TO '${2}';
    GRANT USAGE,CREATE ON SCHEMA '$1' to '${app_role}';
    ALTER DEFAULT PRIVILEGES FOR USER '${2}' IN SCHEMA '$1' GRANT SELECT,INSERT,UPDATE,DELETE ON TABLES TO '${2}';
    GRANT SELECT,INSERT,UPDATE,DELETE ON ALL TABLES IN SCHEMA '$1' TO '${2}';
    GRANT ALL PRIVILEGES ON ALL FUNCTIONS IN SCHEMA '$1' TO '${2}';
    GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA '$1' TO '${2}';
    GRANT '${2}' TO CURRENT_USER,'${new_deploy_role}' WITH ADMIN OPTION;
    GRANT '${app_user}' TO CURRENT_USER,'${new_deploy_role}' WITH ADMIN OPTION;'
    deployCmd "$schema_permission"
}

function createRoleUser {
    echo "Enter NEW password for user: ${2} in RDS, If not a user will be created with Password(${3}):"
    read read_pwd
    if [ -z "${read_pwd}" ]; then 
        deploy_user_pwd=${default_pwd}
    else
        deploy_user_pwd=${read_pwd}
    fi
    deployToPostgresCmd "CREATE ROLE ${1};"
    deployToPostgresCmd "CREATE USER ${2} WITH PASSWORD '${deploy_user_pwd}' in role ${1};"
    deployToPostgresCmd "GRANT ${1} TO CURRENT_USER WITH ADMIN OPTION;"
    deployToPostgresCmd "GRANT ${2} TO CURRENT_USER WITH ADMIN OPTION;"
}

if [ "${create}" = "CreateDB:TRUE" ]; then 
    echo "Dropping and Creating Database..." 
    deployToPostgresCmd "DROP DATABASE IF EXISTS ${db};"
    deployToPostgresCmd "CREATE DATABASE ${db} WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'en_US.UTF-8' LC_CTYPE = 'en_US.UTF-8';"
    deployToPostgresCmd "REVOKE CONNECT ON DATABASE ${db} FROM PUBLIC;"
    deployToPostgresCmd "REVOKE ALL ON ALL TABLES IN SCHEMA public FROM PUBLIC;"
  
    default_pwd="H!xme_0ds_deploy_${stagename}${idxpw}"
    createRoleUser "${new_deploy_role}" "${new_deploy_user}" "${default_pwd}"
    deployToPostgresCmd "GRANT ALL PRIVILEGES ON DATABASE ${db} to ${new_deploy_role};"

    default_pwd="H!xme_0ds_ah_${stagename}${idxpw}"
    createRoleUser "${app_role}" "${app_user}" "${default_pwd}"

    resetdb="ResetData:TRUE"

    for filename in PreDeployment/*.sql; do
       [ -e "$filename" ] || continue
       deployFile "$filename"
   done
   for filename in Tables/*.sql; do
       [ -e "$filename" ] || continue
       deployFile "$filename"
   done
    for filename in Triggers/*.sql; do
        [ -e "$filename" ] || continue
        deployFile "$filename"
    done
else
    echo "Not Creating DB. To Create send param CreateDB:TRUE"
fi

if [ "${resetdb}" = "ResetData:TRUE" ]; then 
    for filename in Data/*.sql; do
        [ -e "$filename" ] || continue
        deployFile $filename
    done
else
    echo "Not Resetting DB. To Reset send param ResetData:TRUE"
fi

for filename in Types/*.sql; do
    [ -e "$filename" ] || continue
    deployFile "$filename"
done

for filename in Views/*.sql; do
    [ -e "$filename" ] || continue
    deployFile "$filename"
done

for filename in Functions/*.sql; do
    [ -e "$filename" ] || continue
    deployFile "$filename"
done

for filename in PostDeployment/*.sql; do
    [ -e "$filename" ] || continue
    deployFile $filename
done

grantPermissionToSchema "arch" "${app_role}"

export PGPASSWORD=''