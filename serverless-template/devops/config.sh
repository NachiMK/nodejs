#!/bin/sh

APP_NAME=$(cat package.json \
  | grep name \
  | head -1 \
  | awk -F: '{ print $2 }' \
  | sed 's/[\ ",]//g')

SLACK_HOOK="https://hooks.slack.com/services/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"

SLACK_SERVICE_CHANNEL="eng-services"
SLACK_RELEASE_CHANNEL="releases-services"

