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
  type        = string
  description = "vsphere datastore name"
}

# number of disks to be created = number of dynatrace jumpbox with disk instances
variable "jumpbox_with_disk_instances" {
  type        = number
  description = "number of jumpbox_with_disk_instances instances"
}
#
# size of disks to be provsiosned.
# NOTE: ANY CHANGE IN DISK SIZE WILL RECREATE THE DISK, HENCE DATA WILL BE LOST
# https://github.com/hashicorp/terraform-provider-vsphere/issues/851
#
variable "jumpbox_data_disk_volume_size" {
  type        = number
  description = "size of the jumpbox data disk volume"
}