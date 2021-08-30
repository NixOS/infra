resource "aws_s3_bucket" "nixpkgs-tarballs" {
  bucket = "nixpkgs-tarballs"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "nixpkgs-tarballs" {
  bucket = aws_s3_bucket.nixpkgs-tarballs.id

  # imported from existing
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
      "Resource": "arn:aws:s3:::nixpkgs-tarballs/*"
    },
    {
      "Sid": "AllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-tarballs"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nixpkgs-tarballs/*"
    },
    {
      "Sid": "AllowUpload2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-tarballs"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::nixpkgs-tarballs"
    },
    {
      "Sid": "CopumpkinAllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::390897850978:root"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nixpkgs-tarballs/*"
    },
    {
      "Sid": "CopumpkinAllowUpload2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::390897850978:root"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::nixpkgs-tarballs"
    },
    {
      "Sid": "ShlevyAllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::976576280863:user/shlevy"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nixpkgs-tarballs/*"
    },
    {
      "Sid": "ShlevyAllowUpload2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::976576280863:user/shlevy"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::nixpkgs-tarballs"
    },
    {
      "Sid": "DaiderdAllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::014292808257:user/lnl7"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nixpkgs-tarballs/*"
    },
    {
      "Sid": "DaiderdAllowUpload2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::014292808257:user/lnl7"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::nixpkgs-tarballs"
    },
    {
      "Sid": "LovesegfaultAllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::839273551904:root"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nixpkgs-tarballs/*"
    },
    {
      "Sid": "LovesegfaultAllowUpload2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::839273551904:root"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::nixpkgs-tarballs"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_object" "nixpkgs-tarballs-index" {
  bucket       = aws_s3_bucket.nixpkgs-tarballs.id
  content_type = "text/html"
  etag         = md5(file("${path.module}/nixpkgs-tarballs/index.html"))
  key          = "index.html"
  source       = "${path.module}/nixpkgs-tarballs/index.html"
}

resource "aws_cloudfront_distribution" "nixpkgs-tarballs" {
  enabled         = true
  is_ipv6_enabled = true
  price_class     = "PriceClass_All"
  aliases         = ["tarballs.nixos.org"]

  # Urgh, can't use an S3 origin because it's configured as a website
  # (to serve HTTP redirects).
  /*
  origin {
    origin_id   = "default"
    domain_name = "nixpkgs-tarballs.s3-eu-west-1.amazonaws.com"
    s3_origin_config {
      origin_access_identity = aws_cloudfront_origin_access_identity.nixpkgs-tarballs-identity.cloudfront_access_identity_path
    }
  }
  */

  origin {
    origin_id   = "default"
    domain_name = "nixpkgs-tarballs.s3-website-eu-west-1.amazonaws.com"

    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
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
    acm_certificate_arn            = aws_acm_certificate.nixpkgs-tarballs.arn
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

resource "aws_acm_certificate" "nixpkgs-tarballs" {
  provider          = aws.us
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

locals {
  tarballs_domain = "tarballs.nixos.org"
  # Use the website endpoint because the bucket is configured with website
  # enabled. This also means we can't use TLS between Fastly and AWS because
  # the website endpoint only has port 80 open.
  tarballs_backend = aws_s3_bucket.nixpkgs-tarballs.website_endpoint
}

resource "fastly_service_v1" "nixpkgs-tarballs" {
  name        = local.tarballs_domain
  default_ttl = 86400

  backend {
    address               = local.tarballs_backend
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = local.tarballs_backend
    override_host         = local.tarballs_backend
    port                  = 80
    shield                = "bwi-va-us"
    use_ssl               = false
    weight                = 100
  }

  condition {
    name      = "Generated by synthetic response for 404 page"
    priority  = 0
    statement = "beresp.status == 404"
    type      = "CACHE"
  }

  condition {
    name      = "Match /"
    priority  = 10
    statement = "req.url ~ \"^/$\""
    type      = "REQUEST"
  }

  domain {
    name = local.tarballs_domain
  }

  header {
    action            = "set"
    destination       = "url"
    ignore_if_set     = false
    name              = "Landing page"
    priority          = 10
    request_condition = "Match /"
    source            = "\"/index.html\""
    type              = "request"
  }

  response_object {
    cache_condition = "Generated by synthetic response for 404 page"
    content         = "404"
    content_type    = "text/html"
    name            = "Generated by synthetic response for 404 page"
    response        = "Not Found"
    status          = 404
  }

  snippet {
    content  = <<-EOT
      if (beresp.status == 403) {
        set beresp.status = 404;
        set beresp.ttl = 86400s;
        set beresp.grace = 0s;
        set beresp.cacheable = true;
      }
    EOT
    name     = "Change 403 from S3 to 404"
    priority = 100
    type     = "fetch"
  }
}
