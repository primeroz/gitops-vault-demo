variable "dependencies" {
  type = "list"
}

variable "instance" {
  default = ""
}

variable "cluster_name" {}
variable "cluster_project" {}
variable "cluster_region" {}

variable "tls_crt" {}
variable "tls_key" {}

variable "controller_version" {
  default = "v0.7.0"
}

variable "enabled" {
  default     = "false"
  description = "is the module enabled"
}
