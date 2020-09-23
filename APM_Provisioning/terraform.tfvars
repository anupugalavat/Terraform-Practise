# NSX-T access information
nsxt_host_ip   = "192.168.11.71"
nsxt_user_name = "admin"
nsxt_password  = "VMware1!VMware1!"

# NSX-T landscape details
nsxt_policy_edge_cluster  = "WLD01"
nsxt_policy_overlay_tz    = "overlay-tz-l02-wld01-nsx01.rainpole.local"
nsxt_policy_tier0_gateway = "T0-WLD01"
dns_server_addresses      = ["192.168.10.253", "8.8.8.8"]
dhcp_server_addresses     = "100.96.0.1/30"

# NSX-T network config details
nsxt_policy_dhcp_server                        = "apm-dhcp"
dhcp_lease_period                              = 86400
nsxt_policy_tier1_gateway                      = "apm-gateway"
nsxt_policy_network_segment                   = "apm-segment"
nsxt_policy_network_segment_cidr              = "10.10.1.1/24"
nsxt_policy_network_segment_dhcp_alloc_ranges = "10.10.1.10-10.10.1.245"

# NSX-T
nsxt_tag_scope = "project"
nsxt_tag       = "apm"

#NSX-T public ip pool path
public_ip_pool_path = "/infra/ip-pools/APM_ip_pool"

#NSX-T enable/disable whietlist ips
ui_whitelist_enabled    = "true"
agent_whitelist_enabled = "true"

#NSX-T whietlist ips
ui_whitelist    = ["172.16.4.165/32", "172.16.4.181/32", "172.15.254.41/32"]
agent_whitelist = ["172.15.254.41/32", "172.15.254.84/32", "172.15.254.41/32"]

# jumpbox details
jumpbox_public_ip = "172.15.254.85"
jumpbox_username  = "ubuntu"
jumpbox_key       = "../../credentials/dynatrace"

# Vcenter access information
vcenter_ip        = "192.168.11.64"
vcenter_user_name = "Administrator@vsphere.local"
vcenter_password  = "VMware1!"

# Vmware landscape details lab 3b
vsphere_datacenter                 = "Hardware-DC"
vsphere_datastore                  = ["/Hardware-DC/datastore/Hardware-l02-wld02-vc01-linuxlab3b-vsan01", "/Hardware-DC/datastore/Hardware-l02-wld02-vc01-linuxlab3a-vsan01"]
vsphere_distributed_virtual_switch = "Hardware-l02-wld02-vc01-linuxlab3b-vds01"
vsphere_resource_pool              = "linuxlab3b/Resources"
vsphere_compute_cluster            = ["linuxlab3a", "linuxlab3b"]

# Note: if below volume size changes, the disk will be recreated, hence the data will be lost
# https://github.com/hashicorp/terraform-provider-vsphere/issues/851
# disks size of dynatrace volumes and nfs volumes
dynatrace_opt_storage_volume_size         = 30
dynatrace_transaction_data_volume_size    = 30
dynatrace_long_term_Cassandra_volume_size = 30
dynatrace_long_term_Logsearch_volume_size = 30
dynatrace_nfs_backup_volume_size          = 30
jumpbox_data_disk_volume_size             = 30

# content library details
vsphere_content_library           = "APM-UBUNTU"
vsphere_content_library_item_name = "Ubuntu-CLOUDIMAGE-18.04"
vsphere_content_library_file_url  = "https://cloud-images.ubuntu.com/releases/server/18.04/release-20200807/ubuntu-18.04-server-cloudimg-amd64.ova"

# jumpbox_with_disk VM config details
jumpbox_with_disk_instances      = 3
jumpbox_with_disk_cpu            = 2
jumpbox_with_disk_mem            = 1024
jumpbox_with_disk_base_disk_size = 20
jumpbox_with_disk_guest_id       = "ubuntu64Guest"

# jumpbox without disk VM config details
jumpbox_without_disk_instances      = 3
jumpbox_without_disk_cpu            = 2
jumpbox_without_disk_mem            = 1024
jumpbox_without_disk_base_disk_size = 20
jumpbox_without_disk_guest_id       = "ubuntu64Guest"

# Dynatrace VM config details
dynatrace_instances      = 3
dynatrace_cpu            = 2
dynatrace_mem            = 1024
dynatrace_base_disk_size = 20
dynatrace_guest_id       = "ubuntu64Guest"

# Dynatrace CAG VM config details
dyntrace_cag_instances       = 3
dynatrace_cag_cpu            = 2
dynatrace_cag_mem            = 1024
dynatrace_cag_base_disk_size = 30
dynatrace_cag_guest_id       = "ubuntu64Guest"

# NFS VM config details
nfs_cpu            = 2
nfs_mem            = 1024
nfs_base_disk_size = 30
nfs_guest_id       = "ubuntu64Guest"

# Disks vmdk path - outputs of disks.tf file
dynatrace_opt_storage_volume_vmdk_path         = [""]
dynatrace_transaction_data_volume_vmdk_path    = [""]
dynatrace_long_term_cassandra_volume_vmdk_path = [""]
dynatrace_long_term_logsearch_volume_vmdk_path = [""]
dynatrace_nfs_backup_volume_vmdk_path          = [""]
jumpbox_data_disk_volume_vmdk_path             = [""]

# public ips - outputs of public_ips.tf file
dynatrace_public_ips        = [""]
dynatrace_cag_public_ips    = [""]
jumpbox_without_disk_public_ips = [""]
jumpbox_with_disk_public_ips = [""]

# VM user and folder details
os_user                = "ubuntu"
os_public_key          = "../../credentials/dynatrace.pub"
os_private_key         = "../../credentials/dynatrace"
helper_dir             = "../../helper/"
terraform_tmp_folder   = "/tmp/terraform"
terraform_tools_folder = "/opt/terraform"

# Volumes mounts
dynatrace_opt_volume_mount                     = "/dynopt"
dynatrace_transaction_data_volume_mount        = "/dynraw"
dynatrace_longterm_Logsearch_data_volume_mount = "/dynlogs"
dynatrace_longterm_cassandra_data_volume_mount = "/dyncas"
dynatrace_backup_nfs_mount                     = "/nfsvol"
jumpbox_data_disk_volume_mount                 = "/jbvol"

# jumpbox with disk details
jumpbox_with_disk_public_ip = [""]
jumpbox_with_disk_username  = "ubuntu"
jumpbox_with_disk_key       = "../../credentials/dynatrace"

# jumpbox without disk details
jumpbox_without_disk_public_ip = [""]
jumpbox__without_disk_username  = "ubuntu"
jumpbox__without_disk_key       = "../../credentials/dynatrace"