locals {
  tarballs_domain = "tarballs.nixos.org"
  # Use the website endpoint because the bucket is configured with website
  # enabled. This also means we can't use TLS between Fastly and AWS because
  # the website endpoint only has port 80 open.
  tarballs_backend = "nixpkgs-tarballs.s3-website-eu-west-1.amazonaws.com"
  # TODO: Uncomment this once has been applied once. This is to work around fastly bug https://github.com/fastly/terraform-provider-fastly/issues/884
  # tarballs_backend = aws_s3_bucket_website_configuration.nixpkgs-tarballs.website_endpoint
}

resource "aws_s3_bucket" "nixpkgs-tarballs" {
  bucket = "nixpkgs-tarballs"
}

resource "aws_s3_bucket_website_configuration" "nixpkgs-tarballs" {
  bucket = aws_s3_bucket.nixpkgs-tarballs.id
  index_document {
    suffix = "index.html"
  }
}

import {
  to = aws_s3_bucket_website_configuration.nixpkgs-tarballs
  id = aws_s3_bucket.nixpkgs-tarballs.id
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
  etag         = filemd5("${path.module}/nixpkgs-tarballs/index.html")
  key          = "index.html"
  source       = "${path.module}/nixpkgs-tarballs/index.html"
}

resource "fastly_service_vcl" "nixpkgs-tarballs" {
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
    shield                = "dub-dublin-ie"
    use_ssl               = false
    weight                = 100
  }

  request_setting {
    name      = "Redirect HTTP to HTTPS"
    force_ssl = true
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

  # Allow CORS GET requests.
  header {
    destination = "http.access-control-allow-origin"
    type        = "cache"
    action      = "set"
    name        = "CORS Allow"
    source      = "\"*\""
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
    content  = "set req.url = querystring.remove(req.url);"
    name     = "Remove all query strings"
    priority = 50
    type     = "recv"
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

  logging_s3 {
    name              = "${local.tarballs_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.tarballs_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

resource "fastly_tls_subscription" "nixpkgs-tarballs" {
  domains               = [for domain in fastly_service_vcl.nixpkgs-tarballs.domain : domain.name]
  configuration_id      = local.fastly_tls12_sni_configuration_id
  certificate_authority = "globalsign"
}

# TODO: move the DNS config to terraform
output "nixpkgs-tarballs-managed_dns_challenge" {
  value = fastly_tls_subscription.nixpkgs-tarballs.managed_dns_challenges
}

# Create an S3 bucket for CloudTrail logs
resource "aws_s3_bucket" "nixpkgs-tarballs-cloudtrail-logs" {
  bucket = "nixpkgs-tarballs-cloudtrail-logs"
  # We can potentially make this public for transparency?
  # But first I want to see what the logs look like.
  acl = "private"
}

resource "aws_s3_bucket_versioning" "nixpkgs-tarballs-cloudtrail-logs" {
  bucket = aws_s3_bucket.nixpkgs-tarballs-cloudtrail-logs.id
  versioning_configuration {
    status = "Enabled"
  }
}


import {
  to = aws_s3_bucket_versioning.nixpkgs-tarballs-cloudtrail-logs
  id = aws_s3_bucket.nixpkgs-tarballs-cloudtrail-logs.id
}

# Attach a policy to the CloudTrail logs S3 bucket
data "aws_iam_policy_document" "nixpkgs-tarballs-cloudtrail-logs-policy" {
  statement {
    sid    = "AWSCloudTrailAclCheck"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:GetBucketAcl"]
    resources = [aws_s3_bucket.nixpkgs-tarballs-cloudtrail-logs.arn]
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/nixpkgs-tarballs"]
    }
  }

  statement {
    sid    = "AWSCloudTrailWrite"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["cloudtrail.amazonaws.com"]
    }

    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.nixpkgs-tarballs-cloudtrail-logs.arn}/*"]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
    condition {
      test     = "StringEquals"
      variable = "aws:SourceArn"
      values   = ["arn:${data.aws_partition.current.partition}:cloudtrail:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:trail/nixpkgs-tarballs"]
    }
  }
}

data "aws_caller_identity" "current" {}
data "aws_partition" "current" {}
data "aws_region" "current" {}

resource "aws_s3_bucket_policy" "nixpkgs-tarballs-cloudtrail-logs-policy" {
  bucket = aws_s3_bucket.nixpkgs-tarballs-cloudtrail-logs.id
  policy = data.aws_iam_policy_document.nixpkgs-tarballs-cloudtrail-logs-policy.json
}

# Create a CloudTrail
resource "aws_cloudtrail" "nixpkgs-tarballs" {
  name                       = "nixpkgs-tarballs"
  s3_bucket_name             = aws_s3_bucket.nixpkgs-tarballs-cloudtrail-logs.bucket
  enable_log_file_validation = true
  depends_on = [
    aws_s3_bucket_policy.nixpkgs-tarballs-cloudtrail-logs-policy
  ]
  # You must specify a log group and a role ARN.

  event_selector {
    read_write_type           = "WriteOnly"
    include_management_events = false

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::${aws_s3_bucket.nixpkgs-tarballs.bucket}/"]
    }
  }
}
