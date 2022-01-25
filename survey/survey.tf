locals {
  region = "eu-west-1"
}

output "public_ip" {
  #value = aws_instance.survey.public_ip
  value = aws_eip.survey.public_ip
}

resource "aws_vpc" "survey" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  enable_classiclink   = "false"
  instance_tenancy     = "default"

  tags = {
    "Name" = "survey.nixos.org"
  }
}

resource "aws_subnet" "survey" {
  vpc_id                  = aws_vpc.survey.id
  cidr_block              = "10.0.0.0/19"
  map_public_ip_on_launch = true
  availability_zone = "eu-west-1a"

  tags = {
    "Name" = "survey.nixos.org"
  }
}

resource "aws_route_table" "survey" {
  vpc_id = aws_vpc.survey.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.survey.id
  }
}

resource "aws_internet_gateway" "survey" {
  vpc_id = aws_vpc.survey.id

  tags = {
    "Name" = "survey.nixos.org"
  }
}

resource "aws_route_table_association" "survey" {
  subnet_id = aws_subnet.survey.id
  route_table_id = aws_route_table.survey.id
}

resource "aws_security_group" "survey" {
  name        = "survey-sg"
  description = "survey.nixos.org"
  vpc_id      = aws_vpc.survey.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    cidr_blocks     = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "survey" {
  instance = aws_instance.survey.id
  vpc      = true
}

resource "aws_instance" "survey" {
  ami = "ami-01d0304a712f2f3f0"
  instance_type = "t3a.xlarge"
  subnet_id               = aws_subnet.survey.id

  vpc_security_group_ids = [ aws_security_group.survey.id ]
  key_name        = aws_key_pair.generated_key.key_name

  root_block_device {
    tags = {
      "Name"   = "survey.nixos.org"
      "Owners" = "edolstra@gmail.com, rok@garbas.si"
    }
    volume_size = 50
  }

  tags = {
    "Name" = "survey.nixos.org"
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "tls_private_key" "state_ssh_key" {
  algorithm = "RSA"
}

resource "local_file" "machine_ssh_key" {
  sensitive_content = tls_private_key.state_ssh_key.private_key_pem
  filename          = "${path.module}/id_rsa.pem"
  file_permission   = "0600"
}

resource "aws_key_pair" "generated_key" {
  key_name   = "generated-key-${sha256(tls_private_key.state_ssh_key.public_key_openssh)}"
  public_key = tls_private_key.state_ssh_key.public_key_openssh
}
