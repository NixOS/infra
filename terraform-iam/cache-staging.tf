resource "aws_iam_user" "s3-upload-cache-staging" {
  name = "s3-upload-cache-staging"
}

resource "aws_iam_access_key" "s3-upload-cache-staging" {
  user = aws_iam_user.s3-upload-cache-staging.name
}

data "aws_iam_policy_document" "s3-upload-cache-staging" {
  statement {
    # Read-only access and listing permissions
    # To the cache and releases inventories,
    # as well as the bucket where cache bucket logs end up in.
    sid = "NixCacheStagingBucket"

    actions = [
      "s3:*"
    ]

    resources = [
      "arn:aws:s3:::nix-cache-staging",
      "arn:aws:s3:::nix-cache-staging/*",
      "arn:aws:s3:::nix-cache-staging-202410",
      "arn:aws:s3:::nix-cache-staging-202410/*",
    ]
  }
}

# This is the role that is given to the AWS Identity Center users
resource "aws_iam_policy" "s3-upload-cache-staging" {
  provider = aws.us

  name        = "s3-upload-cache-staging"
  description = "used by staging hydra"

  policy = data.aws_iam_policy_document.s3-upload-cache-staging.json
}

resource "aws_iam_user_policy_attachment" "s3-upload-cache-staging-attachment" {
  user       = aws_iam_user.s3-upload-cache-staging.name
  policy_arn = aws_iam_policy.s3-upload-cache-staging.arn
}

output "s3-upload-key-staging" {
  value = {
    key    = aws_iam_access_key.s3-upload-cache-staging.id
    secret = aws_iam_access_key.s3-upload-cache-staging.secret
  }
  sensitive = true
}

