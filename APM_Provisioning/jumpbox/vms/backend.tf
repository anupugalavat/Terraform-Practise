terraform {
  backend "consul" {
    address = "http://172.15.254.14:8500"
    path    = "tf/jumpbox/vms-state"
  }
}
