variable "etcd_discovery_uri" {}
variable "admin_key_name" {}
variable "sg" {}
variable "region" {}
variable "coreos-channel" {
  default = "stable"
}
variable "kubernetes_release" {
  default = "v1.0.6"
}
variable "primary-az" {}
variable "secondary-az" {}
variable "primary-az-subnet" {}
variable "secondary-az-subnet" {}
variable "master-cluster-size" {
   default = 1
}
variable "node-cluster-size" {
   default = 3
}
variable "master-instance_type" {
    default = "t2.small"
}
variable "node-instance_type" {
    default = "m3.large"
}
variable "flanneld_cidr" {
    default = "10.244.0.0/24"
}
