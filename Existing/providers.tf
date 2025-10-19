# Provider configuration reused for existing Security Lake deployments

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
  security_lake_role = "arn:aws:iam::${var.security_lake_account_id}:role/${var.security_lake_admin_role_name}"
}

provider "aws" {
  alias  = "security_lake"
  region = var.home_region

  assume_role {
    role_arn     = local.security_lake_role
    session_name = "tf-securitylake-existing"
  }

  default_tags {
    tags = var.tags
  }
}
