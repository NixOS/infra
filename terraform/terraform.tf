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
      source = "registry.opentofu.org/hashicorp/aws"
    }
    fastly = {
      source = "registry.opentofu.org/fastly/fastly"
    }
    netlify = {
      source = "registry.opentofu.org/AegirHealth/netlify"
    }
    secret = {
      source = "registry.opentofu.org/numtide/secret"
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
