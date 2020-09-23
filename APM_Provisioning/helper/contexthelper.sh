#!/usr/bin/env bash
CONTEXT="$( yaml2json < "${1}" )"

fromJson()
{
  value=$(jq -r "$2" <<< "${1}")
  eval "$3=\$value"
  [[ "$value" = "null" ]] && { echo "${2} not found." >&2; return 1; }
  return 0
}

fromContext()
{
  fromJson "$CONTEXT" "$1" "$2"
}

tryFromJson()
{
  value=$(jq -r "$2" <<< "${1}")
  if [[ "$value" = "null" ]]; then
    value=""
  fi
  eval "$3=\$value"
  return 0
}

tryFromContext()
{
  tryFromJson "$CONTEXT" "$1" "$2"
}



fromContext ".context.imports.iaas_terraform.terraform_action_helper" TERRAFORM_ACTION_HELPER

export TERRAFORM_ACTION_HELPER

fromContext ".context.imports.lscrypt.lscrypt_execute" LSCRYPT_EXECUTE

export LSCRYPT_EXECUTE

# exports TF_VAR_<property> variables for each property in the output section
# of a given terraform state file.
# $1: path to terraform state file
exportStateOutputs()
{
  if [ ! -f "$1" ]; then
    echo "$1 is not a file."
    return 1
  fi
  local file="$1"
  local outputs=""

  fromJson "$(< "${file}")" ".modules[0].outputs" outputs

  for key in $( jq -r 'to_entries[] | .key' <<< "${outputs}" ); do
    value="$( jq -r ".${key}.value" <<< "${outputs}" )"
    # Custom change: export without eval in order to fix list exports
    export TF_VAR_"${key}"="${value}"
  done
}

exportNfsDiskId()
{
  if [ ! -f "$1" ]; then
    echo "$1 is not a file."
    return 1
  fi

  if [ -z "$2" ]; then
    echo "No IaaS Provider specified."
    return 1
  fi

  local file="$1"
  local iaas_provider="$2"
  local resources
  local disk_id=""

  fromJson "$(< "${file}")" ".modules[0].resources" resources

  case "${iaas_provider}" in
        "aws")
            disk_id=$(echo "${resources}" | jq -r 'with_entries(select(.key | match("aws_ebs_volume.dynatrace_backup_nfs_storage_enc";"i")))[].primary.id')
            ;;
        "azure")
            disk_id=$(echo "${resources}" | jq -r 'with_entries(select(.key | match("azurerm_virtual_machine.nfs-server";"i")))[].primary.attributes | with_entries(select(.key | match("storage_data_disk.0.managed_disk_id";"i")))[]')
            ;;
        *)
            echo "IaaS provider not supported"
            exit 1
  esac

  export NFS_DISK_ID="${disk_id}"
}

exportRestoreVmName()
{
  if [ ! -f "$1" ]; then
    echo "$1 is not a file."
    return 1
  fi

  if [ -z "$2" ]; then
    echo "No IaaS Provider specified."
    return 1
  fi

  local file="$1"
  local iaas_provider="$2"
  local resources
  local vm_name=""

  fromJson "$(< "${file}")" ".modules[0].resources" resources

  case "${iaas_provider}" in
        "gcp")
            vm_name=$(echo "${resources}" | jq -r 'first(with_entries(select(.key | match("google_compute_instance.dynatrace-server.";"i")))[].primary.id)')
            ;;
        "azure")
            vm_name=$(echo "${resources}" | jq -r 'first(with_entries(select(.key | match("azurerm_virtual_machine.dynatrace-server.";"i")))[].primary.attributes.name)')
            ;;
        "ali")
            vm_name=$(echo "${resources}" | jq -r 'first(with_entries(select(.key | match("alicloud_instance.dynatrace_instance.";"i")))[].primary.attributes.instance_name)')
            ;;
        *)
            echo "IaaS provider not supported"
            exit 1
  esac

  export RESTORE_VM_NAME="${vm_name}"
}