#!/bin/bash
. ./devops/functions.sh

# Get GIT username
USERNAME=$(git config user.name)
infoMessage "Hey ${USERNAME}, let's do a release!"

git checkout develop
git pull origin develop

npm version $TYPE -m "release/%s: bump $TYPE" --no-verify
# tag master
VERSION=$(cat package.json \
	| grep version \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[\ ",]//g')

# Checkout
processMessage "Checking out release branch..."
workingMessage "git checkout -b release/$VERSION\n"
git checkout -b release/$VERSION


# Pushing 
processMessage "Pushing out release branch..."
workingMessage "git push origin release/$VERSION --tags --no-verify\n"
git push origin release/$VERSION --tags --no-verify


# Create pull requests
processMessage "Creating pull requests...\n"
RELEASE_NAME=release/$VERSION REPO=$APP_NAME node ./node_modules/@hixme/pull-request-docs/lib/release.js


# Reset
processMessage "Checking out develop branch..."
workingMessage "git checkout develop\n"
git checkout develop

sleep 3
processMessage "Resetting develop branch with latest..."
workingMessage "git reset --hard origin/develop\n"
git reset --hard origin/develop

