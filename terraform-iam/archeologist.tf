# Workspace to dump analysis data extracted from the cache and other places.
resource "aws_s3_bucket" "archeologist" {
  # Keep it in the same region as the cache
  provider = aws.us

  bucket = "nix-archeologist"
}

# This is the role that is given to the AWS Identity Center users
resource "aws_iam_policy" "archologist" {
  provider = aws.us

  name        = "archeologist"
  description = "used by the S3 archeologists"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "NixCacheInventoryReadOnly",
            "Effect": "Allow",
            "Action": [
                "s3:Get*"
            ],
            "Resource": [
                "arn:aws:s3:::nix-cache-inventory",
                "arn:aws:s3:::nix-cache-inventory/*"
            ]
        },
        {
            "Sid": "NixArcheologistReadWrite",
            "Effect": "Allow",
            "Action": [
                "s3:Get*",
                "s3:List*",
                "s3:Put*"
            ],
            "Resource": [
                "${aws_s3_bucket.archeologist.arn}",
                "${aws_s3_bucket.archeologist.arn}/*"
            ]
        }
    ]
}
EOF
}

# Prepare this role to be attached to the EC2 instance
resource "aws_iam_role" "archeologist-worker" {
  provider = aws.us

  name = "archeologist-worker"

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        },
        "Effect": "Allow",
        "Sid": ""
      }
    ]
  }
  EOF
}

resource "aws_iam_role_policy" "archeologist-worker" {
  provider = aws.us

  name = "archeologist-worker"
  role = aws_iam_role.archeologist-worker.id

  # The EC2 instance gets the same policy as the users
  policy = aws_iam_policy.archologist.policy
}

resource "aws_iam_instance_profile" "archeologist" {
  provider = aws.us

  name = "archeologist-worker"
  role = aws_iam_role.archeologist-worker.name
  # Make sure the role is attached before continuing
  depends_on = [aws_iam_role_policy.archeologist-worker]
}

resource "aws_key_pair" "edef" {
  provider = aws.us

  key_name   = "edef-key"
  public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGu/CiEnmhIthp0XaGhU1cB18t6Ta/51k1/7EeIzKFwm"
}

resource "aws_instance" "archeologist" {
  provider = aws.us

  ami                         = "ami-07df5833f04703a2a" # "23.05".us-east-1.x86_64-linux.hvm-ebs
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.archeologist.id
  instance_type               = "r5a.2xlarge"
  key_name                    = aws_key_pair.edef.key_name
  subnet_id                   = "subnet-1eb22868" # default subnet us-east-1c

  root_block_device {
    volume_size = "256" # GB
  }

  vpc_security_group_ids = [
    "sg-51d35d29", # default
    "sg-b2ee60ca", # public-ssh
  ]

  tags = {
    Name = "archeologist-workspace"
  }
}
