#!/bin/bash

#Constants
DYNATRACEHOME=/opt/dynatrace-managed
LOCK_FILE=/var/run/dtlogs.lock
LOCK_OBTAINED=0

#Functions

#display usage and exit
help() {
cat << END
Usage :
        rsync-dynatrace-audit.sh -s [SERVER] -p [PORT] -d [DESTINATION] [-l [DYNATRACEHOME]]

        OPTION          DESCRIPTION
        ----------------------------------
        -h                    Help
        -s [SERVER]           Rsync server
        -p [PORT]             Port of the Rsync server
        -d [DEST]             Rsync destination
        -l [DYNATRACEHOME]    Path to Dyantrace Home folder. Defaults to ${DYNATRACEHOME}
        ----------------------------------
END
exit 10
}

die() {
  release_lock
  echo "$2"
  exit "$1"
}

#check required parameter and exit if absent
check_parameter() {
  if [[ -z "$1" ]]; then
      die 1 "Missing parameter"
  fi
}

#make lock files
do_lock() {
  if [ ! -e "$LOCK_FILE" ]; then
    #obtain lock
    echo "$CURRENT_TIMESTAMP" > "$LOCK_FILE"
  else
    #lock already exists
    last_timestamp=$(cat "$LOCK_FILE")
    difference=$((CURRENT_TIMESTAMP - last_timestamp))
    if [[ "$difference" -gt 1200 ]]; then
      #refresh the lock
	  echo "$CURRENT_TIMESTAMP" > "$LOCK_FILE"
    else
      die 2 "rsync-dynatrace-audit.sh is already running"
    fi
  fi
  LOCK_OBTAINED=1
}

#clear lock
release_lock() {
  if [ -e "$LOCK_FILE" ] && [ "$LOCK_OBTAINED" == 1 ]; then
    rm "$LOCK_FILE"
  fi
}
check_log_folder(){
    DYNATRACE_SERVER_LOG="$DYNATRACEHOME/server/log"
    if [ -d "$DYNATRACE_SERVER_LOG" ] ; then
        echo "Dynatrace Log Folder found: $DYNATRACE_SERVER_LOG"
    else
        die 3 "Dynatrace Log Folder not found!"
    fi
}

#main
while getopts "s:d:p:l:t:h:" OPT
do
        case $OPT in
        s) SERVER="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        d) DEST="$OPTARG" ;;
        l) DYNATRACEHOME="$OPTARG" ;;
        h) help ;;
        *) help ;;
        esac
done

#check parameters
check_parameter "$SERVER"
check_parameter "$PORT"
check_parameter "$DEST"

CURRENT_TIMESTAMP=$(date +%s)
CURRENT_DATE=$(date)
echo "Date: ${CURRENT_DATE}"

# clean in case of EXIT SIGHUP SIGINT SIGABRT
trap release_lock 0 1 2 3 6
#guard
do_lock

check_log_folder
DYNATRACE_SERVER_LOG="$DYNATRACEHOME/server/log"

# move to server log folder
cd "$DYNATRACE_SERVER_LOG" > /dev/null 2>&1 || die 3 "Cannot find directory ${DYNATRACE_SERVER_LOG}"
# make a copy of the audit log files to folder dt_audit_logs
mkdir -p "$DYNATRACE_SERVER_LOG"/dt_audit_logs
cp audit*.log ./dt_audit_logs

# Rsync each folder seperately
rsync -arv --no-p --no-g --chmod=ugo=rwX "$DYNATRACE_SERVER_LOG"/dt_audit_logs rsync://"${SERVER}":"${PORT}"/aws_replay_logs/"$DEST" || die 4 "Cannot rsync"

# remove the entries after syncing
rm -rf ./dt_audit_logs/*

#release the file lock
release_lock