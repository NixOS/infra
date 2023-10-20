provider "aws" {
  region  = "eu-west-1"
  profile = "nixos-prod"
}

provider "aws" {
  alias   = "us"
  region  = "us-east-1"
  profile = "nixos-prod"
}

provider "fastly" {}
