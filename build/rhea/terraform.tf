terraform {
  backend "s3" {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/rhea"
    region  = "eu-west-1"
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

module "rhea_deploy" {
  source = "github.com/numtide/terraform-deploy-nixos-flakes"

  target_host = "5.9.122.43"
  target_user = "root"

  flake      = path.module
  flake_host = "rhea"

  ssh_agent = true
}
