#!/bin/bash
# Continuous delivery slack
. ./devops/config.sh
. ./devops/functions.sh

# Get GIT username
if [ ${#USERNAME} -eq 0 ]; then
  USERNAME=$(gitUsername)
fi

if [ $BITBUCKET_BRANCH = develop ]; then
  MESSAGE="$APP_NAME/int: deployed with branch \`$BITBUCKET_BRANCH\` by $USERNAME."
  slack $SLACK_SERVICE_CHANNEL "$MESSAGE"
  slack $SLACK_RELEASE_CHANNEL "$MESSAGE"
elif [ $BITBUCKET_BRANCH = master ]; then
  VERSION=$(getPackageVersion)
  MESSAGE="<!channel> $APP_NAME/prod: deployed version \`$VERSION\` with branch \`$BITBUCKET_BRANCH\` by $USERNAME."
  slack $SLACK_SERVICE_CHANNEL "$MESSAGE"
  slack $SLACK_RELEASE_CHANNEL "$MESSAGE"
fi
