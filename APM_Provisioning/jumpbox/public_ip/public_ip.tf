#NSX-T provider
provider "nsxt" {
  host                 = var.nsxt_host_ip
  username             = var.nsxt_user_name
  password             = var.nsxt_password
  allow_unverified_ssl = true
}
#public ip allocation from pool for jumpbox with disk
resource "nsxt_policy_ip_address_allocation" "jumpbox_with_disk_public_ip_allocation" {
  count        = var.jumpbox_with_disk_instances
  display_name = "jumpbox_with_disk-public_ip_allocation"
  description  = "Public ip address allocated from pool for jumpbox with disk instances"
  pool_path    = var.public_ip_pool_path
}
#public ip allocation from pool for jumpbox without disk
resource "nsxt_policy_ip_address_allocation" "jumpbox_without_disk_public_ip_allocation" {
  count        = var.jumpbox_without_disk_instances
  display_name = "jumpbox_without_disk-public_ip_allocation"
  description  = "Public ip address allocated from pool for jumpbox without disk instances"
  pool_path    = var.public_ip_pool_path
}
#output list of public allocation ips from pool which will be consumed for natting with private ip of vsphere_virtual_machine in vms.tf
output "jumpbox_with_disk_public_ips" {
  value = split(",", join(",", nsxt_policy_ip_address_allocation.jumpbox_with_disk_public_ip_allocation.*.allocation_ip))
}
#output list of public allocation ips from pool which will be consumed for natting with private ip of vsphere_virtual_machine in vms.tf
output "jumpbox_without_disk_public_ips" {
  value = split(",", join(",", nsxt_policy_ip_address_allocation.jumpbox_without_disk_public_ip_allocation.*.allocation_ip))
}