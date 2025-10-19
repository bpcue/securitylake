# Reference shared Glue tables (existing deployment)

data "aws_glue_catalog_table" "shared" {
  for_each      = local.active_tables
  provider      = aws.security_lake
  database_name = each.value.database_name
  name          = each.value.table_name
}
