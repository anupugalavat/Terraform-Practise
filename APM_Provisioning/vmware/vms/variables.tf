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
  type        = list(string)
  description = "vsphere datastore name"
}

variable "vsphere_compute_cluster" {
  type        = list(string)
  description = "vsphere cluster name"
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

# Dynatrace instance config details
variable "dynatrace_instances" {
  type        = number
  description = "number of dynatrace instances"
}

variable "dynatrace_cpu" {
  type        = number
  description = "number of Vcpu for dynatrace instance"
}

variable "dynatrace_mem" {
  type        = number
  description = "ram memory in MB for the dynatrace instance"
}

variable "dynatrace_base_disk_size" {
  type        = number
  description = "os disk size in GB for dynatrace instance"
}

variable "dynatrace_guest_id" {
  type        = string
  description = "guest id of os image of the ova template used for dynatrace instance"
}

# Dynatrace CAG instance config details
variable "dyntrace_cag_instances" {
  type        = number
  description = "number of dynatrace cag instances"
}

variable "dynatrace_cag_cpu" {
  type        = number
  description = "number of Vcpu for dynatrace cag instance"
}

variable "dynatrace_cag_mem" {
  type        = number
  description = "ram memory in MB for the dynatrace cag instance"
}

variable "dynatrace_cag_base_disk_size" {
  type        = number
  description = "os disk size in GB for dynatrace cag instance"
}

variable "dynatrace_cag_guest_id" {
  type        = string
  description = "guest id of os image of the ova template used for dynatrace cag instance"
}

# NFS instance config details
variable "nfs_cpu" {
  type        = number
  description = "number of Vcpu for nfs instance"
}

variable "nfs_mem" {
  type        = number
  description = "ram memory in MB for the nfs instance"
}

variable "nfs_base_disk_size" {
  type        = number
  description = "os disk size in GB for nfs instance"
}

variable "nfs_guest_id" {
  type        = string
  description = "guest id of os image of the ova template used for nfs instance"
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

# Disks vmdk path - outputs of disks.tf file
variable "dynatrace_transaction_data_volume_vmdk_path" {
  type        = list(string)
  description = "Comma-separated list of IDs of the volume for raw transaction data"
}

variable "dynatrace_long_term_logsearch_volume_vmdk_path" {
  type        = list(string)
  description = "Comma-separated list of IDs of the volume for long term logsearch data"
}

variable "dynatrace_long_term_cassandra_volume_vmdk_path" {
  type        = list(string)
  description = "Comma-separated list of IDs of the volume for long term cassandra data"
}

variable "dynatrace_opt_storage_volume_vmdk_path" {
  type        = list(string)
  description = "Comma-separated list of IDs of the volume for backups"
}

variable "dynatrace_nfs_backup_volume_vmdk_path" {
  type        = list(string)
  description = "Comma-separated list of IDs of the volume for nfs backups"
}

# Volumes mounts
variable "dynatrace_opt_volume_mount" {
  type        = string
  description = "mount point for opt"
}

variable "dynatrace_transaction_data_volume_mount" {
  type        = string
  description = "mount point for raw data"
}

variable "dynatrace_longterm_Logsearch_data_volume_mount" {
  type        = string
  description = "mount point for long-term data"
}

variable "dynatrace_longterm_cassandra_data_volume_mount" {
  type        = string
  description = "mount point for long-term data"
}

variable "dynatrace_backup_nfs_mount" {
  type        = string
  description = "nfs mount point for backups"
}

# public ips - outputs of public_ips.tf file
variable "dynatrace_public_ips" {
  type        = list(string)
  description = "Comma-separated list of public IPs to attach to dynatrace VMs"
}

variable "dynatrace_cag_public_ips" {
  type        = list(string)
  description = "Comma-separated list of public IPs to attach to dynatrace cag VMs"
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

# Jumpbox details
variable "jumpbox_public_ip" {
  type        = string
  description = "Public IP of jumpbox"
}

variable "jumpbox_username" {
  type        = string
  description = "username of jumpbox"
}

variable "jumpbox_key" {
  type        = string
  description = "Location of private SSH jumpbox key"
}