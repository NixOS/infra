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
      hostname = "makemake.ngi.nixos.org"
      type     = "A"
      value    = "116.202.113.248"
    },
    {
      hostname = "makemake.ngi.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:231:4187::"
    },
    {
      hostname = "buildbot.ngi.nixos.org"
      type     = "CNAME"
      value    = "makemake.ngi.nixos.org"
    },
    {
      hostname = "hydra.ngi0.nixos.org"
      type     = "CNAME"
      value    = "makemake.ngi.nixos.org"
    },
    {
      hostname = "summer.nixos.org"
      type     = "CNAME"
      value    = "makemake.ngi.nixos.org"
    },
    {
      hostname = "ngi.nixos.org"
      type     = "CNAME"
      value    = "ngi-nix.github.io"
    },
    {
      hostname = "hydra.nixos.org"
      type     = "CNAME"
      value    = "mimas.nixos.org"
    },
    {
      hostname = "monitoring.nixos.org"
      type     = "CNAME"
      value    = "pluto.nixos.org"
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
      hostname = "alerts.nixos.org"
      type     = "CNAME"
      value    = "pluto.nixos.org"
    },
    {
      hostname = "prometheus.nixos.org"
      type     = "CNAME"
      value    = "pluto.nixos.org"
    },
    {
      hostname = "grafana.nixos.org"
      type     = "CNAME"
      value    = "pluto.nixos.org"
    },
    {
      hostname = "mimas.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:2220:11c8::1"
    },
    {
      hostname = "mimas.nixos.org"
      type     = "A"
      value    = "157.90.104.34"
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
      hostname = "cache-staging.nixos.org"
      type     = "CNAME"
      value    = "dualstack.v2.shared.global.fastly.net"
    },
    {
      hostname = "channels.nixos.org"
      type     = "CNAME"
      value    = "dualstack.v2.shared.global.fastly.net"
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
      # hetzner ax162-r 2548595
      hostname = "elated-minsky.builder.nixos.org"
      type     = "A"
      value    = "167.235.95.99"
    },
    {
      hostname = "elated-minsky.builder.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:2220:1b03::1"
    },
    {
      # hetzner ax162-r 2566166
      hostname = "sleepy-brown.builder.nixos.org"
      type     = "A"
      value    = "162.55.130.51"
    },
    {
      hostname = "sleepy-brown.builder.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:271:5c14::1"
    },
    {
      hostname = "goofy-hopcroft.builder.nixos.org"
      type     = "A"
      value    = "135.181.225.104"
    },
    {
      hostname = "goofy-hopcroft.builder.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:3071:2d8b::1"
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

    # oakhost m2
    {
      hostname = "eager-heisenberg.mac.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:d1:a027::2"
    },

    # oakhost m2
    {
      hostname = "kind-lumiere.mac.nixos.org"
      type     = "AAAA"
      value    = "2a09:9340:808:60a::1"
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
      hostname = "chat.nixos.org"
      type     = "CNAME"
      value    = "caliban.nixos.org."
    },
    {
      hostname = "live.nixos.org"
      type     = "CNAME"
      value    = "caliban.nixos.org."
    },
    {
      hostname = "matrix.nixos.org"
      type     = "CNAME"
      value    = "caliban.nixos.org."
    },
    {
      hostname = "vault.nixos.org"
      type     = "CNAME"
      value    = "caliban.nixos.org"
    },
    {
      hostname = "tracker.security.nixos.org"
      type     = "A"
      value    = "188.245.41.195"
    },
    {
      hostname = "tracker.security.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:1c1b:b87b::1"
    },
    {
      hostname = "caliban.nixos.org"
      type     = "TXT"
      value    = "v=spf1 ip4:65.109.26.213 ip6:2a01:4f9:5a:186c::2 ~all"
    },
    {
      hostname = "mail._domainkey.caliban.nixos.org"
      type     = "TXT"
      value    = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDCLtvNH4Ly+9COXf7InptMvoA7I5O347D7+j+saECt7RRe8yNz4TmhJTyJik+bg7e3+l7EJM0vE6k7xtpGBXACY6CCmg/8EgUi6YnDd126ttJHWpoqO96w4SWX93G+ZnoSC8O5rTPqdaTTkntYDTrw5u5n+7RA8GarZadgmaEzwIDAQAB"
    },
    {
      hostname = "_dmarc.caliban.nixos.org"
      type     = "TXT"
      value    = "v=DMARC1; p=none"
    },
    {
      hostname = "survey.nixos.org"
      type     = "CNAME"
      value    = "caliban.nixos.org"
    },
    {
      hostname = "nixpkgs-merge-bot.nixos.org"
      type     = "A"
      value    = "37.27.11.42"
    },
    {
      hostname = "nixpkgs-merge-bot.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:c012:7615::1"
    },
    # nixpkgs-merge-bot-staging.nixos.org is currently hosted by helsinki systems
    {
      hostname = "nixpkgs-merge-bot-staging.nixos.org"
      type     = "A"
      value    = "37.27.197.11"
    },
    {
      hostname = "nixpkgs-merge-bot-staging.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:c010:dd30::1"
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
      type     = "TXT"
      value    = "v=spf1 ip4:65.21.240.250 ip6:2a01:4f9:c012:8178:: ~all"
    },
    {
      hostname = "mail._domainkey.wiki.nixos.org"
      type     = "TXT"
      value    = "v=DKIM1; k=rsa; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDa+KjIljYr3q5MWWK7sEYzjR8OcA32zBh9BCPo6/HlY1q2ODTYsmE/FDZWpYMzM5z+ddnuGYdXia322XnZaNpZNoq1TbGYuQ5DsgAEK09CGoLuzONg3PSXTrkG7E2Sd6wstwHGJ5FHxSLKtNoWkknt9F5XAFZgXapO0w54p+BWvwIDAQAB"
    },
    {
      hostname = "_dmarc.wiki.nixos.org"
      type     = "TXT"
      value    = "v=DMARC1; p=none"
    },
    {
      hostname = "wiki.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f9:c012:8178::"
    },

    # Mailserver configuration for `nixos.org`
    # TODO: remove the 2 MX records for improvmx below in favor of this once
    # we're ready to switch to the new mailserver:
    # https://github.com/NixOS/infra/issues/485
    # {
    #   hostname = "nixos.org"
    #   type     = "MX"
    #   value    = "umbriel.nixos.org"
    # },
    {
      hostname = "nixos.org"
      type     = "TXT"
      # TODO: simplify to just a `mx` rule once umbriel is our one and only
      # mailserver:
      # https://github.com/NixOS/infra/issues/485
      # value = "v=spf1 mx ~all"
      value = "v=spf1 include:spf.improvmx.com a:umbriel.nixos.org ~all"
    },
    {
      hostname = "mail._domainkey.nixos.org"
      type     = "TXT"
      # See `nixos.org.mail.key` in `non-critical-infra/modules/mailserver/default.nix`.
      value = "v=DKIM1; p=MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDcgNq4+Y23GxN8Mdza437tL5DuJJZU1y6VzTCwSi6cBNLyBDci2cmqXx/gm1sA3yv7+h+8/OyJpEgcbCIW/Ygs1XLuECqvXVX8MU6Djn4KY+d2sU1tlUdqvNM86puoneQtjEv9rDsjf3HGqaeOcjetFnQW7H+qcNcaEShxyKztzQIDAQAB"
    },
    {
      hostname = "_dmarc.nixos.org"
      type     = "TXT"
      value    = "v=DMARC1; p=none"
    },
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

### TODO: remove, see https://github.com/NixOS/infra/issues/485 ###
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

resource "netlify_dns_record" "nixos_DKIM1" {
  zone_id  = local.zone_id
  hostname = "dkimprovmx1._domainkey.nixos.org"
  type     = "CNAME"
  value    = "dkimprovmx1.improvmx.com"
}

resource "netlify_dns_record" "nixos_DKIM2" {
  zone_id  = local.zone_id
  hostname = "dkimprovmx2._domainkey.nixos.org"
  type     = "CNAME"
  value    = "dkimprovmx2.improvmx.com"
}
### END TODO: remove ###

resource "netlify_dns_record" "nixos_google_verification" {
  zone_id  = local.zone_id
  hostname = "nixos.org"
  type     = "TXT"
  value    = "google-site-verification=Pm5opvmNjJOwdb7JnuVJ_eFBPaZYWNcAavY-08AJoGc"
}
