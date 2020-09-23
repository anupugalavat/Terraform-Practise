data "terraform_remote_state" "disks" {
  backend = "consul"

  config = {
    address = "http://172.15.254.14:8500"
    path    = "tf/vmware/disks-state"
  }
}
data "terraform_remote_state" "public_ips" {
  backend = "consul"

  config = {
    address = "http://172.15.254.14:8500"
    path    = "tf/vmware/public_ips-state"
  }
}

#NSX-T provider
provider "nsxt" {
  host                 = var.nsxt_host_ip
  username             = var.nsxt_user_name
  password             = var.nsxt_password
  allow_unverified_ssl = true
}

#VMware Vsphere provider
provider "vsphere" {
  version = "< 1.18"
  vsphere_server       = var.vcenter_ip
  user                 = var.vcenter_user_name
  password             = var.vcenter_password
  allow_unverified_ssl = true
}

#VMware Vsphere Datacenter
data "vsphere_datacenter" "dc" {
  name = var.vsphere_datacenter
}

#VMware Vsphere Datastore
data "vsphere_datastore" "datastore" {
  name          = var.vsphere_datastore
  datacenter_id = data.vsphere_datacenter.dc.id
}
#vmware Vsphere cluster
data "vsphere_compute_cluster" "cluster" {
  name          = var.vsphere_compute_cluster
  datacenter_id = "${data.vsphere_datacenter.dc.id}"
}
#VMware Vsphere Distributed Virtual Switch
data "vsphere_distributed_virtual_switch" "dvs" {
  name          = var.vsphere_distributed_virtual_switch
  datacenter_id = data.vsphere_datacenter.dc.id
}

#Vmware Vsphere Dynatrace Segment
data "vsphere_network" "apm_network" {
  name                            = var.nsxt_policy_network_segment
  datacenter_id                   = data.vsphere_datacenter.dc.id
  distributed_virtual_switch_uuid = data.vsphere_distributed_virtual_switch.dvs.id
}


# NSXT Tier-1 gateway
data "nsxt_policy_tier1_gateway" "t1_gateway" {
  display_name = var.nsxt_policy_tier1_gateway
}


