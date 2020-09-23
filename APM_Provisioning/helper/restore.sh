#!/bin/bash

set -e
set -o pipefail

ACTION=$1
PRIVATE_IPS=$2
IP_ID=$3
NODE_IP=$4  #10.190.0.10
SEED_IP=$5  #10.190.0.10
mapfile -t PRIVATE_IP_ARRAY < <(echo "${PRIVATE_IPS}" | sed 's/[][]//g' | tr ',' '\n')

initialize_variables() {
    # shellcheck disable=SC2010
    BACKUP_HASH=$(ls /dynatrace-backup-nfs/ | grep -v "lost+found")
    BACKUP_PATH="/dynatrace-backup-nfs/${BACKUP_HASH}"
    # shellcheck disable=SC2010
    mapfile -t nodes < <(ls "${BACKUP_PATH}" | grep node_)
    # shellcheck disable=SC2010
    local -r current_node=$(ls "${BACKUP_PATH}" | grep node_ | head -$((IP_ID+1)) | tail -1)

    CLUSTER_NODES=""    # 1:10.176.41.168, 3:10.176.41.169, 5:10.176.41.170
    for i in "${!nodes[@]}"; do
        node="${nodes[${i}]}"
        node_id=${node#*node_}

        if [[ "$current_node" == "$node" ]]; then
            CURRENT_NODE_ID=${node_id}
        fi
        CLUSTER_NODES="$CLUSTER_NODES${node_id}:${PRIVATE_IP_ARRAY[${i}]},"
    done
    CLUSTER_NODES=${CLUSTER_NODES%*,}
}

prepare_node_for_restore() {
    cp "${BACKUP_PATH}/node_${CURRENT_NODE_ID}/files/backup-00${CURRENT_NODE_ID}-dynatrace-managed-installer.sh"  "/tmp/dynatrace-managed-installer.sh"

    /tmp/dynatrace-managed-installer.sh --restore --cluster-ip "${NODE_IP}" --cluster-nodes "${CLUSTER_NODES}" --seed-ip "${SEED_IP}" --backup-file "${BACKUP_PATH}/node_${CURRENT_NODE_ID}/files/backup-00${CURRENT_NODE_ID}.tar"
    echo "Restore using backup-00${CURRENT_NODE_ID}.tar has finished"
}

start_services() {
    /opt/dynatrace-bin/launcher/firewall.sh start
    /opt/dynatrace-bin/launcher/cassandra.sh start
    /opt/dynatrace-bin/launcher/elasticsearch.sh start

    BACKUP_DIRECTORY="/dynatrace-backup-nfs"
    chown -R dynatrace:dynatrace "${BACKUP_DIRECTORY}"
}

check_services() {
    local -r cassandra_nodetool_info=$(/opt/dynatrace-bin/utils/cassandra-nodetool.sh status)
    local -r cassandra_status=$(echo "${cassandra_nodetool_info}" | grep "${NODE_IP}" | awk '{print $1}' | grep -E '^[U,D][N,L,J,M]$' | cut -c 1)
    if [[ ${cassandra_status#*Status=} != U ]]; then
        echo "Cassandra status is down. Aborting restore..."
        exit 1
    fi

    local -r cassandra_state=$(echo "${cassandra_nodetool_info}" | grep "${NODE_IP}" | awk '{print $1}' | grep -E '^[U,D][N,L,J,M]$' | cut -c 2)
    if [[ ${cassandra_state#*State=} != N ]]; then
        echo "Cassandra state is abnormal. Aborting restore..."
        exit 1
    fi

    sleep 60
    local -r elasticsearch_status=$(curl -s -N -XGET 'http://localhost:9200/_cluster/health?pretty' | jq -r '.status')
    if [[ ${elasticsearch_status} != green && ${elasticsearch_status} != yellow ]];then
        echo "Elasticsearch is not running properly. Aborting restore..."
        exit 1
    fi
}

recover_elasticsearch() {
    /opt/dynatrace-bin/utils/restore-elasticsearch-data.sh "${BACKUP_PATH}"
}

recover_cassandra() {
    /opt/dynatrace-bin/utils/restore-cassandra-data.sh "${BACKUP_PATH}/node_${CURRENT_NODE_ID}/files/backup-00${CURRENT_NODE_ID}.tar"

    local -r cassandra_nodetool_info=$(/opt/dynatrace-bin/utils/cassandra-nodetool.sh status)
    local -r cassandra_status=$(echo "${cassandra_nodetool_info}" | grep "${NODE_IP}" | awk '{print $1}' | grep -E '^[U,D][N,L,J,M]$' | cut -c 1)
    if [[ ${cassandra_status#*Status=} != U ]]; then
        echo "Cassandra status is down. Aborting restore..."
        exit 1
    fi

    local -r cassandra_state=$(echo "${cassandra_nodetool_info}" | grep "${NODE_IP}" | awk '{print $1}' | grep -E '^[U,D][N,L,J,M]$' | cut -c 2)
    if [[ ${cassandra_state#*State=} != N ]]; then
        echo "Cassandra state is abnormal. Aborting restore..."
        exit 1
    fi
}

start_dynatrace() {
    /opt/dynatrace-bin/utils/restore-cassandra-data.sh "${BACKUP_PATH}/node_${CURRENT_NODE_ID}/files/backup-00${CURRENT_NODE_ID}.tar"

    chown -R dynatrace:dynatrace "/dynatrace-longterm-data/datastore/log/server/"
    chown -R dynatrace:dynatrace "/opt/dynatrace-bin/server/"
    /opt/dynatrace-bin/launcher/dynatrace.sh start

    echo "Restore has successfully completed on node ${NODE_IP}"
}

initialize_variables
case "${ACTION}" in
    "prepare_node_for_restore")
        prepare_node_for_restore
        ;;
    "start_services")
        start_services
        ;;
    "check_services")
        check_services
        ;;
    "recover_elasticsearch")
        recover_elasticsearch
        ;;
    "recover_cassandra")
        recover_cassandra
        ;;
    "start_dynatrace")
        start_dynatrace
        ;;
    *)
        echo "No such action is available"
        exit 1
esac
