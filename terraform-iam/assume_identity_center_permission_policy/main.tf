terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

variable "target_account_id" {
  description = "AWS account ID where the reserved SSO roles exist (the target account)."
  type        = string
}

variable "sso_region" {
  description = "Region of the AWS IAM Identity Center instance."
  type        = string
  default     = "eu-north-1"
}

variable "permission_set_name" {
  description = "Name of the IAM Identity Center permission set (without the AWSReservedSSO_ prefix)."
  type        = string
}

locals {
  reserved_role_pattern = format(
    "arn:aws:iam::%s:role/aws-reserved/sso.amazonaws.com/%s/AWSReservedSSO_%s_*",
    var.target_account_id,
    var.sso_region,
    var.permission_set_name,
  )
}

data "aws_iam_policy_document" "this" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [format("arn:aws:iam::%s:root", var.target_account_id)]
    }
    condition {
      test     = "ArnLike"
      variable = "aws:PrincipalArn"
      values   = [local.reserved_role_pattern]
    }
  }
}

output "json" {
  value = data.aws_iam_policy_document.this.json
}
