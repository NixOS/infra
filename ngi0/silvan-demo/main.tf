provider "aws" {
  region = "eu-west-1"
}

output "public_ip" {
  value = aws_instance.server.public_ip
}

resource "aws_instance" "server" {
  ami = "ami-048dbc738074a3083"
  instance_type = "t3a.xlarge"
  subnet_id = aws_subnet.main.id
  #availability_zone = var.availability_zone

  vpc_security_group_ids = [ aws_security_group.ssh_and_egress.id ]
  key_name        = aws_key_pair.generated_key.key_name

  root_block_device {
    volume_size = 50 # GiB
  }

  lifecycle {
    ignore_changes = [ami]
  }
}

resource "aws_vpc" "vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  enable_classiclink = "false"
  instance_tenancy = "default"
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
}

resource "aws_subnet" "main" {
  vpc_id = aws_vpc.vpc.id
  cidr_block = "10.0.0.0/24"
  map_public_ip_on_launch = "true"
  availability_zone = "eu-west-1a"
}

resource "aws_route_table" "rt" {
  vpc_id = aws_vpc.vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table_association" "rt_assoc" {
  subnet_id = aws_subnet.main.id
  route_table_id = aws_route_table.rt.id
}

resource "aws_security_group" "ssh_and_egress" {
  vpc_id = aws_vpc.vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  ingress {
    from_port   = 222
    to_port     = 222
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
