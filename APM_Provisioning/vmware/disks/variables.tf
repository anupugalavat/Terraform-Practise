# Vcenter provider information
variable "vcenter_ip" {
  type        = string
  description = "vcenter sever ip"
}

variable "vcenter_user_name" {
  type        = string
  description = "vcenter user name"
}

variable "vcenter_password" {
  type        = string
  description = "vcenter password"
}

# landscape details
variable "vsphere_datacenter" {
  type        = string
  description = "vsphere datacenter name"
}

variable "vsphere_datastore" {
  type        = list(string)
  description = "vsphere datastore name"
}

# number of disks to be created = number of dynatrace_instances
variable "dynatrace_instances" {
  type        = number
  description = "number of dynatrace instances"
}

#
# size of disks to be provsiosned.
# NOTE: ANY CHANGE IN DISK SIZE WILL RECREATE THE DISK, HENCE DATA WILL BE LOST
# https://github.com/hashicorp/terraform-provider-vsphere/issues/851
#

variable "dynatrace_opt_storage_volume_size" {
  type        = number
  description = "size of the dynatrace_opt_storage volume"
}

variable "dynatrace_transaction_data_volume_size" {
  type        = number
  description = "size of the dynatrace_transaction_data volume"
}

variable "dynatrace_long_term_Cassandra_volume_size" {
  type        = number
  description = "size of the dynatrace_long_term_Cassandra volume"
}

variable "dynatrace_long_term_Logsearch_volume_size" {
  type        = number
  description = "size of the dynatrace_long_term_Logsearch volume"
}

variable "dynatrace_nfs_backup_volume_size" {
  type        = number
  description = "size of the dynatrace_nfs_backup volume"
}