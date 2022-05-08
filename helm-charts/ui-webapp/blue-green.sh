#!/bin/bash

currentSlot=$(helm get values --all ui | python3 -c 'import sys,yaml; yml = yaml.safe_load(sys.stdin); print(yml["productionSlot"]);')

if [ $currentSlot == "blue" ]; then
  newSlot=green
elif [ $currentSlot == "green" ]; then
  newSlot=blue
fi

newAppVersion=$(helm get values --all ui | sed -e "s/^$newSlot:/current:/" | python3 -c 'import sys,yaml; yml = yaml.safe_load(sys.stdin); print(yml["current"]["appVersion"]);')
newAppVersion=$1

echo "Start to deploy on slot: $newSlot with version: $newAppVersion"

if [ $newSlot == "blue" ]; then
  helm upgrade ui . --set blue.enabled=true --set green.enabled=false --set blue.timestamp="$(date '+%Y-%m-%d %H:%M:%S')" --set image.tag=${newAppVersion} --set blue.appVersion=$newAppVersion --reuse-values --debug
  kubectl rollout status deployments/ui-ui-webapp-blue
  sleep 2
  helm upgrade ui . --set productionSlot=blue --reuse-values --debug
elif [ $newSlot == "green" ]; then
  helm upgrade ui . --set green.enabled=true --set blue.enabled=false --set green.timestamp="$(date '+%Y-%m-%d %H:%M:%S')" --set image.tag=${newAppVersion} --set green.appVersion=$new$AppVersion --reuse-values --debug
  kubectl rollout status deployments/ui-ui-webapp-green
  sleep 2
  helm upgrade ui . --set productionSlot=green --reuse-values --debug
fi
