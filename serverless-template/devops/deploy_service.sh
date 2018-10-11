#!/bin/bash
. ./devops/colors.sh
. ./devops/config.sh
. ./devops/functions.sh

if [ ${#STAGE} -eq 0 ] || ([[ $STAGE != 'int' ]] && [[ $STAGE != 'dev' ]] && [[ $STAGE != 'prod' ]]); then
  echo "Stage $STAGE not recognized
Available Stages:
  dev
  int
  prod"

  exit
fi

# Get GIT username
if [ ${#USERNAME} -eq 0 ]; then
  USERNAME=$(gitUsername)
fi
BRANCH=$(gitBranch)

# If this is not a bitbucket pipeline and we're deploying to prod
# Let's ask a question to make sure this is what we want to do
if [ -z "$BITBUCKET_BRANCH" ] && [ $STAGE = prod ]; then
  infoMessage "You are about to update production!"
  processMessage "Do you want to do this?(Yes/no)"

  read YESNO
  lowerYESNO=$(echo $YESNO | awk '{print tolower($0)}')

  if [ $lowerYESNO = 'yes' ] || [ $lowerYESNO = 'y' ]; then
    echo "👍 Thanks $USERNAME! Pushing to prod!"
  else
    exit 0
  fi
else
  infoMessage "👍  Good work $USERNAME! Thanks for testing.\n"
fi

workingMessage "Deploying  🚚\n"
processMessage "  Branch:       ${PURPLE}$BRANCH"
processMessage "  Stage:        ${PURPLE}$STAGE"

# Run build
workingMessage "\nBuilding   🔨"

if [ $STAGE = 'prod' ] || [ $STAGE = 'int' ]; then
  npm run build:min
else
  npm run build
fi

# Deploy serverless files
workingMessage "\nDeploying  🚀 \n"
./node_modules/serverless/bin/serverless deploy --aws-s3-accelerate --stage $STAGE --region $npm_package_config_region

# Post to slack
workingMessage "\nSlacking   💬\n"

# If not part of the bitbucket pipleline
# Slack some messagesd
if [ ${#BITBUCKET_BRANCH} -eq 0 ]; then
  MESSAGE="$APP_NAME/$STAGE updated: \`$BRANCH\` branch deployed by \`$USERNAME\`"
  slackTestMessage "$MESSAGE"

  # Slack release channel for Prod changes
  if [ $STAGE = 'prod' ] || [ $STAGE = 'int' ]; then
    slack $SLACK_RELEASE_CHANNEL "$MESSAGE"
  fi
fi

