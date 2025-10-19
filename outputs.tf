output "security_lake_subscribers" {
  description = "Subscribers created per tenant with RAM share details."
  value = {
    for tenant, res in aws_securitylake_subscriber.tenant :
    tenant => {
      arn                = res.arn
      resource_share_arn = res.resource_share_arn
      access_type        = res.access_type
    }
  }
}

output "tenant_row_filters" {
  description = "Row filter expressions applied to each tenant/table combination."
  value = {
    for key, obj in local.tenant_table_objects :
    key => obj.row_filter_expression
  }
}
