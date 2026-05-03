# Forward S3 Object Created events on the nix-cache bucket to the
# https://cache-updates.snix.store webhook via an EventBridge API destination.

locals {
  cache_webhook_url        = "https://cache-updates.snix.store"
  cache_webhook_header_key = "X-API-Key"
}

resource "secret_resource" "cache_webhook_api_key" {}

# Cost: $1.00 per million events ingested. S3 EventBridge events are opt-in
# data plane events, billed as custom events on the default bus.
# https://aws.amazon.com/eventbridge/pricing/
resource "aws_s3_bucket_notification" "cache" {
  provider    = aws.us
  bucket      = aws_s3_bucket.cache.id
  eventbridge = true
}

resource "aws_cloudwatch_event_connection" "cache_webhook" {
  provider           = aws.us
  name               = "cache-updates-snix-store"
  authorization_type = "API_KEY"

  auth_parameters {
    api_key {
      key   = local.cache_webhook_header_key
      value = secret_resource.cache_webhook_api_key.value
    }
  }
}

# Cost: $0.20 per million invocations.
# https://aws.amazon.com/eventbridge/pricing/
resource "aws_cloudwatch_event_api_destination" "cache_webhook" {
  provider            = aws.us
  name                = "cache-updates-snix-store"
  invocation_endpoint = local.cache_webhook_url
  http_method         = "POST"
  # Tweak this based on the amount of uploads per 24 hours?
  invocation_rate_limit_per_second = 300
  connection_arn                   = aws_cloudwatch_event_connection.cache_webhook.arn
}

resource "aws_cloudwatch_event_rule" "cache_object_created" {
  provider    = aws.us
  name        = "nix-cache-object-created"
  description = "S3 Object Created events on nix-cache forwarded to cache-updates.snix.store"

  event_pattern = jsonencode({
    source        = ["aws.s3"]
    "detail-type" = ["Object Created"]
    detail = {
      bucket = {
        name = [aws_s3_bucket.cache.id]
      }
    }
  })
}

data "aws_iam_policy_document" "cache_webhook_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "cache_webhook_invoke" {
  statement {
    effect    = "Allow"
    actions   = ["events:InvokeApiDestination"]
    resources = [aws_cloudwatch_event_api_destination.cache_webhook.arn]
  }
}

resource "aws_iam_role" "cache_webhook" {
  provider           = aws.us
  name               = "EventBridgeInvokeCacheWebhook"
  assume_role_policy = data.aws_iam_policy_document.cache_webhook_assume.json
}

resource "aws_iam_role_policy" "cache_webhook" {
  provider = aws.us
  name     = "InvokeCacheWebhook"
  role     = aws_iam_role.cache_webhook.id
  policy   = data.aws_iam_policy_document.cache_webhook_invoke.json
}

resource "aws_cloudwatch_event_target" "cache_webhook" {
  provider  = aws.us
  rule      = aws_cloudwatch_event_rule.cache_object_created.name
  target_id = "cache-updates-snix-store"
  arn       = aws_cloudwatch_event_api_destination.cache_webhook.arn
  role_arn  = aws_iam_role.cache_webhook.arn

  # https://docs.aws.amazon.com/eventbridge/latest/userguide/eb-rule-retry-policy.html
  retry_policy {
    maximum_event_age_in_seconds = 86400
    maximum_retry_attempts       = 185
  }
}
