/*
resource "aws_s3_bucket" "nixpkgs-tarballs" {
  bucket = "nixpkgs-tarballs"
  region = "eu-west-1"
  acl    = "public-read"

  website {
    index_document = "index.html"
  }
}
*/

locals {
  nixpkgs-tarballs_website_domain = "nixpkgs-tarballs.s3-website-eu-west-1.amazonaws.com" # "${aws_s3_bucket.nixpkgs-tarballs.website_domain}"
  nixpkgs-tarballs_name           = "nixpkgs-tarballs"                                    # "#{aws_s3_bucket.nixpkgs-tarballs.name}"
}

resource "aws_cloudfront_distribution" "nixpkgs-tarballs" {
  enabled             = true
  is_ipv6_enabled     = true
  default_root_object = "index.html"
  price_class         = "PriceClass_All"
  aliases             = ["tarballs.nixos.org"]

  origin {
    domain_name = "${local.nixpkgs-tarballs_website_domain}"
    origin_id   = "${local.nixpkgs-tarballs_name}"
  }

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "${local.nixpkgs-tarballs_name}"
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 86400
    max_ttl                = 31536000

    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
  }

  viewer_certificate {
    cloudfront_default_certificate = true
  }
}
