variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

variable "bucket" {
  type    = string
  default = "nixos-amis"
}

variable "service_role_name" {
  type    = string
  default = "vmimport"
}

variable "image_store_path" {
  type = string
}
