# GitHub Releases Proxy Service
#
# This service provides IPv6-enabled access to GitHub releases through Fastly CDN.
# It transparently follows GitHub's S3 redirects to provide direct file access.
#
# Supported URL patterns:
# - /nix/* -> /NixOS/experimental-nix-installer/releases/download/*
# - /patchelf/* -> /NixOS/patchelf/releases/download/*
#
# Testing commands:
#
# Basic functionality tests:
# curl -I https://gh-releases.nixos.org/nix/0.27.0/nix-installer.sh
# curl -s https://gh-releases.nixos.org/nix/0.27.0/nix-installer.sh | head -n 5
#
# IPv6 connectivity test:
# curl -6 -I https://gh-releases.nixos.org/nix/0.27.0/nix-installer.sh
#
# Performance comparison (should show redirect following):
# time curl -s https://gh-releases.nixos.org/nix/0.27.0/nix-installer-x86_64-linux > /dev/null
# time curl -s https://github.com/NixOS/experimental-nix-installer/releases/download/0.27.0/nix-installer-x86_64-linux > /dev/null
#
# Error cases (should return 404):
# curl -I https://gh-releases.nixos.org/invalid/path
# curl -I https://gh-releases.nixos.org/patchelf/999.999.999/nonexistent-file

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
    request_condition     = "Use GitHub backend"
  }

  backend {
    address               = "objects.githubusercontent.com"
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 1000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "objects_githubusercontent_com"
    override_host         = "objects.githubusercontent.com"
    port                  = 443
    ssl_cert_hostname     = "objects.githubusercontent.com"
    ssl_check_cert        = true
    use_ssl               = true
    weight                = 100
    request_condition     = "Use Objects backend"
  }

  condition {
    name      = "Use GitHub backend"
    priority  = 10
    statement = "!req.http.X-Use-Objects-Backend"
    type      = "REQUEST"
  }

  condition {
    name      = "Use Objects backend"
    priority  = 10
    statement = "req.http.X-Use-Objects-Backend"
    type      = "REQUEST"
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
      # Only rewrite if this is the first request (not a restart)
      if (!req.http.X-Rewritten) {
        if (req.url ~ "^/nix/") {
          set req.url = regsub(req.url.path, "^/nix/", "/NixOS/experimental-nix-installer/releases/download/");
          set req.http.X-Rewritten = "true";
        } else if (req.url ~ "^/patchelf/") {
          set req.url = regsub(req.url.path, "^/patchelf/", "/NixOS/patchelf/releases/download/");
          set req.http.X-Rewritten = "true";
        } else {
          error 600;
        }
      }
    EOT
    name     = "GitHub releases redirect"
    priority = 100
    type     = "recv"
  }

  # Handle redirects from GitHub to S3
  snippet {
    content  = <<-EOT
      if (beresp.status == 302 && beresp.http.Location ~ "^https://objects\.githubusercontent\.com/") {
        # Extract the full path including query parameters
        set req.url = regsub(beresp.http.Location, "^https://objects\.githubusercontent\.com", "");
        set req.http.X-Use-Objects-Backend = "true";
        # Set correct host header for S3
        set req.http.Host = "objects.githubusercontent.com";
        # Clear GitHub-specific headers that might interfere
        unset req.http.Authorization;
        unset req.http.Cookie;
        restart;
      }
    EOT
    name     = "Follow GitHub redirects"
    priority = 100
    type     = "fetch"
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
  value = fastly_tls_subscription.gh_releases.managed_dns_challenges
}
