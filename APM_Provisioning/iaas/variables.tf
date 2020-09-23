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

# NSX-T landscape details
variable "nsxt_policy_edge_cluster" {
  type        = string
  description = "policy resource - edge cluster name"
}

variable "nsxt_policy_overlay_tz" {
  type        = string
  description = "policy resource - transport zone name - overlay network"
}

variable "nsxt_policy_tier0_gateway" {
  type        = string
  description = "policy resource-tier0-gateway name"
}

variable "dns_server_addresses" {
  type        = list(string)
  description = "dns server addresses"
}

variable "dhcp_server_addresses" {
  type        = string
  description = "dhcp server addresses"
}

# NSX-T network config details
variable "nsxt_policy_dhcp_server" {
  type        = string
  description = "policy resource - dhcp server name"
}

variable "dhcp_lease_period" {
  type        = number
  description = "dhcp lease period in seconds"
}

variable "nsxt_policy_tier1_gateway" {
  type        = string
  description = "policy resource - tier1-gateway name"
}

variable "nsxt_policy_network_segment" {
  type        = string
  description = "policy resource - network segment name"
}

variable "nsxt_policy_network_segment_cidr" {
  type        = string
  description = "ip cidr block used by segment"
}

variable "nsxt_policy_network_segment_dhcp_alloc_ranges" {
  type        = string
  description = "range of ips to be dynamically provisioned by dhcp for resources in segment"
}

# NSX-T TAGs
variable "nsxt_tag_scope" {
  type    = string
}
variable "nsxt_tag" {
  type    = string
}