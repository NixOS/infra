locals {
  cache_domain = "cache.nixos.org"
}

resource "aws_s3_bucket" "cache" {
  provider = aws.us
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

resource "aws_s3_bucket_object" "cache-nix-cache-info" {
  provider = aws.us

  acl          = "public-read"
  bucket       = aws_s3_bucket.cache.bucket
  content_type = "text/x-nix-cache-info"
  etag         = filemd5("${path.module}/cache/nix-cache-info")
  key          = "nix-cache-info"
  source       = "${path.module}/cache/nix-cache-info"
}

resource "aws_s3_bucket_object" "cache-index-html" {
  provider = aws.us

  acl          = "public-read"
  bucket       = aws_s3_bucket.cache.bucket
  content_type = "text/html"
  etag         = filemd5("${path.module}/cache/index.html")
  key          = "index.html"
  source       = "${path.module}/cache/index.html"
}

resource "aws_s3_bucket_policy" "cache" {
  provider = aws.us
  bucket   = aws_s3_bucket.cache.id

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
      "Resource": "arn:aws:s3:::nix-cache/*"
    },
    {
      "Sid": "AllowUploadDebuginfoWrite",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-releases"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nix-cache/debuginfo/*"
    },
    {
      "Sid": "AllowUploadDebuginfoRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-releases"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::nix-cache/*"
    },
    {
      "Sid": "AllowUploadDebuginfoRead2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-releases"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::nix-cache"
    }
  ]
}
EOF
}

resource "fastly_service_v1" "cache" {
  name        = local.cache_domain
  default_ttl = 86400

  backend {
    address               = "s3.amazonaws.com"
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "s3.amazonaws.com"
    override_host         = aws_s3_bucket.cache.bucket_domain_name
    port                  = 443
    shield                = local.fastly_shield
    ssl_cert_hostname     = "s3.amazonaws.com"
    ssl_check_cert        = true
    use_ssl               = true
    weight                = 100
  }

  condition {
    name      = "is-404"
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
    name = "cache.nixos.org"
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

  # Enable Streaming Miss.
  # https://docs.fastly.com/en/guides/streaming-miss
  # https://github.com/NixOS/nixos-org-configurations/issues/212#issuecomment-1187568233
  header {
    priority    = 20
    destination = "do_stream"
    type        = "cache"
    action      = "set"
    name        = "Enabling Streaming Miss"
    source      = "true"
  }

  # Allow CORS GET requests.
  header {
    destination = "http.access-control-allow-origin"
    type        = "response"
    action      = "set"
    name        = "CORS Allow"
    source      = "\"*\""
  }

  response_object {
    name            = "404-page"
    cache_condition = "is-404"
    content         = "404"
    content_type    = "text/plain"
    response        = "Not Found"
    status          = 404
  }

  snippet {
    content  = "set req.url = querystring.remove(req.url);"
    name     = "Remove all query strings"
    priority = 50
    type     = "recv"
  }

  # Work around the 2GB size limit for large files
  #
  # See https://docs.fastly.com/en/guides/segmented-caching
  snippet {
    content  = <<-EOT
      if (req.url.path ~ "^/nar/") {
        set req.enable_segmented_caching = true;
      }
    EOT
    name     = "Enable segment caching for NAR files"
    priority = 60
    type     = "recv"
  }

  snippet {
    name     = "cache-errors"
    content  = <<-EOT
      if (beresp.status == 403) {
        set beresp.status = 404;
      }
    EOT
    priority = 100
    type     = "fetch"
  }

  s3logging {
    name              = "${local.cache_domain}-to-s3"
    bucket_name       = module.fastlylogs.bucket_name
    compression_codec = "zstd"
    domain            = module.fastlylogs.s3_domain
    format            = module.fastlylogs.format
    format_version    = 2
    path              = "${local.cache_domain}/"
    period            = module.fastlylogs.period
    message_type      = "blank"
    s3_iam_role       = module.fastlylogs.iam_role_arn
  }
}

resource "fastly_tls_subscription" "cache" {
  domains               = [for domain in fastly_service_v1.cache.domain : domain.name]
  configuration_id      = local.fastly_tls12_sni_configuration_id
  certificate_authority = "globalsign"
}
