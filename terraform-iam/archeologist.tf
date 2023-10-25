resource "aws_iam_policy" "archologist" {
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

resource "aws_s3_bucket" "archeologist" {
  # Keep it in the same region as the cache
  provider = aws.us

  bucket = "nix-archeologist"
}
