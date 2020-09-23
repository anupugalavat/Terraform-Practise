#!/bin/bash

# sudologs.sh rsync sudo-io logs to remote server

#Constants

SUDOLOG=/var/log/sudo-io
TYPE="SUDOERS"
LOCK_FILE=/var/run/sudologs.lock
LOCK_OBTAINED=0

#Functions

#display usage and exit
help() {
cat << END
Usage :
        sudologs -s [SERVER] -p [PORT] -d [DESTINATION] [-l [LOGPATH]] [-t [TYPE]]
        OPTION          DESCRIPTION
        ----------------------------------
        -h                    Help
        -s [SERVER]           Rsync server
        -p [PORT]             Port of the Rsync server
        -d [DEST]             Rsync destination
        -l [LOGPATH]          Path to sudo logs. Defaults to ${SUDOLOG}
        -t [TYPE]             Tool for replay logs SUDOERS or SUDOSH.
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
  if [[ -z $1 ]]
    then
      die 1 "Missing parameter"
   fi
}

#make lock files
do_lock() {
  if [ ! -e $LOCK_FILE ]; then
    #obtain lock
    echo "$CURRENT_TIMESTAMP" > "$LOCK_FILE"
  else
    #lock already exists
    last_timestamp=$(cat $LOCK_FILE)
    difference=$((CURRENT_TIMESTAMP - last_timestamp))
    if [ $difference -gt 1200 ]; then
      #refresh the lock
	  echo "$CURRENT_TIMESTAMP" > "$LOCK_FILE"
    else
      die 2 "Sudologs is already running"
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

group_files() {
  cd "$SUDOLOG" > /dev/null 2>&1 || die 3 "Cannot find directory ${SUDOLOG}"
  SCRIPT_FILES=$(find ./* -maxdepth 0 -type f ! -path . | grep "script" )
  [[ -z $SCRIPT_FILES ]] && die 0 "There are no appropriate SUDOSH files"
  for filename in $SCRIPT_FILES; do
    LANDSCAPE=$(echo "$DEST" | tr '[:upper:]' '[:lower:]')
    new_dir_name=${LANDSCAPE}-${HOSTNAME}-${filename/"-script-"/"-"}
    mkdir "$new_dir_name"
    cp "$filename" "$new_dir_name"
    cp "${filename/"script"/"time"}" "$new_dir_name"
  done
}

clear_unused_files() {
  cd "$SUDOLOG" > /dev/null 2>&1 || die 3 "Cannot find directory ${SUDOLOG}"
  SCRIPT_FILES=$(find ./* -maxdepth 0 -type f ! -path . )
  [[ -z $SCRIPT_FILES ]] && die 0 "There are no appropriate SUDOSH files"
  for filename in $SCRIPT_FILES; do
    lsof | grep "$SUDOLOG"/"$filename"
    exit_code=$?
    
    #delete file if not used by any process
    if [ $exit_code != 0 ]; then
      echo "Removing unused file: ${filename}"
      rm  "$filename"
    fi
  done
}

#main
while getopts "s:d:p:l:t:h:" OPT
do
        case $OPT in
        s) SERVER="$OPTARG" ;;
        p) PORT="$OPTARG" ;;
        d) DEST="$OPTARG" ;;
        l) SUDOLOG="$OPTARG" ;;
        t) TYPE="$OPTARG" ;;
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
TYPE=$(echo "$TYPE" | tr '[:lower:]' '[:upper:]')
if [[ "${TYPE}" =~ "SUDOSH" ]]; then
  SUDOLOG=/var/log/sudosh
  #group *-script-* and *-time-* files into separate folders with prefix DEST-HOSTNAME-
  group_files
  #clear the old files
  clear_unused_files
fi

#get content
cd $SUDOLOG > /dev/null 2>&1 || die 3 "Cannot find directory ${SUDOLOG}"
SUDO_DIRS_ARRAY=$(find . -maxdepth 1 -type d ! -path .)

# Check if we found any directories to rsync. If not exit
if [[ -z "$SUDO_DIRS_ARRAY" ]]; then
  die 0 "No files to rsync"
fi

for SUDO_DIR in ${SUDO_DIRS_ARRAY}; do
  # Rsync each filder seperately and clean it afterwards
  rsync -arv --no-p --no-g --chmod=ugo=rwX "${SUDO_DIR}" rsync://"${SERVER}":"${PORT}"/aws_replay_logs/"$DEST" || die 4 "Cannot rsync"
  
  #clean rsynced directories if not used anymore
  lsof | grep "$SUDOLOG"/"${SUDO_DIR}"
  exit_code=$?
  
  #delete directory if not used by another process
  if [[ $exit_code != 0 ]]; then
    echo "Removing unused directory: ${SUDO_DIR}"
    rm -r "${SUDO_DIR}"
  fi
done


#release the file lock
release_lock