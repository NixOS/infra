resource "aws_cloudfront_distribution" "cache" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  aliases         = ["cache.nixos.org"]

  origin {
    origin_id   = "S3-nix-cache"
    domain_name = "nix-cache.s3.amazonaws.com"

    s3_origin_config {
      origin_access_identity = "origin-access-identity/cloudfront/E11I84008FX6W9"
    }
  }

  default_cache_behavior {
    allowed_methods        = ["HEAD", "GET"]
    cached_methods         = ["HEAD", "GET"]
    target_origin_id       = "S3-nix-cache"
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
    acm_certificate_arn            = "${aws_acm_certificate.cache.arn}"
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  logging_config {
    bucket = "nix-cache-logs.s3.amazonaws.com"
  }

  custom_error_response {
    error_code            = 403
    response_page_path    = "/error-pages/404"
    response_code         = 404
    error_caching_min_ttl = 600
  }

  custom_error_response {
    error_code            = 500
    error_caching_min_ttl = 10
  }

  default_root_object = "index.html"
}

resource "aws_acm_certificate" "cache" {
  provider          = "aws.us"
  domain_name       = "cache.nixos.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
