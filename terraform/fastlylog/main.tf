

resource "aws_s3_bucket" "logs" {
  bucket_prefix = "fastly-logs"

  lifecycle_rule {
    enabled = true

    expiration {
      days = 365
    }
  }
}

resource "aws_iam_role" "fastly_log_forwarder" {
  name = "FastlyLogForwarder"
  path = "/system/"

  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_policy" "policy" {
  name_prefix = "FastlyLogForwarder"
  path        = "/system"
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
