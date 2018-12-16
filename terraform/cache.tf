resource "aws_s3_bucket" "cache" {
  provider = "aws.us"
  bucket   = "nix-cache"

  lifecycle_rule {
    enabled = true

    transition {
      days          = 365
      storage_class = "STANDARD_IA"
    }
  }

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "cache" {
  provider = "aws.us"
  bucket   = "${aws_s3_bucket.cache.id}"

  # imported from existing
  policy = <<EOF
{"Version":"2008-10-17","Statement":[{"Sid":"AllowPublicRead","Effect":"Allow","Principal":{"AWS":"*"},"Action":"s3:GetObject","Resource":"arn:aws:s3:::nix-cache/*"},{"Sid":"AllowUploadDebuginfoWrite","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::080433136561:user/s3-upload-releases"},"Action":["s3:PutObject","s3:PutObjectAcl"],"Resource":"arn:aws:s3:::nix-cache/debuginfo/*"},{"Sid":"AllowUploadDebuginfoRead","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::080433136561:user/s3-upload-releases"},"Action":"s3:GetObject","Resource":"arn:aws:s3:::nix-cache/*"},{"Sid":"AllowUploadDebuginfoRead2","Effect":"Allow","Principal":{"AWS":"arn:aws:iam::080433136561:user/s3-upload-releases"},"Action":["s3:ListBucket","s3:GetBucketLocation"],"Resource":"arn:aws:s3:::nix-cache"}]}
EOF
}

resource "aws_cloudfront_distribution" "cache" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  aliases         = ["cache.nixos.org"]

  origin {
    origin_id   = "S3-nix-cache"
    domain_name = "${aws_s3_bucket.cache.bucket_domain_name}"

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
    cloudfront_default_certificate = false
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
