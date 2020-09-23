#NSX-T provider
provider "nsxt" {
  host     = var.nsxt_host_ip
  username = var.nsxt_user_name
  password = var.nsxt_password
  allow_unverified_ssl = true
}

#NSX-T Edge Cluster
data "nsxt_policy_edge_cluster" "edge_cluster" {
  display_name = var.nsxt_policy_edge_cluster
}

#NSX-T Overlay transport zone
data "nsxt_policy_transport_zone" "overlay_tz" {
  display_name = var.nsxt_policy_overlay_tz
}

#NSX-T tier-0 gateway
data "nsxt_policy_tier0_gateway" "tier0_gw_gateway" {
  display_name = var.nsxt_policy_tier0_gateway
}

#NSX-T DHCP Profile for all vms
resource "nsxt_policy_dhcp_server" "apm_dhcp" {
  display_name     = var.nsxt_policy_dhcp_server
  description      = "DHCP server servicing Segments"
  server_addresses = [var.dhcp_server_addresses]
}

#NSX-T Tier-1 Gateway
resource "nsxt_policy_tier1_gateway" "t1_gateway" {
  display_name              = var.nsxt_policy_tier1_gateway
  description               = "tier1 gateway used by all vms"
  edge_cluster_path         = data.nsxt_policy_edge_cluster.edge_cluster.path
  dhcp_config_path          = nsxt_policy_dhcp_server.apm_dhcp.path
  enable_standby_relocation = "true"
  failover_mode             = "NON_PREEMPTIVE"
  tier0_path                = data.nsxt_policy_tier0_gateway.tier0_gw_gateway.path
  route_advertisement_types = ["TIER1_IPSEC_LOCAL_ENDPOINT", "TIER1_CONNECTED", "TIER1_NAT","TIER1_DNS_FORWARDER_IP"]
  tag {
    scope = var.nsxt_tag_scope
    tag   = var.nsxt_tag
  }
}

#NSX-T Network segment
resource "nsxt_policy_segment" "apm-segment" {
  display_name        = var.nsxt_policy_network_segment
  description         = "Segment for all apm related vms"
  connectivity_path   = nsxt_policy_tier1_gateway.t1_gateway.path
  transport_zone_path = data.nsxt_policy_transport_zone.overlay_tz.path
  subnet {
    cidr        = var.nsxt_policy_network_segment_cidr
    dhcp_ranges = [var.nsxt_policy_network_segment_dhcp_alloc_ranges]

    dhcp_v4_config {
      server_address = var.dhcp_server_addresses
      dns_servers    = var.dns_server_addresses
      lease_time     = var.dhcp_lease_period
    }
  }
  tag {
    scope = var.nsxt_tag_scope
    tag   = var.nsxt_tag
  }
}