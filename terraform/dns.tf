# Our DNS is managed by Netlify

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
      hostname = "ceres.nixos.org"
      type     = "A"
      value    = "46.4.66.184"
    },
    {
      hostname = "ceres.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:140:244c::"
    },
    {
      hostname = "haumea.nixos.org"
      type     = "A"
      value    = "46.4.89.205"
    },
    {
      hostname = "haumea.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:140:72cf::"
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
      type     = "A"
      value    = "46.4.66.184"
    },
    {
      hostname = "hydra.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:140:244c::"
    },
    {
      hostname = "monitoring.nixos.org"
      type     = "A"
      value    = "138.201.32.77"
    },
    {
      hostname = "planet.nixos.org"
      type     = "A"
      value    = "54.217.220.47"
    },
    {
      hostname = "status.nixos.org"
      type     = "A"
      value    = "138.201.32.77"
    },
    {
      hostname = "survey.nixos.org"
      type     = "A"
      value    = "78.47.220.153"
    },
    {
      hostname = "survey.nixos.org"
      type     = "AAAA"
      value    = "2a01:4f8:c0c:6e2c::1"
    },
  ]
}

resource "netlify_dns_zone" "nixos" {
  site_id = ""
  name    = "nixos.org"
}

# Import fails on all types with:
#
#   Error: &{0 } (*models.Error) is not supported by the TextConsumer, can be resolved by supporting TextUnmarshaler interface
#
# resource "netlify_dns_record" "nixos" {
#   zone_id  = local.zone_id
#
#   hostname = "nixos.org"
#   type     = "NETLIFY"
#   value    = "nixos-homepage.netlify.com"
# }
#
# New entries can be created if they are not of NETLIFY type.
#
# TTL is not supported.

# netlify api getDnsRecords -d '{ "zone_id": "5e6ce1b8b6f808aa16acd1ff" }'

resource "netlify_dns_record" "nixos" {
  for_each = { for v in local.dns_records : "${v.hostname}-${v.type}" => v }
  zone_id  = local.zone_id
  hostname = each.value.hostname
  type     = each.value.type
  value    = each.value.value
}
