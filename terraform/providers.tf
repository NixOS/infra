provider "aws" {
  region = "eu-west-1"
}

provider "aws" {
  alias  = "us"
  region = "us-east-1"
}

provider "fastly" {}

# Create a token at https://app.netlify.com/user/applications/personal
# And then import using `tf import secret_resource.netlify_token <TOKEN>`
resource "secret_resource" "netlify_token" {
  lifecycle { prevent_destroy = true }
}

# Ask @Raito_Bezarius an extra token if needed.
resource "secret_resource" "raito_fastlylogs_s3_secret_key" {
  lifecycle { prevent_destroy = true }
}

provider "netlify" {
  token = secret_resource.netlify_token.value
}
