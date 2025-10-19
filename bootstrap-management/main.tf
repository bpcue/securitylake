# Terraform to create the management-account role that allows registering
# Security Lake as a delegated administrator. Run this module using credentials
# that already have permissions in the AWS Organizations management account.

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

resource "aws_iam_role" "security_lake_delegation" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Purpose = "SecurityLakeDelegatedAdminSetup"
  }
}

data "aws_iam_policy_document" "delegation_permissions" {
  statement {
    sid    = "SecurityLakeDelegatedAdmin"
    effect = "Allow"
    actions = [
      "organizations:RegisterDelegatedAdministrator",
      "organizations:DeregisterDelegatedAdministrator",
      "organizations:ListDelegatedAdministrators",
      "organizations:ListCreateAccountStatus",
      "organizations:DescribeAccount",
      "organizations:DescribeOrganization"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "security_lake_delegation" {
  name   = "SecurityLakeDelegationPermissions"
  role   = aws_iam_role.security_lake_delegation.id
  policy = data.aws_iam_policy_document.delegation_permissions.json
}

output "delegation_role_arn" {
  value       = aws_iam_role.security_lake_delegation.arn
  description = "Use this ARN as organization_management_role_name in the main stack."
}
