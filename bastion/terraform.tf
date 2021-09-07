terraform {
  backend "s3" {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/bastion"
    region  = "eu-west-1"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}
