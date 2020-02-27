resource "aws_s3_bucket" "channels" {
  provider = "aws.us"
  bucket = "nix-channels"

  website {
    index_document = "index.html"
  }
}

resource "aws_s3_bucket_policy" "channels" {
  provider = "aws.us"
  bucket = "${aws_s3_bucket.channels.id}"
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowPublicRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::nix-channels/*"
    },
    {
      "Sid": "AllowPublicList",
      "Effect": "Allow",
      "Principal": {
        "AWS": "*"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::nix-channels"
    },
    {
      "Sid": "AllowUpload",
      "Effect": "Allow",
      "Principal": {
        "AWS": [
          "arn:aws:iam::080433136561:user/s3-upload-releases",
          "arn:aws:iam::065343343465:user/nixos-s3-upload-releases"
        ]
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::nix-channels/*"
    }
  ]
}
EOF
}
