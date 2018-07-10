resource "aws_route53_zone" "nixos" {
  name = "nixos.org"
}

resource "aws_route53_record" "nixos-root" {
  zone_id = "${local.nixos_zone_id}"
  name    = ""
  type    = "A"
  ttl     = "30"
  records = ["${local.unknown1_ip}"]
}

resource "aws_route53_record" "nixos-wiki" {
  zone_id = "${local.nixos_zone_id}"
  name    = "wiki"
  type    = "A"
  ttl     = "30"
  records = ["${local.unknown1_ip}"]
}

resource "aws_route53_record" "nixos-planet" {
  zone_id = "${local.nixos_zone_id}"
  name    = "planet"
  type    = "A"
  ttl     = "30"
  records = ["${local.unknown1_ip}"]
}

resource "aws_route53_record" "nixos-www" {
  zone_id = "${local.nixos_zone_id}"
  name    = "www"
  type    = "A"
  ttl     = "30"
  records = ["${local.chef_ip}"]
}

resource "aws_route53_record" "nixos-hydra" {
  zone_id = "${local.nixos_zone_id}"
  name    = "hydra"
  type    = "A"
  ttl     = "30"
  records = ["${local.chef_ip}"]
}

resource "aws_route53_record" "nixos-cache" {
  zone_id = "${local.nixos_zone_id}"
  name    = "cache"
  type    = "CNAME"
  ttl     = "30"
  records = ["d3m36hgdyp4koz.cloudfront.net"]
}

resource "aws_route53_record" "nixos-conf" {
  zone_id = "${local.nixos_zone_id}"
  name    = "conf"
  type    = "CNAME"
  ttl     = "30"
  records = ["nixconberlin.github.io"]
}

resource "aws_route53_record" "nixos-weekly" {
  zone_id = "${local.nixos_zone_id}"
  name    = "weekly"
  type    = "CNAME"
  ttl     = "30"
  records = ["nixos.github.io"]
}

resource "aws_route53_record" "nixos-tarballs" {
  zone_id = "${local.nixos_zone_id}"
  name    = "tarballs"
  type    = "CNAME"
  ttl     = "30"
  records = ["d3am6xf9zisc71.cloudfront.net"]
}
