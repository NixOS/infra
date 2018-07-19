resource "aws_cloudfront_distribution" "nixpkgs-tarballs" {
  enabled             = true
  is_ipv6_enabled     = true
  price_class         = "PriceClass_All"
  aliases             = ["tarballs.nixos.org"]

  # Urgh, can't use an S3 origin because it's configured as a website
  # (to serve HTTP redirects).
  /*
  origin {
    origin_id   = "default"
    domain_name = "nixpkgs-tarballs.s3-eu-west-1.amazonaws.com"
    s3_origin_config {
      origin_access_identity = "${aws_cloudfront_origin_access_identity.nixpkgs-tarballs-identity.cloudfront_access_identity_path}"
    }
  }
  */

  origin {
    origin_id   = "default"
    domain_name = "nixpkgs-tarballs.s3-website-eu-west-1.amazonaws.com"
    custom_origin_config {
      http_port = 80
      https_port = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols = ["TLSv1.2"]
    }
  }

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "default"
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
    acm_certificate_arn = "${aws_acm_certificate.nixpkgs-tarballs.arn}"
    ssl_support_method = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket = "nix-cache-logs.s3.amazonaws.com"
  }
}

resource "aws_acm_certificate" "nixpkgs-tarballs" {
  provider = "aws.us"
  domain_name       = "tarballs.nixos.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_cloudfront_origin_access_identity" "nixpkgs-tarballs" {
  comment = "Cloudfront identity for nixpkgs-tarballs"
}
*/