#Vmware vsphere provider
provider "vsphere" {
  version = "< 1.18"
  vsphere_server       = var.vcenter_ip
  user                 = var.vcenter_user_name
  password             = var.vcenter_password
  allow_unverified_ssl = true
}
#Vmware Vsphere dynatrace jumpbox data disk volume
resource "vsphere_virtual_disk" "jumpbox_data_disk_volume" {
  count      = var.jumpbox_with_disk_instances
  size       = var.jumpbox_data_disk_volume_size
  vmdk_path  = "APM-Volumes/jumpbox_data_disk_volume-${count.index}.vmdk"
  datacenter = var.vsphere_datacenter
  datastore  = var.vsphere_datastore
  type       = "thin"
}
#output all vmdk paths which will be consumed by attaching disk in vsphere_virtual_machine resources in vms.tf
output "jumpbox_data_disk_volume_vmdk_path" {
  value = join(",", vsphere_virtual_disk.jumpbox_data_disk_volume.*.id)
}