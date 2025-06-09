variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket" "cache" {
  provider = aws
  bucket   = var.bucket_name

  lifecycle_rule {
    enabled = true

    prefix = ""

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

resource "aws_s3_bucket_public_access_block" "cache" {
  bucket = aws_s3_bucket.cache.bucket

  block_public_acls   = false
  block_public_policy = false
}

resource "aws_s3_bucket_object" "cache-nix-cache-info" {
  provider   = aws
  depends_on = [aws_s3_bucket_public_access_block.cache]

  bucket       = aws_s3_bucket.cache.bucket
  content_type = "text/x-nix-cache-info"
  etag         = filemd5("${path.module}/../cache-staging/nix-cache-info")
  key          = "nix-cache-info"
  source       = "${path.module}/../cache-staging/nix-cache-info"
}

resource "aws_s3_bucket_object" "cache-index-html" {
  provider   = aws
  depends_on = [aws_s3_bucket_public_access_block.cache]

  bucket       = aws_s3_bucket.cache.bucket
  content_type = "text/html"
  etag         = filemd5("${path.module}/../cache-staging/index.html")
  key          = "index.html"
  source       = "${path.module}/../cache-staging/index.html"
}

resource "aws_s3_bucket_policy" "cache" {
  provider   = aws
  bucket     = aws_s3_bucket.cache.id
  depends_on = [aws_s3_bucket_public_access_block.cache]

  # imported from existing
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
      "Resource": "arn:aws:s3:::${var.bucket_name}/*"
    },
    {
      "Sid": "AllowUploadDebuginfoWrite",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-releases"
      },
      "Action": [
        "s3:PutObject",
        "s3:PutObjectAcl"
      ],
      "Resource": "arn:aws:s3:::${var.bucket_name}/debuginfo/*"
    },
    {
      "Sid": "AllowUploadDebuginfoRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-releases"
      },
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::${var.bucket_name}/*"
    },
    {
      "Sid": "AllowUploadDebuginfoRead2",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::080433136561:user/s3-upload-releases"
      },
      "Action": [
        "s3:ListBucket",
        "s3:GetBucketLocation"
      ],
      "Resource": "arn:aws:s3:::${var.bucket_name}"
    }
  ]
}
EOF
}

resource "aws_s3_bucket_request_payment_configuration" "cache" {
  provider = aws
  bucket   = aws_s3_bucket.cache.id
  payer    = "Requester"
}

output "bucket" {
  value = aws_s3_bucket.cache.bucket
}

output "bucket_domain_name" {
  value = aws_s3_bucket.cache.bucket_domain_name
}

output "bucket_regional_domain_name" {
  value = aws_s3_bucket.cache.bucket_regional_domain_name
}

output "region" {
  value = aws_s3_bucket.cache.region
}
