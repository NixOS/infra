locals {
  wiki_test_domain = "test.wiki.nixos.org"
}

resource "fastly_service_vcl" "wiki-test" {
  name        = local.wiki_test_domain
  default_ttl = 86400

  backend {
    address               = "he1.wiki.nixos.org"
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "wiki_backend"
    port                  = 443
    # Shield location for Helsinki backend
    shield            = "hel-helsinki-fi"
    ssl_cert_hostname = "he1.wiki.nixos.org"
    ssl_check_cert    = true
    use_ssl           = true
    weight            = 100
  }

  domain {
    name = local.wiki_test_domain
  }

  # Pass through the original Host header
  header {
    destination = "http.Host"
    type        = "request"
    action      = "set"
    name        = "Set Host Header"
    source      = "\"wiki.nixos.org\""
  }

  logging_s3 {
    name              = "${local.wiki_test_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.wiki_test_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

resource "fastly_tls_subscription" "wiki-test" {
  domains               = [for domain in fastly_service_vcl.wiki-test.domain : domain.name]
  configuration_id      = local.fastly_tls13_quic_configuration_id
  certificate_authority = "lets-encrypt"
}

output "wiki_test_acme_challenge" {
  value       = fastly_tls_subscription.wiki-test.managed_dns_challenges
  description = "ACME challenge records for test.wiki.nixos.org - add these to DNS"
}
