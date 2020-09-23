data "terraform_remote_state" "disks" {
  backend = "consul"

  config = {
    address = "http://172.15.254.14:8500"
    path    = "tf/jumpbox/disks-state"
  }
}
data "terraform_remote_state" "public_ips" {
  backend = "consul"

  config = {
    address = "http://172.15.254.14:8500"
    path    = "tf/jumpbox/public_ips-state"
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

#Vmware vsphere virtual machine "Dynatrace Jumpbox without disk"
resource "vsphere_virtual_machine" "jumpbox_without_disk" {
  count                       = var.jumpbox_without_disk_instances
  name                        = "jumpbox_without_disk-${count.index}"
  resource_pool_id            = data.vsphere_resource_pool.pool.id
  datastore_id                = data.vsphere_datastore.datastore.id
  wait_for_guest_net_routable = true
  num_cpus                    = var.jumpbox_without_disk_cpu
  memory                      = var.jumpbox_without_disk_mem
  guest_id                    = var.jumpbox_without_disk_guest_id
  network_interface {
    network_id = data.vsphere_network.apm_network.id
  }
  disk {
    label = "disk0"
    size  = var.jumpbox_without_disk_base_disk_size
  }

  clone {
    template_uuid = vsphere_content_library_item.ubuntu1804.id
  }
  vapp {
    properties = {
      "public-keys" = file("${var.os_public_key}")
      "hostname"    = "jumpbox_without_disk-${count.index}"
    }
  }
}

resource "nsxt_policy_nat_rule" "jumpbox_without_disk_nat" {
  count                = var.jumpbox_without_disk_instances
  display_name         = "jumpbox_without_disk-nat-public"
  action               = "DNAT"
  translated_networks  = [element(vsphere_virtual_machine.jumpbox_without_disk.*.default_ip_address, count.index)]
  destination_networks = formatlist("%s/32", element(data.terraform_remote_state.public_ips.outputs.jumpbox_without_disk_public_ips, count.index))
  gateway_path         = data.nsxt_policy_tier1_gateway.t1_gateway.path
  tag {
    scope = var.nsxt_tag_scope
    tag   = var.nsxt_tag
  }
}
resource "nsxt_policy_vm_tags" "jumpbox_without_disk_tags" {
  count       = var.jumpbox_without_disk_instances
  instance_id = element(vsphere_virtual_machine.jumpbox_without_disk.*.id, count.index)

  tag {
    scope = "app"
    tag   = "jumpbox_without_disk"
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

#Vmware Vsphere virtual Machine " Dynatrace jumpbox with disk"
resource "vsphere_virtual_machine" "jumpbox_with_disk" {
  count                       = var.jumpbox_with_disk_instances
  name                        = "jumpbox_with_disk-${count.index}"
  resource_pool_id            = data.vsphere_resource_pool.pool.id
  datastore_id                = data.vsphere_datastore.datastore.id
  wait_for_guest_net_routable = true
  num_cpus                    = var.jumpbox_with_disk_cpu
  memory                      = var.jumpbox_with_disk_mem
  guest_id                    = var.jumpbox_with_disk_guest_id

  network_interface {
    network_id = data.vsphere_network.apm_network.id
  }
  disk {
    label = "disk0"
    size  = var.jumpbox_with_disk_base_disk_size
  }

  #AAttach aditional jumpbox disk " jumpbox data disk "
  disk {
    attach       = true
    path         = element(split(",", data.terraform_remote_state.disks.outputs.jumpbox_data_disk_volume_vmdk_path), count.index)
    label        = "jumpbox_data_disk_volume-${count.index}"
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
      "hostname"    = "jumpbox_with_disk-${count.index}"
    }
  }
}

resource "nsxt_policy_nat_rule" "jumpbox_with_disk_nat" {
  count                = var.jumpbox_with_disk_instances
  display_name         = "jumpbox_with_disk-nat-public"
  action               = "DNAT"
  translated_networks  = [element(vsphere_virtual_machine.jumpbox_with_disk.*.default_ip_address, count.index)]
  destination_networks = formatlist("%s/32", element(data.terraform_remote_state.public_ips.outputs.jumpbox_with_disk_public_ips, count.index))
  gateway_path         = data.nsxt_policy_tier1_gateway.t1_gateway.path
  tag {
    scope = var.nsxt_tag_scope
    tag   = var.nsxt_tag
  }
}
resource "nsxt_policy_vm_tags" "jumpbox_with_disk_tags" {
  count       = var.jumpbox_with_disk_instances
  instance_id = element(vsphere_virtual_machine.jumpbox_with_disk.*.id, count.index)

  tag {
    scope = "app"
    tag   = "jumpbox_with_disk"
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

output "jumpbox_without_disk_ips" {
  value = data.terraform_remote_state.public_ips.outputs.jumpbox_without_disk_public_ips
}
output "jumpbox_with_disk_ips" {
  value = data.terraform_remote_state.public_ips.outputs.jumpbox_with_disk_public_ips
}

output "jumpbox_with_disk_keyname" {
  value = "jumpbox_with_disk-${var.vsphere_datacenter}"
}

output "jumpbox_without_disk_keyname" {
  value = "jumpbox_without_disk-${var.vsphere_datacenter}"
}

output "jumpbox_with_disk_public_key" {
  value = file("${var.os_public_key}")
}
output "jumpbox_without_disk_public_key" {
  value = file("${var.os_public_key}")
}
output "jumpbox_with_disk_private_key" {
  value = file("${var.os_private_key}")
}
output "jumpbox_without_disk_private_key" {
  value = file("${var.os_private_key}")
}