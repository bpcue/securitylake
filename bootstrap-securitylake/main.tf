# Terraform to create the Security Lake admin role that the main stack assumes
# in the delegated Security Lake account. Run with credentials that have
# permissions in that account (before the role exists).

terraform {
  required_version = ">= 1.4.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

provider "aws" {
  region = var.bootstrap_region
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "AWS"
      identifiers = var.trusted_principal_arns
    }
  }
}

resource "aws_iam_role" "security_lake_admin" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Purpose = "SecurityLakeTerraformAdmin"
  }
}

data "aws_iam_policy_document" "security_lake_permissions" {
  statement {
    sid    = "SecurityLake"
    effect = "Allow"
    actions = [
      "securitylake:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "LakeFormation"
    effect = "Allow"
    actions = [
      "lakeformation:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "Glue"
    effect = "Allow"
    actions = [
      "glue:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "IAMLimited"
    effect = "Allow"
    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:GetRole",
      "iam:PassRole",
      "iam:PutRolePolicy",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:GetRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3Inventory"
    effect = "Allow"
    actions = [
      "s3:CreateBucket",
      "s3:DeleteBucket",
      "s3:GetBucketLocation",
      "s3:GetBucketPolicy",
      "s3:PutBucketPolicy",
      "s3:PutBucketVersioning",
      "s3:PutEncryptionConfiguration",
      "s3:PutBucketPublicAccessBlock",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "LambdaEvents"
    effect = "Allow"
    actions = [
      "lambda:*",
      "events:*",
      "logs:*"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "OrganizationsRead"
    effect = "Allow"
    actions = [
      "organizations:ListAccountsForParent",
      "organizations:DescribeAccount",
      "organizations:ListParents"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "security_lake_admin" {
  name   = "SecurityLakeAdminPermissions"
  role   = aws_iam_role.security_lake_admin.id
  policy = data.aws_iam_policy_document.security_lake_permissions.json
}

resource "aws_iam_role_policy_attachment" "additional" {
  for_each = toset(var.additional_policy_arns)
  role     = aws_iam_role.security_lake_admin.name
  policy_arn = each.value
}

output "security_lake_admin_role_arn" {
  value       = aws_iam_role.security_lake_admin.arn
  description = "Use this ARN as security_lake_admin_role_name in the main stack."
}
