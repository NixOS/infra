locals {
  cache_domain = "cache.nixos.org"

  # Origin for per-file reads under `/nix/store/`. It runs nar-serve, which reads
  # this same cache over its public interface; it holds no credentials and has
  # no write path.
  nar_serve_origin = "nar-serve.nixos.org"

  # S3 has no keys under `nix/`, so these paths do not collide with the cache.
  nar_serve_paths = "req.url.path ~ \"^/nix/store/\""

  # SHA-256 of the token of each client of per-file reads, which sends it in
  # `Authorization: Bearer <token>`. The token is in
  # `non-critical-infra/secrets/nar-serve-token-<client>.caliban`.
  nar_serve_token_sha256 = {
    nixos-search = "ac078e0f8fad13f7ecf9c5e9045c56e4e80b5721293ee34b7bd28ab2685c6c5d"
  }
}

resource "aws_s3_bucket" "cache" {
  provider = aws.us
  bucket   = "nix-cache"
}

resource "aws_s3_bucket_versioning" "cache" {
  provider = aws.us
  bucket   = aws_s3_bucket.cache.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "cache" {
  provider = aws.us
  bucket   = aws_s3_bucket.cache.id

  depends_on = [aws_s3_bucket_versioning.cache]

  transition_default_minimum_object_size = "varies_by_storage_class"

  rule {
    id     = "Infrequent Access"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 0
      storage_class = "INTELLIGENT_TIERING"
    }
  }

  # We delete no-current versions after 30 days
  rule {
    id     = "Non-current Versions"
    status = "Enabled"

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }

  # Reap multipart uploads (large NARs) that were never completed, e.g. when a
  # build aborts mid-upload. Uploads normally finish within an hour.
  rule {
    id     = "Abort incomplete multipart uploads"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

import {
  to = aws_s3_bucket_lifecycle_configuration.cache
  id = aws_s3_bucket.cache.id
}

resource "aws_s3_bucket_cors_configuration" "cache" {
  provider = aws.us
  bucket   = aws_s3_bucket.cache.id
  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

import {
  to = aws_s3_bucket_cors_configuration.cache
  id = aws_s3_bucket.cache.id
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

resource "aws_s3_bucket_request_payment_configuration" "cache" {
  provider = aws.us
  bucket   = aws_s3_bucket.cache.id
  payer    = "Requester"
}

resource "fastly_service_vcl" "cache" {
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
    shield                = "iad-va-us"
    ssl_cert_hostname     = "s3.amazonaws.com"
    ssl_check_cert        = true
    use_ssl               = true
    weight                = 100
  }

  # Per-file reads. This backend only gets `/nix/store/`; all other paths
  # continue to go to S3 with byte-identical behavior. Only the clients that
  # have the token get access, see "Require a token for per-file reads".
  #
  # `first_byte_timeout` is large because the origin must decompress the archive
  # up to the wanted file before it can send a byte. Measured over 25 store
  # paths, the median is 0.53s, but a file near the end of a 700 MB xz NAR takes
  # 19s. The 15s that S3 gets is too short for that.
  backend {
    address               = local.nar_serve_origin
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 60000
    max_conn              = 200
    name                  = "nar-serve"
    override_host         = local.nar_serve_origin
    port                  = 443
    request_condition     = "Per-file reads"
    shield                = "iad-va-us"
    ssl_cert_hostname     = local.nar_serve_origin
    ssl_check_cert        = true
    use_ssl               = true
    weight                = 100
  }

  condition {
    name      = "Per-file reads"
    priority  = 10
    statement = local.nar_serve_paths
    type      = "REQUEST"
  }

  request_setting {
    name          = "Redirect HTTP to HTTPS"
    force_ssl     = true
    max_stale_age = 0
    xff           = "append"
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
  # https://github.com/NixOS/infra/issues/212#issuecomment-1187568233
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

  # Authenticate Fastly<->S3 requests. See Fastly documentation:
  # https://docs.fastly.com/en/guides/amazon-s3#using-an-amazon-s3-private-bucket
  snippet {
    name     = "Authenticate S3 requests"
    type     = "miss"
    priority = 100
    content = templatefile("${path.module}/cache/s3-authn.vcl", {
      aws_region     = aws_s3_bucket.cache.region
      backend_domain = aws_s3_bucket.cache.bucket_domain_name
      access_key     = local.cache-iam.key
      secret_key     = local.cache-iam.secret
      # Per-file reads go to nar-serve, which needs no S3 signature.
      unsigned_paths = local.nar_serve_paths
    })
  }

  # Decompression on the origin is expensive, thus per-file reads are not open
  # to all clients. Make sure of the token before the cache lookup, because a
  # response in the cache does not keep the token of the request that put it
  # there. The header goes on to the shield and the origin, which also make
  # sure of the token. The scheme name is not case-sensitive (RFC 9110).
  snippet {
    content  = <<-EOT
      table nar_serve_clients {
      ${join(",\n", [for client, sha256 in local.nar_serve_token_sha256 : "  \"${sha256}\": \"${client}\""])}
      }
    EOT
    name     = "Clients of per-file reads"
    priority = 10
    type     = "init"
  }

  snippet {
    content  = <<-EOT
      if (${local.nar_serve_paths} && !(req.http.Authorization ~ "(?i)^bearer " && table.contains(nar_serve_clients, digest.hash_sha256(regsub(req.http.Authorization, "(?i)^bearer ", ""))))) {
        error 401 "Unauthorized";
      }
    EOT
    name     = "Require a token for per-file reads"
    priority = 40
    type     = "recv"
  }

  # A 401 must tell the client which authentication scheme to use (RFC 9110).
  snippet {
    content  = <<-EOT
      if (obj.status == 401 && ${local.nar_serve_paths}) {
        set obj.http.WWW-Authenticate = "Bearer";
      }
    EOT
    name     = "Bearer scheme for per-file reads"
    priority = 10
    type     = "error"
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

  logging_s3 {
    name              = "${local.cache_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.cache_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

resource "fastly_tls_subscription" "cache-2025-11" {
  domains               = [for domain in fastly_service_vcl.cache.domain : domain.name]
  configuration_id      = local.fastly_tls13_quic_configuration_id
  certificate_authority = "lets-encrypt"
}

output "cache-managed_dns_challenge" {
  value = fastly_tls_subscription.cache-2025-11.managed_dns_challenges
}
