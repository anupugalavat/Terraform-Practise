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

#enable/disable whitelist ips
variable "ui_whitelist_enabled" {
  type        = bool
  description = "set to true/false to enable/disable restricted access through a whitelist"
}
variable "agent_whitelist_enabled" {
  type        = bool
  description = "set to true/false to enable/disable restricted access through a whitelist"
}

#whitelist ip details
variable "ui_whitelist" {
  type        = list(string)
  description = "a set of cidrs that are allowed to access dynatrace VMs on port 8443"
}

variable "agent_whitelist" {
  type        = list(string)
  description = "a set of cidrs that are allowed to access dynatrace VMs on port 8443"
}

#jumpbox ip details
variable "jumpbox_public_ip" {
  type        = string
  description = "public ip of jumpbox"
}