#Vmware Vsphere Resource Pool
data "vsphere_resource_pool" "pool" {
  name          = var.vsphere_resource_pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

#Vmware Vsphere Content Library
resource "vsphere_content_library" "library" {
  name            = var.vsphere_content_library
  storage_backing = flatten([data.vsphere_datastore.datastore.id])
  description     = "A new source of content"
}

resource "vsphere_content_library_item" "ubuntu1804" {
  name        = var.vsphere_content_library_item_name
  description = "Ubuntu template"
  library_id  = vsphere_content_library.library.id
  file_url    = [var.vsphere_content_library_file_url]
}

#Vmware Vsphere virtual Machine " Dynatrace instances"
resource "vsphere_virtual_machine" "dynatrace" {
  count                       = var.dynatrace_instances
  name                        = "dynatrace-${count.index}"
  resource_pool_id            = data.vsphere_resource_pool.pool.id
  datastore_id                = data.vsphere_datastore.datastore.id
  wait_for_guest_net_routable = true
  num_cpus                    = var.dynatrace_cpu
  memory                      = var.dynatrace_mem
  guest_id                    = var.dynatrace_guest_id
  cdrom {
    client_device = true
  }
  network_interface {
    network_id = data.vsphere_network.apm_network.id
  }
  disk {
    label = "disk0"
    size  = var.dynatrace_base_disk_size
  }

  #AAttach aditional Volumes " dynatrace opt storage volume "
  disk {
    attach       = true
    path         = element(split(",", data.terraform_remote_state.disks.outputs.dynatrace_opt_storage_volume_vmdk_path), count.index)
    label        = "dynatrace_opt_storage_volume-${count.index}"
    disk_mode    = "independent_persistent"
    unit_number  = 1
    datastore_id = data.vsphere_datastore.datastore.id
  }

  #Attach additional Volumes " dynatrace transaction data volume "
  disk {
    attach       = true
    path         = element(split(",", data.terraform_remote_state.disks.outputs.dynatrace_transaction_data_volume_vmdk_path), count.index)
    label        = "dynatrace_transaction_data_volume-${count.index}"
    disk_mode    = "independent_persistent"
    unit_number  = 2
    datastore_id = data.vsphere_datastore.datastore.id
  }

  #Attach additional Volumes " dynatrace long term Logsearch volume "
  disk {
    attach       = true
    path         = element(split(",", data.terraform_remote_state.disks.outputs.dynatrace_long_term_logsearch_volume_vmdk_path), count.index)
    label        = "dynatrace_long_term_Logsearch_volume-${count.index}"
    disk_mode    = "independent_persistent"
    unit_number  = 3
    datastore_id = data.vsphere_datastore.datastore.id
  }

  #Attach aadditional Volumes " dynatrace long term Cassandra volume "
  disk {
    attach       = true
    path         = element(split(",", data.terraform_remote_state.disks.outputs.dynatrace_long_term_cassandra_volume_vmdk_path), count.index)
    label        = "dynatrace_long_term_Cassandra_volume-${count.index}"
    disk_mode    = "independent_persistent"
    unit_number  = 4
    datastore_id = data.vsphere_datastore.datastore.id
  }
  clone {
    template_uuid = vsphere_content_library_item.ubuntu1804.id
  }
  vapp {
    properties = {
      "public-keys" = file("${var.os_public_key}")
      "hostname"    = "dynatrace-${count.index}"
    }
  }
}

#Vmware Vsphere virtual Machine " Dynatrace cluster active gate instances "
resource "vsphere_virtual_machine" "dynatrace-cluster-active-gate" {
  count                       = var.dyntrace_cag_instances
  name                        = "dynatrace-cluster-active-gate-${count.index}"
  resource_pool_id            = data.vsphere_resource_pool.pool.id
  datastore_id                = data.vsphere_datastore.datastore.id
  wait_for_guest_net_routable = true
  num_cpus                    = var.dynatrace_cag_cpu
  memory                      = var.dynatrace_cag_mem
  guest_id                    = var.dynatrace_cag_guest_id
  cdrom {
    client_device = true
  }
  network_interface {
    network_id = data.vsphere_network.apm_network.id
  }
  disk {
    label = "disk0"
    size  = var.dynatrace_cag_base_disk_size
  }

  clone {
    template_uuid = vsphere_content_library_item.ubuntu1804.id
  }
  vapp {
    properties = {
      "public-keys" = file("${var.os_public_key}")
      "hostname"    = "dynatrace-cluster-active-gate-${count.index}"
    }
  }
}

#Vmware Vsphere virtual Machine " NFS Server instances"
resource "vsphere_virtual_machine" "nfs-server" {
  count                       = 1
  name                        = "nfs-server-${count.index}"
  resource_pool_id            = data.vsphere_resource_pool.pool.id
  datastore_id                = data.vsphere_datastore.datastore.id
  wait_for_guest_net_routable = true
  num_cpus                    = var.nfs_cpu
  memory                      = var.nfs_mem
  guest_id                    = var.nfs_guest_id
  cdrom {
    client_device = true
  }
  network_interface {
    network_id = data.vsphere_network.apm_network.id
  }
  disk {
    label = "disk0"
    size  = var.nfs_base_disk_size
  }
  #Attach additional Volumes nfs backup volume 
  disk {
    attach       = true
    path         = element(split(",", data.terraform_remote_state.disks.outputs.dynatrace_nfs_backup_volume_vmdk_path), count.index)
    label        = "dynatrace_nfs_backup_volume-${count.index}"
    disk_mode    = "independent_persistent"
    unit_number  = 1
    datastore_id = data.vsphere_datastore.datastore.id
  }

  clone {
    template_uuid = vsphere_content_library_item.ubuntu1804.id
  }
  vapp {
    properties = {
      "public-keys" = file("${var.os_public_key}")
      "hostname"    = "nfs-server-${count.index}"
    }
  }
}

#Post provisioning tasks / install required packages
resource "null_resource" "install_packages" {

  count      = var.dynatrace_instances
  depends_on = [vsphere_virtual_machine.dynatrace]
  # Changes to any instance of the cluster requires re-provisioning

  triggers = {
    cluster_instance_ids = join(",", vsphere_virtual_machine.dynatrace.*.id)
  }

  connection {
    type                = "ssh"
    host                = element(vsphere_virtual_machine.dynatrace.*.default_ip_address, count.index)
    user                = var.os_user
    private_key         = file("${var.os_private_key}")
    timeout             = "5m"
    agent               = false
    bastion_host        = var.jumpbox_public_ip
    bastion_private_key = file("${var.jumpbox_key}")
    bastion_user        = var.jumpbox_username
  }

  #install required apt-get packages
  provisioner "remote-exec" {
    inline = [<<EOC
set -e
timeout 180 /usr/bin/env bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do \
  echo "Waiting for instance boot finished..."; sleep 1; done'
sudo sed -i -e "s/\\(.*127.0.0.1\\s*$(hostname)\\)/\\1/;t;1i127.0.0.1\t$(hostname)" /etc/hosts
echo 'Updating package list...'
sudo apt-get -q update
echo "Upgrading installed packages..."
sudo DEBIAN_FRONTEND=noninteractive sh -c 'apt-get -o Dpkg::Options::="--force-confnew" -q -y --with-new-pkgs upgrade'
echo 'Installing lvm2...'
sudo apt-get -qq install lvm2
echo 'Installing jq...'
sudo apt-get -qq install jq
echo 'Installing unzip...'
sudo apt-get -qq install unzip
echo 'Installing ntp...'
sudo apt-get -qq install ntp
EOC
    ]
  }
}

#Format volumes and attach_volumes
resource "null_resource" "attach_volumes" {

  count      = var.dynatrace_instances
  depends_on = [null_resource.install_packages]
  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = join(",", vsphere_virtual_machine.dynatrace.*.id)
  }

  connection {
    type                = "ssh"
    host                = element(vsphere_virtual_machine.dynatrace.*.default_ip_address, count.index)
    user                = var.os_user
    private_key         = file("${var.os_private_key}")
    timeout             = "5m"
    agent               = false
    bastion_host        = var.jumpbox_public_ip
    bastion_private_key = file("${var.jumpbox_key}")
    bastion_user        = var.jumpbox_username
  }

  provisioner "remote-exec" {
    inline = [<<EOC
set -e
mkdir -p ${var.terraform_tmp_folder}
EOC
    ]
  }

  # provision whole helper folder
  provisioner "file" {
    source      = var.helper_dir
    destination = var.terraform_tmp_folder
  }

  # - mount and prepare volumes
  provisioner "remote-exec" {
    inline = [<<EOC
set -e
chmod a+x ${var.terraform_tmp_folder}/*.sh
echo 'Preparing volumes...'
sudo ${var.terraform_tmp_folder}/mount-lvm.sh sdb ${var.dynatrace_opt_volume_mount} ${var.os_user}
sudo ${var.terraform_tmp_folder}/mount-lvm.sh sdc ${var.dynatrace_transaction_data_volume_mount} ${var.os_user}
sudo ${var.terraform_tmp_folder}/mount-lvm.sh sdd ${var.dynatrace_longterm_Logsearch_data_volume_mount} ${var.os_user}
sudo ${var.terraform_tmp_folder}/mount-lvm.sh sde ${var.dynatrace_longterm_cassandra_data_volume_mount} ${var.os_user}
echo 'Copying tools to ${var.terraform_tools_folder}'
sudo cp -a ${var.terraform_tmp_folder}/. ${var.terraform_tools_folder}/
EOC
    ]
  }
}

#Prepare NFS server
resource "null_resource" "prepare_nfs_server" {

  count = 1

  depends_on = [vsphere_virtual_machine.nfs-server, null_resource.install_packages]

  # Changes to any nfs server or dynatrace cluster instance requires re-provisioning
  triggers = {
    cluster_instance_ids = join(",", concat(vsphere_virtual_machine.dynatrace.*.id, vsphere_virtual_machine.nfs-server.*.id))
  }

  connection {
    type                = "ssh"
    host                = element(vsphere_virtual_machine.nfs-server.*.default_ip_address, count.index)
    user                = var.os_user
    private_key         = file("${var.os_private_key}")
    timeout             = "5m"
    agent               = false
    bastion_host        = var.jumpbox_public_ip
    bastion_private_key = file("${var.jumpbox_key}")
    bastion_user        = var.jumpbox_username
  }

  provisioner "remote-exec" {
    inline = [<<EOC
set -e
mkdir -p ${var.terraform_tmp_folder}
EOC
    ]
  }

  # provision whole helper folder
  provisioner "file" {
    source      = var.helper_dir
    destination = var.terraform_tmp_folder
  }

  # install required apt-get packages
  provisioner "remote-exec" {
    inline = [<<EOC
set -e
timeout 180 /usr/bin/env bash -c \
  'until stat /var/lib/cloud/instance/boot-finished 2>/dev/null; do \
  echo "Waiting for instance boot finished..."; sleep 1; done'
sudo sed -i -e "s/\\(.*127.0.0.1\\s*$(hostname)\\)/\\1/;t;1i127.0.0.1\t$(hostname)" /etc/hosts
echo 'Updating apt-get package list...'
sudo apt-get -q update
echo "Upgrading installed packages..."
sudo DEBIAN_FRONTEND=noninteractive sh -c 'apt-get -o Dpkg::Options::="--force-confnew" -q -y --with-new-pkgs upgrade'
echo 'Installing lvm2...'
sudo apt-get -qq install lvm2
echo 'Installing jq...'
sudo apt-get -qq install jq
echo 'Installing unzip...'
sudo apt-get -qq install unzip
echo 'Installing ntp...'
sudo apt-get -qq install ntp
echo 'Installing nfs server...'
sudo apt-get -qq install nfs-kernel-server
echo "Preparing volumes..."
chmod a+x ${var.terraform_tmp_folder}/*.sh
sudo ${var.terraform_tmp_folder}/mount-lvm.sh sdb ${var.dynatrace_backup_nfs_mount} ${var.os_user}
echo 'Copying tools to ${var.terraform_tools_folder}'
sudo cp -a ${var.terraform_tmp_folder}/. ${var.terraform_tools_folder}/
echo "Exporting NFS volumes..."
sudo su -c "cat /etc/exports | grep -q '${var.dynatrace_backup_nfs_mount}' || { echo '${var.dynatrace_backup_nfs_mount} ${element(vsphere_virtual_machine.nfs-server.*.default_ip_address, 0)}/16(rw,sync,no_subtree_check,no_root_squash)' >> /etc/exports; }"
sudo /etc/init.d/nfs-kernel-server restart
EOC
    ]
  }
}

#Prepare NFS client in dynatrace instances
resource "null_resource" "prepare_nfs_client" {
  count = var.dynatrace_instances

  connection {
    type                = "ssh"
    host                = element(vsphere_virtual_machine.dynatrace.*.default_ip_address, count.index)
    user                = var.os_user
    private_key         = file("${var.os_private_key}")
    timeout             = "5m"
    agent               = false
    bastion_host        = var.jumpbox_public_ip
    bastion_private_key = file("${var.jumpbox_key}")
    bastion_user        = var.jumpbox_username
  }
  depends_on = [
    null_resource.attach_volumes,
  null_resource.prepare_nfs_server]

  # Changes to any instance of the cluster requires re-provisioning
  triggers = {
    cluster_instance_ids = join(",", vsphere_virtual_machine.dynatrace.*.id)
  }
  # - install required apt-get packages
  # - mount and prepare NFS volumes
  provisioner "remote-exec" {
    inline = [<<EOC
set -e
echo "Installing nfs-common..."
sudo apt-get -qq install nfs-common
echo "Preparing NFS volumes..."
sudo umount ${var.dynatrace_backup_nfs_mount} || echo "Unmounting ${var.dynatrace_backup_nfs_mount} failed, will continue anyway..."
sudo mkdir -p ${var.dynatrace_backup_nfs_mount}
sudo chown -R ${var.os_user} ${var.dynatrace_backup_nfs_mount}
sudo mount -t nfs -o defaults ${element(vsphere_virtual_machine.nfs-server.*.default_ip_address, 0)}:${var.dynatrace_backup_nfs_mount} ${var.dynatrace_backup_nfs_mount}
sudo su -c "cat /etc/fstab | grep -q '${element(vsphere_virtual_machine.nfs-server.*.default_ip_address, 0)}' || { echo '${element(vsphere_virtual_machine.nfs-server.*.default_ip_address, 0)}:${var.dynatrace_backup_nfs_mount} ${var.dynatrace_backup_nfs_mount} nfs defaults 0 0' >> /etc/fstab; }"
EOC
    ]
  }
}

#VMware Vsphere instances Public IP assigning by NSXT natting
resource "nsxt_policy_nat_rule" "dynatrace_nat" {
  count                = var.dynatrace_instances
  display_name         = "dynatrace-nat-public"
  action               = "DNAT"
  translated_networks  = [element(vsphere_virtual_machine.dynatrace.*.default_ip_address, count.index)]
  destination_networks = formatlist("%s/32", element(data.terraform_remote_state.public_ips.outputs.dynatrace_public_ips, count.index))
  gateway_path         = data.nsxt_policy_tier1_gateway.t1_gateway.path
  tag {
    scope = var.nsxt_tag_scope
    tag   = var.nsxt_tag
  }
}

resource "nsxt_policy_nat_rule" "dynatrace_cag_nat" {
  count                = var.dyntrace_cag_instances
  display_name         = "dynatrace-cag-nat-public"
  action               = "DNAT"
  translated_networks  = [element(vsphere_virtual_machine.dynatrace-cluster-active-gate.*.default_ip_address, count.index)]
  destination_networks = formatlist("%s/32", element(data.terraform_remote_state.public_ips.outputs.dynatrace_cag_public_ips, count.index))
  gateway_path         = data.nsxt_policy_tier1_gateway.t1_gateway.path
  tag {
    scope = var.nsxt_tag_scope
    tag   = var.nsxt_tag
  }
}

#Tagging instances for dynamic grouping used in security_groups.tf
resource "nsxt_policy_vm_tags" "Dynatrace_tags" {
  count       = var.dynatrace_instances
  instance_id = element(vsphere_virtual_machine.dynatrace.*.id, count.index)

  tag {
    scope = "app"
    tag   = "dynatrace"
  }
  tag {
    scope = "tier"
    tag   = "ssh-server"
  }
  tag {
    scope = "scope"
    tag   = "apm-vms"
  }
}

resource "nsxt_policy_vm_tags" "Dynatrace_CAG_tags" {
  count       = var.dyntrace_cag_instances
  instance_id = element(vsphere_virtual_machine.dynatrace-cluster-active-gate.*.id, count.index)

  tag {
    scope = "app"
    tag   = "dynatrace-cag"
  }
  tag {
    scope = "tier"
    tag   = "ssh-server"
  }
  tag {
    scope = "scope"
    tag   = "apm-vms"
  }
}
resource "nsxt_policy_vm_tags" "NFS_server_tags" {
  count       = 1
  instance_id = element(vsphere_virtual_machine.nfs-server.*.id, count.index)

  tag {
    scope = "app"
    tag   = "dynatrace"
  }
  tag {
    scope = "scope"
    tag   = "apm-vms"
  }
  tag {
    scope = "tier"
    tag   = "ssh-server"
  }
}

# Exports
output "dynatrace_private_ips" {
  value = vsphere_virtual_machine.dynatrace.*.default_ip_address
}

output "dynatrace_public_ips" {
  value = data.terraform_remote_state.public_ips.outputs.dynatrace_public_ips
}

output "dynatrace_cluster_active_gate_ips" {
  value = data.terraform_remote_state.public_ips.outputs.dynatrace_cag_public_ips
}

output "dynatrace_cluster_active_gate_private_ips" {
  value = vsphere_virtual_machine.dynatrace-cluster-active-gate.*.default_ip_address
}

output "dynatrace_keyname" {
  value = "dynatrace-${var.vsphere_datacenter}"
}

output "dynatrace_public_key" {
  value = file("${var.os_public_key}")
}
output "dynatrace_private_key" {
  value = file("${var.os_private_key}")
}

output "nfs_private_ip" {
  value = vsphere_virtual_machine.nfs-server.*.default_ip_address
}