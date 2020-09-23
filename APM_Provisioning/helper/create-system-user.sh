#!/usr/bin/env bash

#
# This program will create the Dynatrace OS user if it not exists.
#

set -e

DYNATRACE_GID=44445
DYNATRACE_UID=44445
DYNATRACE_GROUP=dynatrace
DYNATRACE_USER=dynatrace

DYNATRACE_SUDOERS_FILE=/etc/sudoers.d/dynatrace

if id -u $DYNATRACE_USER && [ "$DYNATRACE_GROUP" = "$( id -gn $DYNATRACE_USER )" ]; then
    echo "User $DYNATRACE_USER:$DYNATRACE_GROUP already exists"
else
    sudo groupadd -g ${DYNATRACE_GID} ${DYNATRACE_GROUP}
    echo "Group ${DYNATRACE_GROUP} created successfully"
    sudo useradd -r -s '/bin/bash' -g $DYNATRACE_GROUP -u $DYNATRACE_UID $DYNATRACE_USER
    echo "User ${DYNATRACE_USER}:${DYNATRACE_GROUP} created successfully"

    # make sure that the dynatrace user has sudo rights on /opt/dtrun/dtrun
    # to do so we place a file called dynatrace in /etc/sudoers.d/
    if [ ! -f $DYNATRACE_SUDOERS_FILE ]; then
        echo "Sudoers file does not exist! Creating it to allow sudo rights on /opt/dtrun/dtrun"
        echo -en 'Defaults:dynatrace !requiretty\nDefaults:dynatrace !env_reset\ndynatrace ALL=(root:root) NOPASSWD:/opt/dtrun/dtrun\n' | sudo tee -a $DYNATRACE_SUDOERS_FILE
    else
        echo "Sudoers file already exists at $DYNATRACE_SUDOERS_FILE"
    fi

fi