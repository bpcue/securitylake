# Security Lake enablement

###############################################################################
# Enable Amazon Security Lake in the delegated account
###############################################################################

resource "aws_securitylake_data_lake" "this" {
  provider                    = aws.security_lake
  meta_store_manager_role_arn = aws_iam_role.meta_store_manager.arn

  configuration {
    region = var.home_region

    encryption_configuration {
      kms_key_id = "S3_MANAGED_KEY"
    }

    lifecycle_configuration {
      transition {
        days          = 30
        storage_class = "STANDARD_IA"
      }

      expiration {
        days = 365
      }
    }
  }

  tags = var.tags
}
