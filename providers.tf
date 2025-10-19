# Provider configuration and shared locals

###############################################################################
# Terraform requirements & shared locals
###############################################################################

terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.50"
    }
  }
}

locals {
  org_role_arn       = "arn:aws:iam::${var.organization_management_account_id}:role/${var.organization_management_role_name}"
  security_lake_role = "arn:aws:iam::${var.security_lake_account_id}:role/${var.security_lake_admin_role_name}"

  catalog_account_id = var.security_lake_account_id
  table_catalog_id   = var.security_lake_account_id
}

###############################################################################
# Providers
###############################################################################

provider "aws" {
  alias  = "org"
  region = var.home_region

  assume_role {
    role_arn     = local.org_role_arn
    session_name = "tf-org-securitylake"
  }
}

provider "aws" {
  alias  = "security_lake"
  region = var.home_region

  assume_role {
    role_arn     = local.security_lake_role
    session_name = "tf-securitylake-admin"
  }

  default_tags {
    tags = var.tags
  }
}
