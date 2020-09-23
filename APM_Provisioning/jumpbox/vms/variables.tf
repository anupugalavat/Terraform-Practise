# NSX-T provider information
variable "nsxt_host_ip" {
  type        = string
  description = "nsxt Workload Domain NSX-T LB ip"
}

variable "nsxt_user_name" {
  type        = string
  description = "nsxt host user name"
}

variable "nsxt_password" {
  type        = string
  description = "nsxt host password"
}

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

# VMware Vsphere landscape details
variable "vsphere_datacenter" {
  type        = string
  description = "vsphere datacenter name"
}

variable "vsphere_datastore" {
  type        = string
  description = "vsphere datastore name"
}

variable "vsphere_distributed_virtual_switch" {
  type        = string
  description = "vsphere distributed virtual switch datastore name"
}

variable "dns_server_addresses" {
  type        = list(string)
  description = "dns server addresses"
}

variable "vsphere_resource_pool" {
  type        = string
  description = "vsphere resource pool name"
}

# VMware Vsphere content library details
variable "vsphere_content_library" {
  type        = string
  description = "vsphere content library name to create"
}

variable "vsphere_content_library_item_name" {
  type        = string
  description = "name of the ubuntu ova template to create"
}

variable "vsphere_content_library_file_url" {
  type        = string
  description = "remote url to download ubuntu ova"
}
# Dynatrace Jumpbox without disk instance config details
variable "jumpbox_without_disk_instances" {
type = number
description = " number of instance for jumpbox without disk"
}

variable "jumpbox_without_disk_cpu" {
  type        = number
  description = "number of Vcpu for Jumpbox instance"
}

variable "jumpbox_without_disk_mem" {
  type        = number
  description = "ram memory in MB for the Jumpbox instance"
}

variable "jumpbox_without_disk_base_disk_size" {
  type        = number
  description = "os disk size in GB for Jumpbox instance"
}

variable "jumpbox_without_disk_guest_id" {
  type        = string
  description = "guest id of os image of the ova template used for Jumpbox instance"
}

variable "jumpbox_without_disk_public_ips" {
  type        = list(string)
  description = "Comma-separated list of public IPs to attach to dynatrace jumpbox VMs"
}

# NSXT network segment
variable "nsxt_policy_network_segment" {
  type        = string
  description = "policy resource - network segment name"
}

# NSXT teir1 gateway
variable "nsxt_policy_tier1_gateway" {
  type        = string
  description = "policy resource - tier1-gateway name"
}

# NSX-T TAGs
variable "nsxt_tag_scope" {
  type = string
}

variable "nsxt_tag" {
  type = string
}

# VM user and folder details
variable "os_user" {
  type        = string
  description = "user for os access"
}

variable "os_public_key" {
  type        = string
  description = "file Path for public key"
}

variable "os_private_key" {
  type        = string
  description = "file path private key"
}

variable "helper_dir" {
  type        = string
  description = "Directoty Path for helper script files"
}

variable "terraform_tmp_folder" {
  type        = string
  description = "temp folder for provisioning"
}

variable "terraform_tools_folder" {
  type        = string
  description = "tools folder for provisioning"
}

# Dynatrace Jumpbox with disk instance config details
variable "jumpbox_with_disk_instances" {
type = number
description = " number of instance for jumpbox without disk"
}

variable "jumpbox_with_disk_cpu" {
  type        = number
  description = "number of Vcpu for Jumpbox instance"
}

variable "jumpbox_with_disk_mem" {
  type        = number
  description = "ram memory in MB for the Jumpbox instance"
}

variable "jumpbox_with_disk_base_disk_size" {
  type        = number
  description = "os disk size in GB for Jumpbox instance"
}

variable "jumpbox_with_disk_guest_id" {
  type        = string
  description = "guest id of os image of the ova template used for Jumpbox instance"
}

variable "jumpbox_with_disk_public_ips" {
  type        = list(string)
  description = "Comma-separated list of public IPs to attach to dynatrace jumpbox VMs"
}

variable "jumpbox_with_disk_username" {
  type        = string
  description = "username of jumpbox"
}

variable "jumpbox_with_disk_key" {
  type        = string
  description = "Location of private SSH jumpbox key"
}
# Disks vmdk path - outputs of disks.tf file
variable "jumpbox_data_disk_volume_vmdk_path" {
  type        = list(string)
  description = "Comma-separated list of IDs of the volume for raw transaction data"
}
# Volumes mounts
variable "jumpbox_data_disk_volume_mount" {
  type        = string
  description = "mount point for jumpbox data disk volume"
}