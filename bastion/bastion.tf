locals {
  region = "eu-west-1"
  zone   = "eu-west-1a"
}

resource "aws_vpc" "bastion" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  instance_tenancy     = "default"

  tags = {
    "CharonMachineName" = "bastion-vpc"
    "CharonNetworkName" = "nixos-bastion"
    "CharonNetworkUUID" = "d48ef0d9-7bb1-11e8-8c41-507b9defcdfc"
    "CharonStateFile"   = "deploy@bastion:/home/deploy/.nixops/deployments.nixops"
    "Name"              = "Unnamed NixOps network [bastion-vpc]"
  }
}

resource "aws_subnet" "bastion" {
  vpc_id                  = aws_vpc.bastion.id
  cidr_block              = "10.0.0.0/19"
  map_public_ip_on_launch = true

  tags = {
    "CharonMachineName" = "bastion-subnet"
    "CharonNetworkName" = "nixos-bastion"
    "CharonNetworkUUID" = "d48ef0d9-7bb1-11e8-8c41-507b9defcdfc"
    "CharonStateFile"   = "deploy@bastion:/home/deploy/.nixops/deployments.nixops"
    "Name"              = "Unnamed NixOps network [bastion-subnet]"
  }
}

resource "aws_route_table" "bastion" {
  vpc_id = aws_vpc.bastion.id
  route  = []
}

resource "aws_internet_gateway" "bastion" {
  vpc_id = aws_vpc.bastion.id

  tags = {
    "CharonMachineName" = "bastion-igw"
    "CharonNetworkName" = "nixos-bastion"
    "CharonNetworkUUID" = "d48ef0d9-7bb1-11e8-8c41-507b9defcdfc"
    "CharonStateFile"   = "deploy@bastion:/home/deploy/.nixops/deployments.nixops"
  }
}

resource "aws_security_group" "bastion" {
  name        = "charon-d48ef0d9-7bb1-11e8-8c41-507b9defcdfc-bastion-sg"
  description = "NixOps-provisioned group bastion-sg"
  vpc_id      = aws_vpc.bastion.id

  egress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = ""
      from_port        = 0
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "-1"
      security_groups  = []
      self             = false
      to_port          = 0
    },
  ]

  ingress = [
    {
      cidr_blocks      = ["0.0.0.0/0"]
      description      = ""
      from_port        = 51820
      ipv6_cidr_blocks = []
      prefix_list_ids  = []
      protocol         = "udp"
      security_groups  = []
      self             = false
      to_port          = 51820
    },
  ]

  timeouts {}

  lifecycle {
    # User IPs are manually added to the security group.
    ignore_changes = [ingress]
  }
}

resource "aws_instance" "bastion" {
  ami                     = "ami-cda4fab4"
  instance_type           = "t3.xlarge"
  subnet_id               = aws_subnet.bastion.id
  disable_api_termination = true

  # TODO(zimbatm): move that to a aws_ebs_volume + aws_volume_attachment
  ebs_block_device {
    delete_on_termination = false
    device_name           = "/dev/sdh"
    tags = {
      "CharonMachineName" = "scratch"
      "CharonNetworkName" = "nixos-bastion"
      "CharonNetworkUUID" = "d48ef0d9-7bb1-11e8-8c41-507b9defcdfc"
      "CharonStateFile"   = "deploy@bastion:/home/deploy/.nixops/deployments.nixops"
      "Name"              = "Scratch space for the channel generator"
    }
    volume_size = 64
    volume_type = "standard"
  }

  root_block_device {
    delete_on_termination = false
    iops = 450
    tags = {
      "Name"   = "Unnamed NixOps network [bastion - /dev/xvda1]"
      "Owners" = "edolstra@gmail.com, rob.vermaas@gmail.com"
    }
    volume_size = 150
    volume_type = "gp2"
  }

  tags = {
    "CharonMachineName" = "bastion"
    "CharonNetworkName" = "nixos-bastion"
    "CharonNetworkUUID" = "d48ef0d9-7bb1-11e8-8c41-507b9defcdfc"
    "CharonStateFile"   = "deploy@bastion:/home/deploy/.nixops/deployments.nixops"
    "Name"              = "NixOS.org Infrastructure Deployment Server"
    "Owners"            = "edolstra@gmail.com, rob.vermaas@gmail.com"
  }

  lifecycle {
    # FIXME(zimbatm): I'm not sure why, the user_data changes on every plan.
    ignore_changes = [user_data]
  }
}

resource "aws_eip" "bastion" {
  instance = aws_instance.bastion.id
  vpc      = true
}

module "bastion_deploy" {
  source = "github.com/numtide/terraform-deploy-nixos-flakes"

  target_host = aws_eip.bastion.public_ip
  target_user = "deploy"

  flake      = path.module
  flake_host = "bastion"

  ssh_agent = true

  triggers = {
    machine_id = aws_instance.bastion.id
  }
}
