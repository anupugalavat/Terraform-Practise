#!/usr/bin/env bash

set -e

write_deploy_info_to_state() {
  STATE_SUB_DIR="$1"
  if [[ -z "$STATE_SUB_DIR" ]]; then
    echo -e "Error: parameter for STATE_DIR is missing.\nUsage: write_deploy_info_to_state STATE_DIR.\n"
    exit 1
  fi

  mkdir -p "${IAC_DEPLOYMENT_STATE_DIR}/$STATE_SUB_DIR"
  pushd "$IAC_DEPLOYMENT_GEN_DIR" > /dev/null

    cat > "${IAC_DEPLOYMENT_STATE_DIR}/$STATE_SUB_DIR/deploy_info.yml" <<EOF
---
  landscape_commit_id: $(git log -1 --pretty=format:%H)"
EOF

  popd > /dev/null
}