locals {
  nixos_zone_id = "${aws_route53_zone.nixos.zone_id}"
  unknown1_ip   = "54.217.220.47"                     # EC2 instance
  chef_ip       = "46.4.67.10"
}
