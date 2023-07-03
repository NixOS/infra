terraform {
  backend "s3" {
    bucket = "nixos-terraform-state"
    encrypt = true
    key = "nixos-amis.tfstate"
    workspace_key_prefix = "targets/amis/releases"
    region = "eu-west-1"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}
