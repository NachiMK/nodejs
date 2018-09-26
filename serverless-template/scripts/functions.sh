#!/bin/bash
. ./scripts/colors.sh
. ./scripts/config.sh

infoMessage() {
  echo -e "$GREEN$1$NONE"

}
processMessage() {
  echo -e "$CYAN$1$NONE"
}
workingMessage() {
  echo -e "$ORANGE$1$NONE"
}

gitUsername() {
  # Get GIT username
  echo $(git config user.name)
}

gitBranch() {
  # Get GIT username
  echo $(git rev-parse --symbolic-full-name --abbrev-ref HEAD)
}

slack() {
  if [ -z "$2" ]; then
    echo Not enough arguments sent for slack
    exit
  fi

  workingMessage "\nSending slack to #$1..."
  curl -X POST --data-urlencode 'payload={"channel": "#'"$1"'", "username": "Sir Service", "text": "'"$2"'"}' $SLACK_HOOK
  echo " 👌"
}

slackTestMessage() {
  if [ -z "$1" ]; then
    echo Not enough arguments sent for slack
    exit
  fi

  curl -X POST --data-urlencode 'payload={"channel": "#eng-services", "username": "Testy McTestface", "icon_url": "https://s3.amazonaws.com/dev-slack-images/all-the-things-face.jpg", "text": "'"$1"'"}' $SLACK_HOOK 
  echo " 👌"
}


