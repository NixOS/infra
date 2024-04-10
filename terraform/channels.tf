locals {
  channels_domain = "channels.nixos.org"

  channels_index = templatefile("${path.module}/s3_listing.html.tpl", {
    bucket_name    = aws_s3_bucket.channels.bucket
    bucket_url     = "https://${aws_s3_bucket.channels.bucket_domain_name}"
    bucket_website = "https://${local.channels_domain}"
  })

  # Use the website endpoint because the bucket is configured with website
  # enabled. This also means we can't use TLS between Fastly and AWS because
  # the website endpoint only has port 80 open.
  channels_backend = aws_s3_bucket.channels.website_endpoint
}

resource "aws_s3_bucket" "channels" {
  provider = aws.us
  bucket   = "nix-channels"

  website {
    index_document = "index.html"
  }

  cors_rule {
    allowed_headers = ["*"]
    allowed_methods = ["HEAD", "GET"]
    allowed_origins = ["*"]
    expose_headers  = ["ETag"]
    max_age_seconds = 3600
  }
}

resource "aws_s3_bucket_object" "channels-index-html" {
  provider = aws.us

  acl          = "public-read"
  bucket       = aws_s3_bucket.channels.bucket
  content_type = "text/html"
  etag         = md5(local.channels_index)
  key          = "index.html"
  content      = local.channels_index
}

resource "aws_s3_bucket_policy" "channels" {
  provider = aws.us
  bucket   = aws_s3_bucket.channels.id
  policy   = <<EOF
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
      "Resource": "arn:aws:s3:::nix-channels/*"
    },
    {
      "Sid": "AllowPublicList",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::nix-channels"
    },
    {
      "Sid": "AllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::080433136561:user/s3-upload-releases",
          "arn:aws:iam::065343343465:user/nixos-s3-upload-releases"
        ]
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nix-channels/*"
    }
  ]
}
EOF
}

resource "fastly_service_vcl" "channels" {
  name        = local.channels_domain
  default_ttl = 3600

  backend {
    address           = local.channels_backend
    auto_loadbalance  = false
    connect_timeout   = 5000
    name              = local.channels_backend
    override_host     = local.channels_backend
    request_condition = "not-flake-registry"
    shield            = "iad-va-us"
  }

  backend {
    # https://github.com/NixOS/flake-registry/raw/master/flake-registry.json
    name              = "flake-registry"
    address           = "raw.githubusercontent.com"
    auto_loadbalance  = false
    override_host     = "raw.githubusercontent.com"
    port              = 443
    use_ssl           = true
    ssl_check_cert    = false
    request_condition = "flake-registry"
  }

  condition {
    name      = "Match /"
    priority  = 10
    statement = "req.url ~ \"^/$\""
    type      = "REQUEST"
  }

  condition {
    name      = "not-flake-registry"
    statement = "req.url != \"/NixOS/flake-registry/master/flake-registry.json\""
    type      = "REQUEST"
  }

  condition {
    name      = "flake-registry"
    statement = "req.url == \"/NixOS/flake-registry/master/flake-registry.json\""
    type      = "REQUEST"
  }

  domain {
    name = local.channels_domain
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
      if (req.url ~ "/flake-registry.json") {
        set beresp.stale_if_error = 1000000s;
      }
    EOT
    name     = "Change 403 from S3 to 404"
    priority = 100
    type     = "fetch"
  }

  snippet {
    name    = "flake-registry"
    content = <<-EOT
      if (req.url == "/flake-registry.json") {
        set req.url = "/NixOS/flake-registry/master/flake-registry.json";
      }
    EOT
    type    = "recv"
  }

  snippet {
    content = <<-EOT
      # S3 object-level redirects can only be 301s. We use them to point
      # "latest" versions of various channel/release artifacts to the correct
      # location. First, mark these redirects as temporary. Second, disable
      # caching, since some of the artifacts need to have matching versions
      # (e.g. a .iso and its checksum), which is near-impossible to guarantee
      # with caching unless we explicitly perform invalidations.
      #
      # Note: we need to match on 301s and 302s here, since Fastly has multiple
      # layers, and otherwise a redirect might still get cached at the second
      # layer after the first layer turned a 301 into a 302.
      if (beresp.status == 301 || beresp.status == 302) {
        set beresp.status = 302;
        set beresp.ttl = 0s;
        set beresp.grace = 0s;
        set beresp.cacheable = false;
        return (pass);
      }
    EOT
    name    = "Change 301 from S3 to 302"
    # Keep close to last, since it conditionally returns.
    priority = 999
    type     = "fetch"
  }

  logging_s3 {
    name              = "${local.channels_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.channels_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

resource "fastly_tls_subscription" "channels" {
  domains               = [for domain in fastly_service_vcl.channels.domain : domain.name]
  configuration_id      = local.fastly_tls12_sni_configuration_id
  certificate_authority = "globalsign"
}

# TODO: move the DNS config to terraform
output "channels-managed_dns_challenge" {
  value = fastly_tls_subscription.channels.managed_dns_challenge
}
