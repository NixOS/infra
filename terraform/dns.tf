# Our DNS is managed by Netlify

locals {
  # Shortcut to keep this a bit leaner
  zone_id = netlify_dns_zone.nixos.id
}

resource "netlify_dns_zone" "nixos" {
  site_id = ""
  name    = "nixos.org"
}

# Import fails with:
#
#   Error: &{0 } (*models.Error) is not supported by the TextConsumer, can be resolved by supporting TextUnmarshaler interface
#
# resource "netlify_dns_record" "test" {
#   zone_id  = local.zone_id
#
#   hostname = "nixos.org"
#   type     = "NETLIFY"
#   value    = "nixos-homepage.netlify.com"
# }
