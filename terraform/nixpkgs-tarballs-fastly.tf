locals {
  tarballs_fqdn = "${aws_s3_bucket.nixpkgs-tarballs.website_endpoint}"
}

resource "fastly_service_v1" "nixpkgs-tarballs" {
  name          = "tarballs.nixos.org"
  force_destroy = true
  default_host  = "${local.tarballs_fqdn}"

  domain {
    name    = "tarballs.nixos.org"
    comment = "nixpkgs-tarballs"
  }

  /* TODO: setup papertrail logging
  papertrail {
    name = "???"
    address = "todo"
    port = "xxxx"
  }
  */

  backend {
    address           = "${local.tarballs_fqdn}"
    name              = "AWS S3 website"
    port              = 443
    use_ssl           = true
    ssl_cert_hostname = "${local.tarballs_fqdn}"
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
