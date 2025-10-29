terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "subject_filter" {
  type = list(string)
}

data "aws_caller_identity" "current" {}

data "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "assume_github_actions" {

  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github_actions.arn]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = var.subject_filter
    }
  }
}

output "json" {
  value = data.aws_iam_policy_document.assume_github_actions.json
}
