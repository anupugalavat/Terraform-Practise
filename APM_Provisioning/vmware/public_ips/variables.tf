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

# number of public ips to be allocated from pool = number of instances
variable "dynatrace_instances" {
  type        = number
  description = "number of dynatrace instances"
}
variable "dyntrace_cag_instances" {
  type        = number
  description = "number of dynatrace cag instances"
}

# public ip pool path
variable "public_ip_pool_path" {
  type        = string
  description = "nsxt path of ip pool which contains public ips"
}