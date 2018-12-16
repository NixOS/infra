resource "aws_s3_bucket" "releases" {
  bucket = "nix-releases"

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["HEAD", "GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_policy" "releases" {
  bucket = "${aws_s3_bucket.releases.id}"
  policy = "${data.aws_iam_policy_document.releases.json}"
}

data "aws_iam_policy_document" "releases" {
  statement {
    sid       = "1"
    actions   = ["s3:GetObject"]
    resources = ["${aws_s3_bucket.releases.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

resource "aws_cloudfront_distribution" "releases" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  aliases         = ["releases.nixos.org"]

  origin {
    origin_id   = "default"
    domain_name = "${aws_s3_bucket.releases.bucket_domain_name}"

    s3_origin_config {
      origin_access_identity = ""

      #origin_access_identity = "${aws_cloudfront_origin_access_identity.releases.cloudfront_access_identity_path}"
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
    cloudfront_default_certificate = false
    acm_certificate_arn            = "${aws_acm_certificate.releases.arn}"
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
}

resource "aws_acm_certificate" "releases" {
  provider          = "aws.us"
  domain_name       = "releases.nixos.org"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

/*
resource "aws_cloudfront_origin_access_identity" "releases" {
  comment = "Cloudfront identity for releases"
}
*/

