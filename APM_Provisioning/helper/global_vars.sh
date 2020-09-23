#!/usr/bin/env bash

__fromContext() {
  jq -r "$2" <(yaml2json < "$1")
}

# shellcheck disable=SC1090
source "$(__fromContext "$1" .context.imports.lscrypt.lscrypt_helper)"

readonly DYNATRACE_PRIVATE_KEY="$(get_key_file_location credentials/dynatrace.pem)"
