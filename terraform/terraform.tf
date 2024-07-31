terraform {
  backend "s3" {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/terraform"
    region  = "eu-west-1"
    profile = "nixos-prod"
  }

  required_providers {
    aws = {
      source = "registry.terraform.io/hashicorp/aws"
    }
    fastly = {
      source = "registry.terraform.io/fastly/fastly"
    }
    netlify = {
      source = "registry.terraform.io/AegirHealth/netlify"
    }
    secret = {
      source = "registry.terraform.io/numtide/secret"
    }
  }
}

data "terraform_remote_state" "terraform-iam" {
  backend = "s3"
  config = {
    bucket  = "nixos-terraform-state"
    encrypt = true
    key     = "targets/terraform-iam"
    region  = "eu-west-1"
    profile = "nixos-prod"
  }
}
