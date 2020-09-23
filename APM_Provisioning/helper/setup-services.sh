#!/usr/bin/env bash

# This script reconfigures dynatrace services on a VM, e.g. after VM recreation.
# Attention: The oneagent process is currently not restored (because it is not used on this VMs).

set -e

# shellcheck disable=SC1090
source "$IAC_PRODUCT_DIR/helper/commons.sh"

readonly DYNATRACE_BINARIES_DIR=$(fromContext .context.product_config.dynatrace_binaries_dir)

createInitdEntries() {
    sudo ln -sf "${DYNATRACE_BINARIES_DIR}"/services/cassandra.sh /etc/init.d/dynatrace-cassandra
    sudo ln -sf "${DYNATRACE_BINARIES_DIR}"/services/elasticsearch.sh /etc/init.d/dynatrace-elasticsearch
    sudo ln -sf "${DYNATRACE_BINARIES_DIR}"/services/failover.sh /etc/init.d/dynatrace-failover
    sudo ln -sf "${DYNATRACE_BINARIES_DIR}"/services/firewall.sh /etc/init.d/dynatrace-firewall
    sudo ln -sf "${DYNATRACE_BINARIES_DIR}"/services/security-gateway.sh /etc/init.d/dynatrace-security-gateway
    sudo ln -sf "${DYNATRACE_BINARIES_DIR}"/services/server.sh /etc/init.d/dynatrace-server
}

maintainRunLevels() {
    sudo update-rc.d dynatrace-firewall defaults 93
    sudo update-rc.d dynatrace-cassandra defaults 94
    sudo update-rc.d dynatrace-elasticsearch defaults 95
    sudo update-rc.d dynatrace-server defaults 96
    sudo update-rc.d dynatrace-security-gateway defaults 97
    sudo update-rc.d dynatrace-failover defaults 98
}

startServices() {
    sudo service dynatrace-cassandra start
    sudo service dynatrace-elasticsearch start
    sudo service dynatrace-failover start
    sudo service dynatrace-firewall start
    sudo service dynatrace-security-gateway start
    sudo service dynatrace-server start
}

# main
# shellcheck disable=SC1091
. /opt/terraform/create-system-user.sh
createInitdEntries
maintainRunLevels
startServices
