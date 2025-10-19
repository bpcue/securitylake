# Derived locals used across modules

###############################################################################
# Additional shared locals
###############################################################################

locals {
  tenant_ou_ids                = distinct([for _, cfg in var.tenants : cfg.ou_id])
  ou_inventory_prefix_clean    = trim(var.ou_inventory_prefix, "/")
  tenant_inventory_target_list = join(",", local.tenant_ou_ids)
  ou_inventory_bucket_arn      = "arn:aws:s3:::${var.ou_inventory_bucket}"
  ou_inventory_objects_arn     = local.ou_inventory_prefix_clean != ""
    ? "arn:aws:s3:::${var.ou_inventory_bucket}/${local.ou_inventory_prefix_clean}/*"
    : "arn:aws:s3:::${var.ou_inventory_bucket}/*"
  ou_inventory_lambda_name     = "securitylake-ou-inventory-sync"
}
