# Lake Formation data filters & grants

###############################################################################
# Lake Formation data filters and grants per tenant
###############################################################################

resource "aws_lakeformation_data_cells_filter" "tenant_scope" {
  for_each = local.tenant_table_objects
  provider = aws.security_lake

  table_data {
    table_catalog_id = local.table_catalog_id
    database_name    = each.value.database_name
    table_name       = data.aws_glue_catalog_table.shared[each.value.table_key].name
    name             = "filter-${each.value.tenant_key}-${each.value.table_key}"

    dynamic "column_names" {
      for_each = each.value.allowed_columns != null ? [each.value.allowed_columns] : []
      content  = column_names.value
    }

    row_filter {
      filter_expression = each.value.row_filter_expression
    }
  }

  depends_on = [
    null_resource.revoke_default_permissions
  ]

  tags = merge(var.tags, {
    Tenant     = each.value.tenant_key
    TableAlias = each.value.table_key
  })
}

resource "aws_lakeformation_permissions" "tenant_database_describe" {
  for_each = local.tenant_database_objects
  provider = aws.security_lake

  catalog_id  = local.catalog_account_id
  principal   = each.value.tenant.query_role_arn
  permissions = ["DESCRIBE"]

  database {
    name = each.value.database_name
  }
}

resource "aws_lakeformation_permissions" "tenant_table_describe" {
  for_each = local.tenant_table_objects
  provider = aws.security_lake

  catalog_id  = local.catalog_account_id
  principal   = each.value.tenant.query_role_arn
  permissions = ["DESCRIBE"]

  table {
    database_name = each.value.database_name
    name          = each.value.table_name
  }
}

resource "aws_lakeformation_permissions" "tenant_filter_select" {
  for_each = local.tenant_table_objects
  provider = aws.security_lake

  catalog_id  = local.catalog_account_id
  principal   = each.value.tenant.query_role_arn
  permissions = ["SELECT"]

  data_cells_filter {
    table_catalog_id = local.catalog_account_id
    database_name    = each.value.database_name
    table_name       = each.value.table_name
    name             = aws_lakeformation_data_cells_filter.tenant_scope[each.key].table_data[0].name
  }

  depends_on = [
    aws_lakeformation_data_cells_filter.tenant_scope
  ]
}
