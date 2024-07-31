provider "aws" {
  region  = "eu-west-1"
  profile = "nixos-prod"

  ignore_tags {
    keys = ["nixos-cost-tag"]
  }
}

provider "aws" {
  alias   = "us"
  region  = "us-east-1"
  profile = "nixos-prod"

  ignore_tags {
    keys = ["nixos-cost-tag"]
  }
}

provider "fastly" {}

# Create a token at https://app.netlify.com/user/applications/personal
# And then import using
# - terraform state rm secret_resource.netlify_token
# - terraform import secret_resource.netlify_token <TOKEN>
resource "secret_resource" "netlify_token" {
  lifecycle { prevent_destroy = true }
}

provider "netlify" {
  token = secret_resource.netlify_token.value
}
