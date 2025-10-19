###############################################################################
# Build per-tenant table scopes (existing deployment)
###############################################################################

locals {
  tenant_table_matrix = {
    for tenant_key, tenant_cfg in var.tenants :
    tenant_key => {
      for table_key, table_cfg in var.tables :
      table_key => merge(
        {
          allowed_columns = null
          row_filter_expression = length(local.tenant_accounts[tenant_key]) > 0
            ? format("accountid IN (%s)", join(", ", [for acct in local.tenant_accounts[tenant_key] : format("'%s'", acct)]))
            : "accountid IS NULL"
        },
        lookup(coalesce(tenant_cfg.table_overrides, {}), table_key, {})
      )
    }
  }

  tenant_table_pairs = flatten([
    for tenant_key, table_cfg in local.tenant_table_matrix : [
      for table_key, settings in table_cfg : {
        tenant_key            = tenant_key
        tenant                = var.tenants[tenant_key]
        table_key             = table_key
        database_name         = var.tables[table_key].database_name
        table_name            = var.tables[table_key].table_name
        allowed_columns       = lookup(settings, "allowed_columns", null)
        row_filter_expression = lookup(settings, "row_filter_expression", null)
      }
    ]
  ])

  tenant_table_objects = {
    for obj in local.tenant_table_pairs :
    "${obj.tenant_key}::${obj.table_key}" => obj
  }

  tenant_database_objects = {
    for obj in local.tenant_table_pairs :
    "${obj.tenant_key}::${obj.database_name}" => {
      tenant_key    = obj.tenant_key
      tenant        = obj.tenant
      database_name = obj.database_name
    }
  }

  active_tables = {
    for table_key, table_cfg in var.tables :
    table_key => table_cfg
    if length([
      for tt in local.tenant_table_pairs : 1
      if tt.table_key == table_key
    ]) > 0
  }
}
