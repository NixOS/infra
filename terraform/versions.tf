terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    fastly = {
      source = "nixpkgs/fastly"
    }
  }
  required_version = ">= 0.13"
}
