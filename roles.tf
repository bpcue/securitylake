# Meta store manager IAM role/policy

###############################################################################
# IAM role Security Lake uses to manage Glue & Lake Formation resources
###############################################################################

data "aws_iam_policy_document" "meta_store_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["securitylake.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "meta_store_permissions" {
  statement {
    sid     = "GlueMetadataMaintenance"
    effect  = "Allow"
    actions = [
      "glue:BatchCreatePartition",
      "glue:BatchDeletePartition",
      "glue:CreatePartition",
      "glue:DeletePartition",
      "glue:GetDatabase",
      "glue:GetDatabases",
      "glue:GetPartition",
      "glue:GetPartitions",
      "glue:GetTable",
      "glue:GetTables",
      "glue:UpdateTable"
    ]
    resources = [
      "arn:aws:glue:${var.home_region}:${var.security_lake_account_id}:catalog",
      "arn:aws:glue:${var.home_region}:${var.security_lake_account_id}:database/*",
      "arn:aws:glue:${var.home_region}:${var.security_lake_account_id}:table/*"
    ]
  }

  statement {
    sid     = "LakeFormationRuntime"
    effect  = "Allow"
    actions = [
      "lakeformation:GetDataAccess",
      "lakeformation:GetResourceLFTags",
      "lakeformation:ListPermissions"
    ]
    resources = ["*"]
  }

  statement {
    sid     = "SecurityLakeBuckets"
    effect  = "Allow"
    actions = [
      "s3:GetBucketLocation",
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = [
      "arn:aws:s3:::aws-security-data-lake-*",
      "arn:aws:s3:::aws-security-data-lake-*/*"
    ]
  }
}

resource "aws_iam_role" "meta_store_manager" {
  provider           = aws.security_lake
  name               = "AmazonSecurityLakeMetaStoreManager"
  description        = "Role Security Lake uses for Glue partition updates"
  assume_role_policy = data.aws_iam_policy_document.meta_store_assume.json
  tags               = merge(var.tags, { ManagedBy = "terraform" })
}

resource "aws_iam_role_policy" "meta_store_manager" {
  provider = aws.security_lake
  role     = aws_iam_role.meta_store_manager.id
  policy   = data.aws_iam_policy_document.meta_store_permissions.json
}
