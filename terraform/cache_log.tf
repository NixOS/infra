resource "aws_s3_bucket" "cache_log" {
  provider = aws.us

  bucket = "nix-cache-log"
}

resource "aws_s3_bucket_logging" "cache_log" {
  provider = aws.us

  bucket = aws_s3_bucket.cache.id

  target_bucket = aws_s3_bucket.cache_log.id
  target_prefix = "log/"
}

resource "aws_s3_bucket_lifecycle_configuration" "cache_log" {
  provider = aws.us

  bucket = aws_s3_bucket.cache_log.id

  rule {
    id     = "rule-1"
    status = "Enabled"

    transition {
      days          = 30
      storage_class = "ONEZONE_IA"
    }

    expiration {
      days = "120"
    }
  }
}

data "aws_iam_policy_document" "cache_log" {
  statement {
    sid = "AWSLogDeliveryWrite"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    effect = "Allow"

    actions = [
      "s3:PutObject",
    ]

    resources = [
      "${aws_s3_bucket.cache_log.arn}/*",
    ]

    condition {
      test     = "StringEquals"
      variable = "s3:x-amz-acl"
      values   = ["bucket-owner-full-control"]
    }
  }

  statement {
    sid = "AWSLogDeliveryAclCheck"

    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["delivery.logs.amazonaws.com"]
    }

    actions = [
      "s3:GetBucketAcl",
    ]

    resources = [
      aws_s3_bucket.cache_log.arn,
    ]
  }

  statement {
    sid    = "S3PolicyStmt-DO-NOT-MODIFY-1699369618664"
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["logging.s3.amazonaws.com"]
    }

    actions = ["s3:PutObject"]

    resources = [
      "${aws_s3_bucket.cache_log.arn}/*",
    ]
  }
}

resource "aws_s3_bucket_policy" "cache_log" {
  provider = aws.us

  bucket = aws_s3_bucket.cache_log.id
  policy = data.aws_iam_policy_document.cache_log.json
}
