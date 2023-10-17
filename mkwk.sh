#!/usr/bin/env bash
#
# This scripts creates the required actions files for Github Actions
#

DOCKERHUB_USER=${DOCKERHUB_USER}


# List all directories
directories=($(ls -d */ | sed 's#/##'))

# Push Alpine to the first
alpine_index=$(echo "${directories[@]}" | tr ' ' '\n' | grep -n "alpine" | cut -d ":" -f 1)
if [[ $alpine_index != 1 ]]; then
    tmp=${directories[0]}
    directories[0]=${directories[$alpine_index-1]}
    directories[$alpine_index-1]=$tmp
fi

minute="0"
hour="0"
day_of_month="*"
month="*"
day_of_week="1"

for (( i=0; i<${#directories[@]}; i++ )); do
  name=${directories[$i]}
  dest=.github/workflows/${name}.yaml
  conf=${name}/Earthfile
    
  [[ -f "$conf" ]] || continue
  [[ ":ci-prefect-devops:netshoot:" =~ .*":$name:".* ]] || continue


  echo "INFO: Creates: $dest"
  cat > $dest <<EOF
name: $DOCKERHUB_USER/${directories[$i]}

on:
  schedule:
    - cron: $minute $hour $day_of_month $month $day_of_week
  workflow_call:
  workflow_dispatch:
    inputs:
      trigger:
        description: Manually trigger
        required: true
        type: choice
        options:
          - build

jobs:
  ${directories[$i]}:
    uses: ./.github/workflows/.earthly.yaml
    secrets: inherit
    with:
      build-dir: ${directories[$i]}
EOF

    hour=$((hour + 1))
    if [ $hour -eq 24 ]; then
        hour=0
        day_of_week=$((day_of_week + 1))
        if [ $day_of_week -eq 8 ]; then
            day_of_week=1
        fi
    fi

done

