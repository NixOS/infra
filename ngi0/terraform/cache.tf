resource "aws_s3_bucket" "cache" {
  provider = aws
  bucket   = "ngi0-cache"

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
  provider = aws
  bucket   = aws_s3_bucket.cache.id
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cache.id}/*"
    }
  ]
}
EOF
}

resource "aws_cloudfront_distribution" "cache" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  aliases         = ["cache.ngi0.nixos.org"]

  origin {
    origin_id   = "S3-nix-cache"
    domain_name = aws_s3_bucket.cache.bucket_domain_name

    #s3_origin_config {
    #  origin_access_identity = "origin-access-identity/cloudfront/E11I84008FX6W9"
    #}
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
    acm_certificate_arn            = aws_acm_certificate.cache.arn
    ssl_support_method             = "sni-only"
  }

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }
}

resource "aws_acm_certificate" "cache" {
  provider          = aws.us
  domain_name       = "cache.ngi0.nixos.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}
