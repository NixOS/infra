locals {
  gh_releases_domain = "gh-releases.nixos.org"
}

resource "fastly_service_vcl" "gh_releases" {
  name        = local.gh_releases_domain
  default_ttl = 3600

  backend {
    address               = "github.com"
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 1000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "github.com"
    override_host         = "github.com"
    port                  = 443
    ssl_cert_hostname     = "github.com"
    ssl_check_cert        = true
    use_ssl               = true
    weight                = 100
  }

  request_setting {
    name      = "Redirect HTTP to HTTPS"
    force_ssl = true
  }

  domain {
    name = local.gh_releases_domain
  }

  # Main VCL snippet to handle the redirect logic
  snippet {
    content  = <<-EOT
      if (req.url ~ "^/nix/") {
        set req.url = regsub(req.url.path, "^/nix/", "/NixOS/experimental-nix-installer/releases/download/");
      } else if (req.url ~ "^/patchelf/") {
        set req.url = regsub(req.url.path, "^/patchelf/", "/NixOS/patchelf/releases/download/");
      } else {
        error 600;
      }
    EOT
    name     = "GitHub releases redirect"
    priority = 100
    type     = "recv"
  }

  # Handle 404 errors
  snippet {
    content  = <<-EOT
      if (obj.status == 600) {
        set obj.status = 404;
        set obj.http.Content-Type = "text/html";
        synthetic {"<h1>Not Found</h1>"};
        return(deliver);
      }
    EOT
    name     = "Handle 404 errors"
    priority = 100
    type     = "error"
  }

  # Add HSTS header for security
  header {
    destination = "http.Strict-Transport-Security"
    type        = "response"
    action      = "set"
    name        = "Add HSTS"
    source      = "\"max-age=300\""
  }

  logging_s3 {
    name              = "${local.gh_releases_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.gh_releases_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

resource "fastly_tls_subscription" "gh_releases" {
  domains               = [for domain in fastly_service_vcl.gh_releases.domain : domain.name]
  configuration_id      = local.fastly_tls12_sni_configuration_id
  certificate_authority = "lets-encrypt"
}

output "gh-releases-managed_dns_challenge" {
  value = fastly_tls_subscription.gh_releases.managed_dns_challenge
}