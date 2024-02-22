# Our DNS is managed by Netlify
#
# NOTES on the provider:
#
# * NETLIFY and NETLIFY6 resource types are missing because no support
# * The TTL is 3600 everywhere because the "ttl" attribute is not supported
# * The MX records both have 10 priority because no support

locals {
  # Shortcut to keep this a bit leaner
  zone_id = netlify_dns_zone.nixos.id

  dns_records = [
    {
      hostname = "bastion.nixos.org"
      type     = "A"
      value    = "34.254.208.229"
    },
    {
      hostname = "eris.nixos.org"
      type     = "A"
      value    = "138.201.32.77"
    },
    {
      hostname = "eris.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:171:33cc::1"
    },
    {
      hostname = "haumea.nixos.org"
      type     = "A"
      value    = "46.4.89.205"
    },
    {
      hostname = "haumea.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:212:41c9::1"
    },
    {
      hostname = "hydra.ngi0.nixos.org"
      type     = "A"
      value    = "116.202.113.248"
    },
    {
      hostname = "hydra.ngi0.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:231:4187::"
    },
    {
      hostname = "hydra.nixos.org"
      type     = "CNAME"
      value    = "rhea.nixos.org"
    },
    {
      hostname = "netboot.nixos.org"
      type     = "CNAME"
      value    = "pluto.nixos.org"
    },
    {
      hostname = "monitoring.nixos.org"
      type     = "A"
      value    = "138.201.32.77"
    },
    {
      hostname = "pluto.nixos.org"
      type     = "A"
      value    = "37.27.99.100"
    },
    {
      hostname = "pluto.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:3070:15e0::1"
    },
    {
      hostname = "rhea.nixos.org"
      type     = "A"
      value    = "5.9.122.43"
    },
    {
      hostname = "rhea.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:162:71eb::"
    },
    {
      hostname = "survey.nixos.org"
      type     = "A"
      value    = "54.72.253.2"
    },
    {
      hostname = "survey.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:c0c:6e2c::1"
    },
    {
      hostname = "reproducible.nixos.org"
      type     = "CNAME"
      value    = "nixos.github.io"
    },
    {
      hostname = "_293364b7f7ebb076ac287cd132f8b316.cache.ngi0.nixos.org"
      type     = "CNAME"
      value    = "_6a75cfb0c20f4eaac96b72afaffb489b.auiqqraehs.acm-validations.aws"
    },
    {
      hostname = "_acme-challenge.channels.nixos.org"
      type     = "CNAME"
      value    = "9u55qij5w2odiwqxfi.fastly-validations.com"
    },
    {
      hostname = "_acme-challenge.releases.nixos.org"
      type     = "CNAME"
      value    = "s731ezp9ameh5f349b.fastly-validations.com"
    },
    {
      hostname = "_acme-challenge.tarballs.nixos.org"
      type     = "CNAME"
      value    = "vnqm62k5sjx9jogeqg.fastly-validations.com"
    },
    {
      hostname = "cache.ngi0.nixos.org"
      type     = "CNAME"
      value    = "d2tu257wv37zz1.cloudfront.net"
    },
    {
      hostname = "cache.nixos.org"
      type     = "CNAME"
      value    = "dualstack.v2.shared.global.fastly.net"
    },
    {
      hostname = "channels.nixos.org"
      type     = "CNAME"
      value    = "dualstack.v2.shared.global.fastly.net"
    },
    {
      hostname = "chat.nixos.org"
      type     = "CNAME"
      value    = "nixos.element.io."
    },
    {
      hostname = "conf.nixos.org"
      type     = "CNAME"
      value    = "nixconberlin.github.io"
    },
    {
      hostname = "discourse.nixos.org"
      type     = "A"
      value    = "195.62.126.31"
    },
    {
      hostname = "discourse.nixos.org"
      type     = "AAAA"
      value    = "2a02:248:101:62::146f"
    },
    {
      hostname = "discourse.nixos.org"
      type     = "MX"
      value    = "mail.nixosdiscourse.fcio.net."
    },
    {
      hostname = "discourse.nixos.org"
      type     = "TXT"
      value    = "v=spf1 ip4:185.105.252.151 ip6:2a02:248:101:62::1479 ~all"
    },
    {
      hostname = "_dmarc.discourse.nixos.org"
      type     = "TXT"
      value    = "v=DMARC1; p=none"
    },
    {
      hostname = "mail._domainkey.discourse.nixos.org"
      type     = "TXT"
      value    = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDmxDhMfDl6lnueSRCjYiWIDeTAJXR9Yw0PfpBfG7GPUIkMyqy9jVGpb4ECVTt9S1zfpr4dbtCgir781oVwZiwGIWzC8y8XsD37wernQIPN4Yubnrnpw+6lill4uA/AuyU/ghbeZ5lW03pHD//2EW4YEu+Jw4aS4rF0Wtk+BlJRCwIDAQAB"
    },
    {
      hostname = "mobile.nixos.org"
      type     = "CNAME"
      value    = "nixos.github.io"
    },
    {
      hostname = "planet.nixos.org"
      type     = "CNAME"
      value    = "nixos-planet.netlify.app"
    },
    {
      hostname = "releases.nixos.org"
      type     = "CNAME"
      value    = "dualstack.v2.shared.global.fastly.net"
    },
    {
      hostname = "status.nixos.org"
      type     = "CNAME"
      value    = "nixos-status.netlify.app"
    },
    {
      hostname = "tarballs.nixos.org"
      type     = "CNAME"
      value    = "dualstack.v2.shared.global.fastly.net"
    },
    {
      hostname = "weekly.nixos.org"
      type     = "CNAME"
      value    = "nixos-weekly.netlify.com"
    },
    {
      hostname = "_github-challenge-nixos.nixos.org"
      type     = "TXT"
      value    = "9e10a04a4b"
    },
    {
      hostname = "nixos.org"
      type     = "TXT"
      value    = "v=spf1 include:spf.improvmx.com include:_mailcust.gandi.net ~all"
    },
    {
      # hetzner m1 1638981
      hostname = "intense-heron.mac.nixos.org"
      type     = "A"
      value    = "23.88.75.215"
    },
    {
      # hetzner m1 1640609
      hostname = "sweeping-filly.mac.nixos.org"
      type     = "A"
      value    = "142.132.141.35"
    },
    {
      # hetzner m1 1640635
      hostname = "maximum-snail.mac.nixos.org"
      type     = "A"
      value    = "23.88.76.161"
    },
    {
      # hetzner m1 1643080
      hostname = "growing-jennet.mac.nixos.org"
      type     = "A"
      value    = "23.88.76.75"
    },
    {
      # hetzner m1 1643228
      hostname = "enormous-catfish.mac.nixos.org"
      type     = "A"
      value    = "142.132.140.199"
    },
    {
      hostname = "20th.nixos.org"
      type     = "CNAME"
      value    = "20th-nix.pages.dev"
    },
    {
      hostname = "caliban.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:5a:186c::2"
    },
    {
      hostname = "caliban.nixos.org"
      type     = "A"
      value    = "65.109.26.213"
    },
    {
      hostname = "vault.nixos.org"
      type     = "CNAME"
      value    = "caliban.nixos.org"
    },
    {
      hostname = "nixpkgs-merge-bot.nixos.org"
      type     = "A"
      value    = "37.27.11.42"
    },
    {
      hostname = "umbriel.nixos.org"
      type     = "A"
      value    = "37.27.20.162"
    },
    {
      hostname = "umbriel.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:c011:8fb5::1"
    },
    {
      hostname = "wiki.nixos.org"
      type     = "A"
      value    = "65.21.240.250"
    },
    {
      hostname = "wiki.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:c012:8178::"
    }
  ]
}

resource "netlify_dns_zone" "nixos" {
  site_id = ""
  name    = "nixos.org"
}

resource "netlify_dns_record" "nixos" {
  for_each = { for v in local.dns_records : "${v.hostname}-${v.type}" => v }
  zone_id  = local.zone_id
  hostname = each.value.hostname
  type     = each.value.type
  value    = each.value.value
}

# MX records both have the same hostname and type and would clash on the above
# mapping.

resource "netlify_dns_record" "nixos_MX1" {
  zone_id  = local.zone_id
  hostname = "nixos.org"
  type     = "MX"
  value    = "mx1.improvmx.com"
}

resource "netlify_dns_record" "nixos_MX2" {
  zone_id  = local.zone_id
  hostname = "nixos.org"
  type     = "MX"
  value    = "mx2.improvmx.com"
}

resource "netlify_dns_record" "nixos_google_verification" {
  zone_id  = local.zone_id
  hostname = "nixos.org"
  type     = "TXT"
  value    = "google-site-verification=Pm5opvmNjJOwdb7JnuVJ_eFBPaZYWNcAavY-08AJoGc"
}
