#!/bin/bash

set -e

if [[ -n "${TERM}" ]] && [[ "${TERM}" != dumb ]]; then
    RED=$(tput setaf 1)
    export RED
    GREEN=$(tput setaf 2)
    export GREEN
    YELLOW=$(tput setaf 3)
    export YELLOW
    RESET=$(tput sgr0)
    export RESET
    BOLD=$(tput bold)
    export BOLD
fi

#
# utf-8 symbols
#
export CHECKMARK="\xE2\x9C\x94"
export BALLOT_X="\xE2\x9C\x97"
export WARNING_SIGN="\xE2\x9A\xA0"
export PLUS_SIGN="\x2B"
export REFRESH_SIGN="\xE2\x9F\xB3"

function status() {
  echo "STATUS:${1}"
}

if [ $# -ne 2 ]; then
  echo "Two devices must be provided as arguments"
  status "ERROR"
  exit 1
fi

DEV_FROM=$1
DEV_TO=$2

if [ ! -b "$DEV_FROM" ]; then
  echo "$DEV_FROM is not a valid block device"
  status "ERROR"
  exit 1
fi

if [ ! -b "$DEV_TO" ]; then
  echo "$DEV_TO is not a valid block device"
  status "ERROR"
  exit 1
fi

VOLUME_GROUP=$(pvs "$DEV_FROM" -o vg_name --no-headings || echo "")
# remove leading whitespace characters
VOLUME_GROUP=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' <<< "$VOLUME_GROUP")

if [ -z "$VOLUME_GROUP" ]; then
  echo "${GREEN}${BOLD}No volume group found on $DEV_FROM. Nothing to be done, exiting.${RESET}"
  status "DONE"
  exit 0
fi

DST_VOLUME_GROUP=$(pvs "$DEV_TO" -o vg_name --no-headings || echo "")
# remove leading whitespace characters
DST_VOLUME_GROUP=$(sed 's/^[[:space:]]*//;s/[[:space:]]*$//' <<< "$DST_VOLUME_GROUP")

if [ -z "$DST_VOLUME_GROUP" ]; then
  echo "Found volume group $VOLUME_GROUP on source device $DEV_FROM"

  if lvs -a -o+devices | grep -q "pvmove"; then
    echo "${YELLOW}${BOLD}Another pvmove operation is in progress, please wait for that job to finish and retrigger action encrypt_aws_disks.${RESET}"
    status "WAITING"
    exit
  fi

  echo "Extending volume group $VOLUME_GROUP by device $DEV_TO"

  vgextend "$VOLUME_GROUP" "$DEV_TO"

  echo "${YELLOW}${BOLD}Moving data from source device $DEV_FROM to target device $DEV_TO in background. Please execute action encrypt_aws_disks regularly to check the progress.${RESET}"

  pvmove -b "$DEV_FROM" "$DEV_TO"

  status "PROCESSING"

  exit
fi

if [ "$VOLUME_GROUP" == "$DST_VOLUME_GROUP" ]; then
  echo "Volume group ${VOLUME_GROUP} was already extended by ${DEV_TO}"
  if ! lvs -a -o+devices --noheadings | grep -q "${DEV_FROM}"; then
    echo "${DEV_FROM} is no longer used by any logical volume. Removing ${DEV_FROM} from volume group ${VOLUME_GROUP}"
    vgreduce "${VOLUME_GROUP}" "${DEV_FROM}"
    echo "${GREEN}${BOLD}Disk migration from ${DEV_FROM} to ${DEV_TO} completed.${RESET}"
    status "DONE"
    exit
  else
    PROGRESS=$(lvs -a --separator ';' -o+devices | grep "${VOLUME_GROUP}" | grep "\[pvmove" | cut --delimiter=';' --fields=11)
    echo "${YELLOW}${BOLD}Disk migration is still in progress @ ${PROGRESS}%.${RESET}"
    status "PROCESSING"
    exit
  fi
else
 echo "${RED}${BOLD}Volume group ${DST_VOLUME_GROUP} on destination device ${DEV_TO} does not match volume group ${VOLUME_GROUP} on source device ${DEV_FROM}. Aborting.${RESET}"
 status "ERROR"
 exit 1
fi


