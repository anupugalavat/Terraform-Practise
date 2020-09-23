#Vmware vsphere provider
provider "vsphere" {
  version = "< 1.18"
  vsphere_server       = var.vcenter_ip
  user                 = var.vcenter_user_name
  password             = var.vcenter_password
  allow_unverified_ssl = true
}

# All fields in the vsphere_virtual_disk resource are currently immutable and force a new resource if changed.
# https://github.com/hashicorp/terraform-provider-vsphere/issues/851

#Vmware Vsphere dynatrace opt storage volume
resource "vsphere_virtual_disk" "dynatrace_opt_storage_volume" {
  count      = var.dynatrace_instances
  size       = var.dynatrace_opt_storage_volume_size
  vmdk_path  = "APM-Volumes/dynatrace_opt_storage_volume-${count.index}.vmdk"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  type       = "thin"
}

#Vmware Vsphere dynatrace transaction data volume
resource "vsphere_virtual_disk" "dynatrace_transaction_data_volume" {
  count      = var.dynatrace_instances
  size       = var.dynatrace_transaction_data_volume_size
  vmdk_path  = "APM-Volumes/dynatrace_transaction_data_volume-${count.index}.vmdk"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  type       = "thin"
}

#Vmware Vsphere dynatrace long term cassandra volume
resource "vsphere_virtual_disk" "dynatrace_long_term_Cassandra_volume" {
  count      = var.dynatrace_instances
  size       = var.dynatrace_long_term_Cassandra_volume_size
  vmdk_path  = "APM-Volumes/dynatrace_long_term_Cassandra_volume-${count.index}.vmdk"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  type       = "thin"
}

#Vmware Vsphere dynatrace long term Logsearch volume
resource "vsphere_virtual_disk" "dynatrace_long_term_Logsearch_volume" {
  count      = var.dynatrace_instances
  size       = var.dynatrace_long_term_Logsearch_volume_size
  vmdk_path  = "APM-Volumes/dynatrace_long_term_Logsearch_volume-${count.index}.vmdk"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  type       = "thin"
}
#Vmware Vsphere dynatrace nfs backup volume
resource "vsphere_virtual_disk" "dynatrace_nfs_backup_volume" {
  count      = 1
  size       = var.dynatrace_nfs_backup_volume_size
  vmdk_path  = "APM-Volumes/dynatrace_nfs_backup_volume.vmdk"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  type       = "thin"
}

#output all vmdk paths which will be consumed by attaching disk in vsphere_virtual_machine resources in vms.tf
output "dynatrace_opt_storage_volume_vmdk_path" {
  value = join(",", vsphere_virtual_disk.dynatrace_opt_storage_volume.*.id)
}

output "dynatrace_transaction_data_volume_vmdk_path" {
  value = join(",", vsphere_virtual_disk.dynatrace_transaction_data_volume.*.id)
}

output "dynatrace_long_term_cassandra_volume_vmdk_path" {
  value = join(",", vsphere_virtual_disk.dynatrace_long_term_Cassandra_volume.*.id)
}

output "dynatrace_long_term_logsearch_volume_vmdk_path" {
  value = join(",", vsphere_virtual_disk.dynatrace_long_term_Logsearch_volume.*.id)
}

output "dynatrace_nfs_backup_volume_vmdk_path" {
  value = join(",", vsphere_virtual_disk.dynatrace_nfs_backup_volume.*.id)
}