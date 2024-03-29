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
      source = "hashicorp/aws"
    }
    fastly = {
      source = "fastly/fastly"
    }
    netlify = {
      source = "AegirHealth/netlify"
    }
    secret = {
      source = "numtide/secret"
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
