resource "aws_s3_bucket" "cache" {
  provider = aws
  bucket   = "ngi0-cache"

  lifecycle_rule {
    enabled = true

    transition {
      days          = 365
      storage_class = "STANDARD_IA"
    }
  }

  cors_rule {
    allowed_headers = ["Authorization"]
    allowed_methods = ["GET"]
    allowed_origins = ["*"]
    max_age_seconds = 3000
  }
}

resource "aws_s3_bucket_policy" "cache" {
  provider = aws
  bucket   = aws_s3_bucket.cache.id
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
      "Resource": "arn:aws:s3:::${aws_s3_bucket.cache.id}/*"
    }
  ]
}
EOF
}
