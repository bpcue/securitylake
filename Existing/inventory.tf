###############################################################################
# Load OU inventory from S3 (existing deployment)
###############################################################################

locals {
  tenant_s3_objects = {
    for tenant_key, tenant_cfg in var.tenants :
    tenant_key => {
      bucket = var.ou_inventory_bucket
      key    = local.ou_inventory_prefix_clean != ""
        ? "${local.ou_inventory_prefix_clean}/${tenant_cfg.ou_id}.json"
        : "${tenant_cfg.ou_id}.json"
    }
  }
}

data "aws_s3_object" "tenant_accounts" {
  for_each = local.tenant_s3_objects
  provider = aws.security_lake
  bucket   = each.value.bucket
  key      = each.value.key
}

locals {
  tenant_accounts = {
    for tenant_key, tenant_cfg in var.tenants :
    tenant_key => sort(distinct(concat(
      try(jsondecode(data.aws_s3_object.tenant_accounts[tenant_key].body).accounts, []),
      coalesce(tenant_cfg.include_accounts, [])
    )))
  }
}
