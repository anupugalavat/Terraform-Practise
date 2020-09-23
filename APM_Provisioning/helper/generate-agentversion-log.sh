#!/usr/bin/env bash

readonly curDate=$(date -u "+%Y-%m-%d %H:%M:%S")
readonly versions="$(find /dynatrace-longterm-data/datastore/agents/ -maxdepth 2 -mindepth 2 -type d | sed -e 's/.*\/\(.*\)\/\(.*\)/{"version":"\1","type":"\2"}/g' | paste -s -d "," -)"

echo "$curDate UTC" '{"availableVersions":['"$versions"']}' >>/opt/dynatrace-bin/server/log/audit.agent.versions.0.0.log
