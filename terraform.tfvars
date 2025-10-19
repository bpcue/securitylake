# -----------------------------------------------------------------------------
# Sample variable values for the Security Lake multi-tenant deployment.
# Adjust account IDs, role names, tables, tenants, and tags for your environment.
# -----------------------------------------------------------------------------

home_region                        = "us-east-1"
organization_management_account_id = "123456789012"
organization_management_role_name  = "OrganizationAccountAccessRole"
security_lake_account_id           = "210987654321"
security_lake_admin_role_name      = "SecurityLakeTerraform"

# Toggle to have Terraform create/manage the OU inventory bucket.
create_ou_inventory_bucket = true

ou_inventory_bucket = "securitylake-tenant-inventory-example"
ou_inventory_prefix = "ous"

default_security_lake_sources = {
  CLOUD_TRAIL_MGMT = "2.0"
  VPC_FLOW         = "2.0"
}

tables = {
  cloudtrail = {
    database_name = "aws_security_lake_db"
    table_name    = "aws_security_lake_cloudtrail"
  }
}

tenants = {
  tenantA = {
    tenant_account_id      = "345678901234"
    subscriber_external_id = "tenantA-external-id"
    query_role_arn         = "arn:aws:iam::345678901234:role/SecurityLakeQueryRole"
    ou_id                  = "ou-exampleroot-tenantA"
    description            = "Tenant A Security Operations"
    include_accounts       = []
    table_overrides = {
      cloudtrail = {
        allowed_columns       = ["accountid", "eventtime", "eventname", "useridentity"]
        row_filter_expression = "accountid IN ('345678901234','456789012345')"
      }
    }
  }
}

tags = {
  Project = "SecurityLake"
  Owner   = "SecurityTeam"
}
