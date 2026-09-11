locals {
  wiki_domain = "wiki.nixos.org"
  # must match services.nixos-wiki.fastly.originHostname in nixos-wiki-infra
  wiki_origin = "he1.wiki.nixos.org"
}

resource "fastly_service_vcl" "wiki" {
  name        = local.wiki_domain
  default_ttl = 0

  backend {
    address               = local.wiki_origin
    auto_loadbalance      = false
    between_bytes_timeout = 10000
    connect_timeout       = 5000
    error_threshold       = 0
    first_byte_timeout    = 15000
    max_conn              = 200
    name                  = "wiki_backend"
    port                  = 443
    shield                = "hel-helsinki-fi"
    override_host         = local.wiki_domain
    ssl_cert_hostname     = local.wiki_origin
    ssl_sni_hostname      = local.wiki_origin
    ssl_check_cert        = true
    use_ssl               = true
    weight                = 100
  }

  domain {
    name = local.wiki_domain
  }

  # canary
  domain {
    name = "test.${local.wiki_domain}"
  }

  snippet {
    name    = "recv"
    type    = "recv"
    content = <<-EOT
      # Trusted by the origin as client address; only the first hop may set it.
      if (fastly.ff.visits_this_service == 0) {
        set req.http.Fastly-Client-IP = client.ip;
      }

      if (req.url.path ~ "^/\.well-known/acme-challenge/") {
        return(pass);
      }

      # Sessions bypass the cache, all other cookies are irrelevant to MediaWiki.
      if (req.http.Cookie ~ "([sS]ession|Token|UserID|UserName)=") {
        return(pass);
      }
      unset req.http.Cookie;

      # MobileFrontend varies HTML by User-Agent; same regex as the origin nginx.
      if (req.http.User-Agent ~ "(?i)(mobi|240x240|240x320|320x320|alcatel|android|audiovox|bada|benq|blackberry|cdm-|compal-|docomo|ericsson|hiptop|htc[-_]|huawei|ipod|kddi-|kindle|meego|midp|mitsu|mmp/|mot-|motor|ngm_|nintendo|opera.m|palm|panasonic|philips|phone|playstation|portalmmm|sagem-|samsung-|sanyo|sec-|semc-browser|sendo|sharp|silk|softbank|symbian|teleca|up.browser|vodafone|webos)") {
        set req.http.X-Device = "mobile";
      } else {
        set req.http.X-Device = "desktop";
      }
    EOT
  }

  snippet {
    name    = "fetch"
    type    = "fetch"
    content = <<-EOT
      # Vary on X-Device instead of Cookie/User-Agent (also undoes vcl_deliver of a shield).
      if (beresp.http.Vary) {
        set beresp.http.Vary = regsuball(beresp.http.Vary, "(?i)(^|,\s*)(Cookie|User-Agent|X-Device)(?=,|$)", "");
        set beresp.http.Vary = regsub(beresp.http.Vary, "^[,\s]+", "");
      }
      if (beresp.http.Content-Type ~ "^text/html") {
        set beresp.http.Vary = if(beresp.http.Vary, beresp.http.Vary ", X-Device", "X-Device");
      }
    EOT
  }

  snippet {
    name    = "deliver"
    type    = "deliver"
    content = <<-EOT
      if (resp.http.Vary ~ "X-Device") {
        set resp.http.Vary = regsuball(resp.http.Vary, "X-Device", "Cookie, User-Agent");
      }
    EOT
  }

  logging_s3 {
    name              = "${local.wiki_domain}-to-s3"
    bucket_name       = local.fastlylogs["bucket_name"]
    compression_codec = "zstd"
    domain            = local.fastlylogs["s3_domain"]
    format            = local.fastlylogs["format"]
    format_version    = 2
    path              = "${local.wiki_domain}/"
    period            = local.fastlylogs["period"]
    message_type      = "blank"
    s3_iam_role       = local.fastlylogs["iam_role_arn"]
  }
}

moved {
  from = fastly_service_vcl.wiki-test
  to   = fastly_service_vcl.wiki
}

resource "fastly_tls_subscription" "wiki" {
  domains               = [local.wiki_domain]
  configuration_id      = local.fastly_tls13_quic_configuration_id
  certificate_authority = "lets-encrypt"
}

resource "fastly_tls_subscription" "wiki-test" {
  domains               = ["test.${local.wiki_domain}"]
  configuration_id      = local.fastly_tls13_quic_configuration_id
  certificate_authority = "lets-encrypt"
  depends_on            = [fastly_service_vcl.wiki]
}

output "wiki_acme_challenge" {
  value       = fastly_tls_subscription.wiki.managed_dns_challenges
  description = "ACME challenge records for wiki.nixos.org - add these to DNS"
}
