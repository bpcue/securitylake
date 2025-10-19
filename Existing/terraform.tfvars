# Example variable values for hardening an existing Security Lake deployment.

home_region                   = "us-east-1"
security_lake_account_id      = "210987654321"
security_lake_admin_role_name = "SecurityLakeTerraform"

create_ou_inventory_bucket = false
ou_inventory_bucket        = "securitylake-tenant-inventory-example"
ou_inventory_prefix        = "ous"

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
  }
}

tags = {
  Project = "SecurityLake"
  Owner   = "SecurityTeam"
}
