#NSX-T provider
provider "nsxt" {
  host                 = var.nsxt_host_ip
  username             = var.nsxt_user_name
  password             = var.nsxt_password
  allow_unverified_ssl = true
}

#public ip allocation from pool for dynatrace instances
resource "nsxt_policy_ip_address_allocation" "dynatrace_public_ip_allocation" {
  count        = var.dynatrace_instances
  display_name = "dynatrace-public_ip_allocation"
  description  = "Public ip address allocated from pool for dynatrace instances"
  pool_path    = var.public_ip_pool_path
}

#public ip allocation from pool for dynatrace cluster active gate instances
resource "nsxt_policy_ip_address_allocation" "dynatrace_cag_public_ip_allocation" {
  count        = var.dyntrace_cag_instances
  display_name = "dynatrace-cag_public_ip_allocation"
  description  = "Public ip address for allocated from pool for dynatrace cluster active gates instances"
  pool_path    = var.public_ip_pool_path
}

#output list of public allocation ips from pool which will be consumed for natting with private ip of vsphere_virtual_machine in vms.tf
output "dynatrace_public_ips" {
  value = split(",", join(",", nsxt_policy_ip_address_allocation.dynatrace_public_ip_allocation.*.allocation_ip))
}

output "dynatrace_cag_public_ips" {
  value = split(",", join(",", nsxt_policy_ip_address_allocation.dynatrace_cag_public_ip_allocation.*.allocation_ip))
}