resource "aws_s3_bucket" "logs" {
  bucket_prefix = "fastly-logs-"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 365
    }
  }

  lifecycle_rule {
    id = "move-to-glacier"

    enabled = true

    transition {
      days          = 14
      storage_class = "DEEP_ARCHIVE"
    }
  }
}

resource "aws_s3_bucket_policy" "logs" {
  bucket = aws_s3_bucket.logs.id
  policy = <<EOF
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Sid": "AllowNixOSOrgRead",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::008826681144:user/fastly-log-processor"
      },
      "Action": [
        "s3:GetObject",
        "s3:ListBucket"
      ],
      "Resource": [
        "arn:aws:s3:::${aws_s3_bucket.logs.id}/*",
        "arn:aws:s3:::${aws_s3_bucket.logs.id}"
      ]
    }
  ]
}
EOF
}


resource "aws_iam_role" "fastly_log_forwarder" {
  name = "FastlyLogForwarder"
  path = "/system/"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "policy" {
  name_prefix = "FastlyLogForwarder"
  path        = "/system/"
  description = "Allow Fastly to write logs to ${aws_s3_bucket.logs.bucket}."

  policy = data.aws_iam_policy_document.fastly_write.json
}

resource "aws_iam_role_policy_attachment" "attachment" {
  role       = aws_iam_role.fastly_log_forwarder.name
  policy_arn = aws_iam_policy.policy.arn
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"

      # this is our Fastly customer ID
      values = [var.fastly_customer_id]
    }

    principals {
      type = "AWS"

      # This is the ID of the Fastly AWS account
      identifiers = ["717331877981"]
    }
  }
}

data "aws_iam_policy_document" "fastly_write" {
  statement {
    actions   = ["s3:PutObject"]
    resources = ["${aws_s3_bucket.logs.arn}/*"]
  }
}
