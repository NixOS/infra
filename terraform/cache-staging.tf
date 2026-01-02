locals {
  cache_staging_domain = "cache-staging.nixos.org"
}

# This is the old bucket we want to archive.
module "cache-staging-202010" {
  source      = "./cache-bucket"
  bucket_name = "nix-cache-staging"
  providers = {
    aws = aws.us
  }
}

import {
  to = module.cache-staging-202010.aws_s3_bucket_lifecycle_configuration.cache
  id = "nix-cache-staging"
}

import {
  to = module.cache-staging-202010.aws_s3_bucket_cors_configuration.cache
  id = "nix-cache-staging"
}


# This is the new bucket we want to use in future.
module "cache-staging-202410" {
  source      = "./cache-bucket"
  bucket_name = "nix-cache-staging-202410"
  providers = {
    # move the new bucket to EU
    aws = aws
  }
}

import {
  to = module.cache-staging-202410.aws_s3_bucket_lifecycle_configuration.cache
  id = "nix-cache-staging-202410"
}

import {
  to = module.cache-staging-202410.aws_s3_bucket_cors_configuration.cache
  id = "nix-cache-staging-202410"
}

# The fastly configuration below will first try the new bucket and than the old bucket.
# As demonstation we have two files in the buckets:
# $ curl https://cache-staging.nixos.org/new-cache                                                                                                                                                               │
# new
# $ curl https://cache-staging.nixos.org/old-cache
# old

resource "aws_s3_object" "old-cache-test-file" {
  provider   = aws.us
  depends_on = [module.cache-staging-202010]

  bucket       = module.cache-staging-202010.bucket
  content_type = "text/plain"
  etag         = filemd5("${path.module}/cache-staging/old-cache-test-file")
  key          = "old-cache"
  source       = "${path.module}/cache-staging/old-cache-test-file"
}
resource "aws_s3_object" "new-cache-test-file" {
  provider   = aws
  depends_on = [module.cache-staging-202410]

  bucket       = module.cache-staging-202410.bucket
  content_type = "text/plain"
  etag         = filemd5("${path.module}/cache-staging/new-cache-test-file")
  key          = "new-cache"
  source       = "${path.module}/cache-staging/new-cache-test-file"
}

resource "fastly_service_vcl" "cache-staging" {
  name        = local.cache_staging_domain
  default_ttl = 86400

  backend {
    address               = module.cache-staging-202010.bucket_regional_domain_name
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "old_bucket"
    port                  = 443
    # For the old bucket we want to use Ashburn as our bucket is in us-east-1
    shield            = "iad-va-us"
    ssl_cert_hostname = module.cache-staging-202010.bucket_regional_domain_name
    ssl_check_cert    = true
    use_ssl           = true
    weight            = 100
  }

  backend {
    address               = module.cache-staging-202410.bucket_regional_domain_name
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "new_bucket"
    port                  = 443
    # The new bucket is in EU (eu-west-1)
    shield            = "dub-dublin-ie"
    ssl_cert_hostname = module.cache-staging-202410.bucket_regional_domain_name
    ssl_check_cert    = true
    use_ssl           = true

    # newer bucket has higher priority
    weight = 200
  }

  # Temporarily disabled due to nix-index bugs: see https://github.com/nix-community/nix-index/issues/249
  #request_setting {
  #  name      = "Redirect HTTP to HTTPS"
  #  force_ssl = true
  #}

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

  condition {
    name      = "Restarts > 0"
    type      = "REQUEST"
    priority  = 20
    statement = "req.restarts > 0"
  }

  domain {
    name = "cache-staging.nixos.org"
  }

  header {
    name              = "Landing page"
    request_condition = "Match /"
    ignore_if_set     = false
    priority          = 10
    type              = "request"

    action      = "set"
    destination = "url"
    source      = "\"/index.html\""

  }

  header {
    name              = "Use old bucket"
    request_condition = "Restarts > 0"
    ignore_if_set     = false
    priority          = 20
    type              = "request"

    action      = "set"
    destination = "backend"
    source      = "F_old_bucket"
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

  snippet {
    name     = "Variables for aws s3 auth"
    type     = "miss"
    priority = 90
    content  = <<-EOT
declare local var.awsAccessKey STRING;
declare local var.awsSecretKey STRING;
declare local var.awsS3Bucket STRING;
declare local var.awsRegion STRING;
declare local var.awsS3Host STRING;

declare local var.canonicalHeaders STRING;
declare local var.signedHeaders STRING;
declare local var.canonicalRequest STRING;
declare local var.canonicalQuery STRING;
declare local var.stringToSign STRING;
declare local var.dateStamp STRING;
declare local var.signature STRING;
declare local var.scope STRING;
EOT
  }

  # Authenticate Fastly<->S3 requests. See Fastly documentation:
  # https://docs.fastly.com/en/guides/amazon-s3#using-an-amazon-s3-private-bucket
  snippet {
    name     = "Authenticate S3 requests for new bucket"
    type     = "miss"
    priority = 100
    content = templatefile("${path.module}/cache-staging/s3-authn.vcl", {
      backend_name   = "F_new_bucket"
      aws_region     = module.cache-staging-202410.region
      bucket         = module.cache-staging-202410.bucket
      backend_domain = module.cache-staging-202410.bucket_domain_name
      access_key     = local.cache-iam.key
      secret_key     = local.cache-iam.secret
    })
  }

  snippet {
    name     = "Authenticate S3 requests for old bucket"
    type     = "miss"
    priority = 100
    content = templatefile("${path.module}/cache-staging/s3-authn.vcl", {
      backend_name   = "F_old_bucket"
      aws_region     = module.cache-staging-202010.region
      bucket         = module.cache-staging-202010.bucket
      backend_domain = module.cache-staging-202010.bucket_domain_name
      access_key     = local.cache-iam.key
      secret_key     = local.cache-iam.secret
    })
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
    name     = "Fallback to old bucket on 403 or return 404"
    type     = "fetch"
    priority = 90
    content  = <<-EOT
      if (beresp.status == 403) {
         if (req.backend == F_new_bucket) {
           restart;
         } else {
           set beresp.status = 404;
         }
      }
    EOT
  }

  # We will switch to this snipped once we retire the old bucket instead of the fallback above
  #snippet {
  #  name     = "Return 404 on 403"
  #  type     = "fetch"
  #  priority = 90
  #  content  = <<-EOT
  #    if (beresp.status == 403) {
  #      set beresp.status = 404;
  #    }
  #  EOT
  #}

  # Add a snippet to set a custom header based on the backend used
  snippet {
    name     = "Set-Backend-Header"
    type     = "deliver"
    priority = 70
    content  = <<-EOT
      if (req.backend == F_old_bucket) {
        set resp.http.X-Bucket = "${module.cache-staging-202010.bucket}";
      } else if (req.backend == F_new_bucket) {
        set resp.http.X-Bucket = "${module.cache-staging-202410.bucket}";
      }
    EOT
  }

  logging_s3 {
    name              = "${local.cache_staging_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.cache_staging_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

resource "fastly_tls_subscription" "cache-staging-2025-11" {
  domains               = [for domain in fastly_service_vcl.cache-staging.domain : domain.name]
  configuration_id      = local.fastly_tls13_quic_configuration_id
  certificate_authority = "lets-encrypt"
}
