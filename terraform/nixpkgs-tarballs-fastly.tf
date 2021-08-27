locals {
  # The aws_s3_bucket resource returns an unknown domain
  #tarballs_backend = "${lower(aws_s3_bucket.nixpkgs-tarballs.website_endpoint)}"
  tarballs_backend = "nixpkgs-tarballs.s3-website-eu-west-1.amazonaws.com"

  tarballs_domain = "tarballs.nixos.org"
}

resource "fastly_service_v1" "nixpkgs-tarballs" {
  name          = "nixpkgs-tarballs"
  force_destroy = true
  default_host  = local.tarballs_backend

  domain {
    name = local.tarballs_domain
  }

  backend {
    address = local.tarballs_backend
    name    = "AWS S3 website"

    # S3 websites don't binds on port 443
    port = 80
  }

  # Clean headers for caching

  header {
    destination = "http.x-amz-request-id"
    type        = "cache"
    action      = "delete"
    name        = "remove x-amz-request-id"
  }
  header {
    destination = "http.x-amz-version-id"
    type        = "cache"
    action      = "delete"
    name        = "remove x-amz-version-id"
  }
  header {
    destination = "http.x-amz-id-2"
    type        = "cache"
    action      = "delete"
    name        = "remove x-amz-id-2"
  }
}
