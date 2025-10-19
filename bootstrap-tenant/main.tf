# Terraform to create the tenant-side role used for querying Security Lake via
# Lake Formation resource links. Run with credentials in the tenant account.

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

resource "aws_iam_role" "query" {
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Purpose = "SecurityLakeTenantQuery"
  }
}

data "aws_iam_policy_document" "query_permissions" {
  statement {
    sid    = "LakeFormation"
    effect = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:ListPermissions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "GlueDescribe"
    effect = "Allow"
    actions = [
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetTable",
      "glue:GetTables",
      "glue:GetPartition",
      "glue:GetPartitions"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AthenaExecution"
    effect = "Allow"
    actions = [
      "athena:StartQueryExecution",
      "athena:GetQueryExecution",
      "athena:GetQueryResults",
      "athena:ListQueryExecutions",
      "athena:ListWorkGroups"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "S3ReadResults"
    effect = "Allow"
    actions = [
      "s3:GetObject"
    ]
    resources = var.athena_output_bucket_arn != null ? ["${var.athena_output_bucket_arn}/*"] : []
  }

  statement {
    sid    = "S3WriteResults"
    effect = "Allow"
    actions = [
      "s3:PutObject"
    ]
    resources = var.athena_output_bucket_arn != null ? ["${var.athena_output_bucket_arn}/*"] : []
  }
}

resource "aws_iam_role_policy" "query_inline" {
  name   = "SecurityLakeTenantQuery"
  role   = aws_iam_role.query.id
  policy = data.aws_iam_policy_document.query_permissions.json
}

output "query_role_arn" {
  value       = aws_iam_role.query.arn
  description = "Use this ARN as query_role_arn in the main tenant configuration."
}
