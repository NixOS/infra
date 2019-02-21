locals {
  host_bastion = "34.254.208.229"
  host_chef    = "46.4.67.10"
  host_www     = "54.217.220.47"
  host_status  = "138.201.32.77"
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

resource "aws_route53_record" "nixos-a" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = ""
  type    = "A"
  ttl     = "500"
  records = ["${local.host_www}"]
}

resource "aws_route53_record" "nixos-bastion" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "bastion"
  type    = "A"
  ttl     = "600"
  records = ["${local.host_bastion}"]
}

resource "aws_route53_record" "nixos-discourse" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "discourse"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixos1.hosted-by-discourse.com"]
}

resource "aws_route53_record" "nixos-cache" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "cache"
  type    = "CNAME"
  ttl     = "3600"
  records = ["dualstack.v2.shared.global.fastly.net"]
}

resource "aws_route53_record" "nixos-cache-verification" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "_d47a77b375708cea087182ee599174c0.cache"
  type    = "CNAME"
  ttl     = "600"
  records = ["_f437d0ffb520b017f4d72beb71afedf8.acm-validations.aws"]
}

# NOTE: this should be moved to the nixcon.org domain
resource "aws_route53_record" "nixos-conf" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "conf"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixconberlin.github.io"]
}

resource "aws_route53_record" "nixos-conf-wild" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "*.conf"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixconberlin.github.io"]
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

resource "aws_route53_record" "nixos-planet" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "planet"
  type    = "A"
  ttl     = "3600"
  records = ["${local.host_www}"]
}

resource "aws_route53_record" "nixos-releases" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "releases"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3g5gsiof5omrk.cloudfront.net."]
}

resource "aws_route53_record" "nixos-releases-verification" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "_d8f6310f3e219676be295c56e7084ed2.releases"
  type    = "CNAME"
  ttl     = "600"
  records = ["_f66cc632b3b03a0f5493a406c535ad7d.acm-validations.aws"]
}

resource "aws_route53_record" "nixos-status" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "status"
  type    = "A"
  ttl     = "3600"
  records = ["${local.host_status}"]
}

resource "aws_route53_record" "nixos-tarballs" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "tarballs"
  type    = "CNAME"
  ttl     = "3600"
  records = ["d3am6xf9zisc71.cloudfront.net."]
}

resource "aws_route53_record" "nixos-tarballs-verification" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "_ea68264b3470fb78960575f8dda9b40b.tarballs"
  type    = "CNAME"
  ttl     = "600"
  records = ["_d7407b1e66c162385ea6816b6da86f00.acm-validations.aws"]
}

resource "aws_route53_record" "nixos-weekly" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "weekly"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixos-weekly.netlify.com"]
}

resource "aws_route53_record" "nixos-weekly-wild" {
  zone_id = "${aws_route53_zone.nixos.zone_id}"
  name    = "*.weekly"
  type    = "CNAME"
  ttl     = "3600"
  records = ["nixos-weekly.netlify.com"]
}

#resource "aws_route53_record" "nixos-wild" {
#  zone_id = "${aws_route53_zone.nixos.zone_id}"
#  name    = "*"
#  type    = "A"
#  ttl     = "3600"
#  records = ["${local.host_www}"]
#}
