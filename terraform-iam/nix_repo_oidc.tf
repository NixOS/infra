# In this document we configure OIDC from GitHub to allow automatically
# publishing NixOS/nix releases using GitHub Actions.
#
# This means that everyone with merge rights in the Nix repo can publish
# releases (with a public trail).

resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = ["sts.amazonaws.com"]
  thumbprint_list = [
    # https://github.com/aws-actions/configure-aws-credentials/issues/357#issuecomment-1626357333
    "6938fd4d98bab03faadb97b34396831e3780aea1",
  ]
}

import {
  to = aws_iam_openid_connect_provider.github_actions
  id = format(
    "arn:aws:iam::%s:oidc-provider/token.actions.githubusercontent.com",
    data.aws_caller_identity.current.account_id,
  )
}

data "aws_iam_policy_document" "nix_release" {
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:PutObject"
    ]
    # Only allow uploading in the /nix/ prefix in the bucket
    resources = ["arn:aws:s3:::nix-releases/nix/*"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:ListBucketMultipartUploads"
    ]
    resources = ["arn:aws:s3:::nix-releases"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["nix/*"]
    }
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    # The release also publishes the install script when it's the latest
    # release.
    resources = ["arn:aws:s3:::nix-channels/nix-latest/install"]
  }

  statement {
    effect = "Allow"
    actions = [
      "s3:ListBucket"
    ]
    resources = ["arn:aws:s3:::nix-channels"]
    condition {
      test     = "StringLike"
      variable = "s3:prefix"
      values   = ["nix-latest/*"]
    }
  }
}

resource "aws_iam_policy" "nix_release" {
  name   = "nix-release"
  policy = data.aws_iam_policy_document.nix_release.json
}

data "aws_caller_identity" "current" {}

module "assume_nix_releases_permission" {
  source              = "./assume_identity_center_permission_policy"
  target_account_id   = data.aws_caller_identity.current.account_id
  permission_set_name = "NixReleases"
  sso_region          = "eu-north-1"
}

module "assume_nix_release" {
  source = "./assume_github_actions_policy_document"

  # Only allow to assume this role in the NixOS/nix repo, and while running
  # in the "releases" environment.
  subject_filter = ["repo:NixOS/nix:environment:releases"]
}

data "aws_iam_policy_document" "assume_nix_release" {
  source_policy_documents = [
    module.assume_nix_releases_permission.json,
    module.assume_nix_release.json,
  ]
}

resource "aws_iam_role" "nix_release" {
  name               = "nix-release"
  assume_role_policy = data.aws_iam_policy_document.assume_nix_release.json
}

resource "aws_iam_role_policy_attachment" "nix_release_managed_policy" {
  role       = aws_iam_role.nix_release.name
  policy_arn = aws_iam_policy.nix_release.arn
}

output "nix_release_role_arn" {
  value = aws_iam_role.nix_release.arn
}
