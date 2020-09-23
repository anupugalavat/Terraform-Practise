# NSX-T provider
provider "nsxt" {
  host                 = var.nsxt_host_ip
  username             = var.nsxt_user_name
  password             = var.nsxt_password
  allow_unverified_ssl = true
}

# NSX-T group vms based on nsxt policy vm tags
resource "nsxt_policy_group" "all_vms_group" {
  display_name = "all-vms-group"
  description  = "Group consisting of all apm vpms"
  criteria {
    condition {
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      key         = "Tag"
      value       = "apm-vms"

    }
  }
}

resource "nsxt_policy_group" "ssh_group" {
  display_name = "ssh-group"
  description  = "Group consisting of Dynatrace and Dynatrace_CAG for SSH access"
  criteria {
    condition {
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      key         = "Tag"
      value       = "ssh-server"

    }
  }
}

resource "nsxt_policy_group" "Dynatrace_group" {
  display_name = "Dynatrace-group"
  description  = "Group consisting Dynatrace and NFS VMs"
  criteria {
    condition {
      member_type = "VirtualMachine"
      operator    = "EQUALS"
      key         = "Tag"
      value       = "dynatrace"
    }
  }
}

resource "nsxt_policy_group" "Dynatrace_CAG_group" {
  display_name = "Dynatrace-CAG-group"
  description  = "Group consisting Dynatace CAG VMs"
  criteria {
    condition {
      member_type = "VirtualMachine"
      operator    = "CONTAINS"
      key         = "Tag"
      value       = "dynatrace-cag"
    }
  }
}

# NSX-T group based on whitelisted ips
resource "nsxt_policy_group" "Agent_whitelist_group" {
  display_name = "Agent_whitelist_groups"
  description  = "Group containing all Agent whitelisted IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = split(",", var.agent_whitelist_enabled ? join(",", var.agent_whitelist) : "0.0.0.0/0")
    }
  }
}

resource "nsxt_policy_group" "UI_whitelist_group" {
  display_name = "UI_whitelist_groups"
  description  = "Group containing all UI whitelisted IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = split(",", var.ui_whitelist_enabled ? join(",", var.ui_whitelist) : "0.0.0.0/0")
    }
  }
}

# NSX-T service creation for ports used in firewall
resource "nsxt_policy_service" "node_service_443" {
  display_name = "service-node-443"
  description  = "Allow UI and Agent traffic access to Cluster nodes (443)"
  l4_port_set_entry {
    display_name      = "node_443"
    description       = "TCP Port 443"
    protocol          = "TCP"
    destination_ports = ["443"]
  }
}

resource "nsxt_policy_service" "node_service_8443" {
  display_name = "service-node-8443"
  description  = "Allow UI and Agent traffic access to Cluster nodes (8443)"
  l4_port_set_entry {
    display_name      = "node_8443"
    description       = "TCP Port 8443"
    protocol          = "TCP"
    destination_ports = ["8443"]
  }
}

resource "nsxt_policy_service" "ssh_service" {
  display_name = "service-ssh"
  description  = "Allow ssh port "
  l4_port_set_entry {
    display_name      = "SSH_22"
    description       = "TCP Port 22"
    protocol          = "TCP"
    destination_ports = ["22"]
  }
}

resource "nsxt_policy_service" "Dynatrace-CAG-service" {
  display_name = "service-Dynatrace-CAG"
  description  = "Allow agent traffic towards cluster ActiveGates (9999)"
  l4_port_set_entry {
    display_name      = "Dynatrace_CAG_9999"
    description       = "TCP Port 9999"
    protocol          = "TCP"
    destination_ports = ["9999"]
  }
}

resource "nsxt_policy_service" "Dynatrace-mutual-access-service" {
  display_name = "service-Dynatrace-mutual-access"
  description  = "Allow dynatrace instances to access each other"
  l4_port_set_entry {
    display_name      = "Dynatrace_mutual_access_1-65535"
    description       = "TCP Port 1-65535"
    protocol          = "TCP"
    destination_ports = ["1-65535"]
  }
}

resource "nsxt_policy_group" "SSH_whitelist_group" {
  display_name = "SSH_whitelist_group"
  description  = "Group containing SSH whitelisted IPs"
  criteria {
    ipaddress_expression {
      ip_addresses = list(format("%s/32", var.jumpbox_public_ip))
    }
  }
}

# NSX-T firewall creation
resource "nsxt_policy_security_policy" "APM_Firewall" {
  display_name = "APM-Firewall"
  description  = "Firewall for ALL APM VMs"
  scope        = [nsxt_policy_group.all_vms_group.path]
  category     = "Application"
  locked       = "false"
  stateful     = "true"

  rule {
    display_name       = "Allow_1-65535_access"
    description        = "Allow dynatrace instances to access each other"
    action             = "ALLOW"
    logged             = "false"
    ip_version         = "IPV4"
    source_groups      = [nsxt_policy_group.Dynatrace_group.path]
    destination_groups = [nsxt_policy_group.Dynatrace_group.path]
    services           = [nsxt_policy_service.Dynatrace-mutual-access-service.path]
  }

  rule {
    display_name       = "Allow_22_access"
    description        = "Allow ssh access for ssh_whitelist_group to access each other"
    action             = "ALLOW"
    logged             = "false"
    ip_version         = "IPV4"
    source_groups      = [nsxt_policy_group.SSH_whitelist_group.path]
    destination_groups = [nsxt_policy_group.ssh_group.path]
    services           = [nsxt_policy_service.ssh_service.path]
  }

  rule {
    display_name       = "Allow_9999_access"
    description        = "Allow agent whitelist ips to access Dynatrce cag vms via 9999 "
    action             = "ALLOW"
    logged             = "false"
    ip_version         = "IPV4"
    source_groups      = [nsxt_policy_group.Agent_whitelist_group.path]
    destination_groups = [nsxt_policy_group.Dynatrace_CAG_group.path]
    services           = [nsxt_policy_service.Dynatrace-CAG-service.path]
  }

  rule {
    display_name       = "Allow_443_access"
    description        = "Allow UI whitelist ips to access Dynatrce vms via 443"
    action             = "ALLOW"
    logged             = "false"
    ip_version         = "IPV4"
    source_groups      = [nsxt_policy_group.UI_whitelist_group.path]
    destination_groups = [nsxt_policy_group.Dynatrace_group.path]
    services           = [nsxt_policy_service.node_service_443.path]
  }

  rule {
    display_name       = "Allow_8443_access"
    description        = "Allow Agent whitelist ips to access Dynatrce vms via 443"
    action             = "ALLOW"
    logged             = "false"
    ip_version         = "IPV4"
    source_groups      = [nsxt_policy_group.Agent_whitelist_group.path]
    destination_groups = [nsxt_policy_group.Dynatrace_group.path]
    services           = [nsxt_policy_service.node_service_8443.path]
  }

  rule {
    display_name  = "Allow out"
    description   = "Outgoing rule"
    action        = "ALLOW"
    logged        = "true"
    ip_version    = "IPV4"
    source_groups = [nsxt_policy_group.ssh_group.path]
  }

  # Reject everything else
  rule {
    display_name = "Deny ANY"
    description  = "Default Deny the traffic"
    action       = "REJECT"
    logged       = "true"
    ip_version   = "IPV4"
  }
}