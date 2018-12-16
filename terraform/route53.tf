locals {
  host_bastion = "34.254.208.229"
  host_chef    = "46.4.67.10"
  host_www     = "54.217.220.47"
}

resource "aws_route53_zone" "nixos" {
  name = "nixos.org"
}

resource "aws_route53_record" "nixos-mx" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = ""
  type    = "MX"
  ttl     = "14300"

  records = [
    "10 mx00.udag.de.",
    "20 mx01.udag.de.",
  ]
}

resource "aws_route53_record" "nixos-naked" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = ""
  type    = "A"
  ttl     = "500"
  records = ["${local.host_www}"]
}

resource "aws_route53_record" "nixos-www" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "www"
  type    = "A"
  ttl     = "3600"
  records = ["${local.host_www}"]
}

resource "aws_route53_record" "nixos-wild" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "*"
  type    = "A"
  ttl     = "3600"
  records = ["${local.host_www}"]
}

resource "aws_route53_record" "nixos-planet" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "planet"
  type    = "A"
  ttl     = "3600"
  records = ["${local.host_www}"]
}

resource "aws_route53_record" "nixos-conf" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "conf"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixconberlin.github.io"]
}

resource "aws_route53_record" "nixos-weekly" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "weekly"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixos.github.io"]
}

resource "aws_route53_record" "nixos-cache" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "tarballs"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dualstack.v2.shared.global.fastly.net"]
}

resource "aws_route53_record" "nixos-tarballs" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "tarballs"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3am6xf9zisc71.cloudfront.net"]
}

resource "aws_route53_record" "nixos-releases" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "tarballs"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3g5gsiof5omrk.cloudfront.net."]
}

resource "aws_route53_record" "nixos-bastion" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "bastion"
  type    = "A"
  ttl     = "600"
  records = ["${local.host_bastion}"]
}

resource "aws_route53_record" "nixos-hydra-v4" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "hydra"
  type    = "A"
  ttl     = "3600"
  records = ["${local.host_chef}"]
}

resource "aws_route53_record" "nixos-hydra-v6" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "hydra"
  type    = "AAAA"
  ttl     = "3600"
  records = ["2a01:4f8:140:248f::"]
}
