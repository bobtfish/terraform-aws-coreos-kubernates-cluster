variable "sg" {}
variable "region" {}
variable "coreos-channel" {
  default = "stable"
}
variable "primary-az" {}
variable "secondary-az" {}
variable "primary-az-subnet" {}
variable "secondary-az-subnet" {}
variable "master-cluster-size" {
   default = 3
}
variable "node-cluster-size" {
   default = 3
}
variable "master-instancetype" {
    default = "m3.large"
}
variable "node-instancetype" {
    default = "m3.large"
}

