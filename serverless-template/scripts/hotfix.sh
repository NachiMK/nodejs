#!/bin/bash
. ./scripts/functions.sh

# Get GIT username
USERNAME=$(git config user.name)
BRANCH=$(git rev-parse --abbrev-ref HEAD)
infoMessage "Hey ${USERNAME}, let's get this hotfix out!!"

npm version patch -m "$BRANCH: bump %s" --no-verify

# Pushing 
processMessage "Pushing out release branch..."
workingMessage "git push origin $BRANCH --tags --no-verify\n"
git push origin $BRANCH --tags --no-verify

# Create pull requests
processMessage "Creating pull requests...\n"
RELEASE_NAME=$BRANCH REPO=$APP_NAME node ./node_modules/@hixme/pull-request-docs/lib/release.js

