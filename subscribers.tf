# Create Security Lake subscribers

###############################################################################
# Amazon Security Lake subscribers (one per tenant)
###############################################################################

resource "aws_securitylake_subscriber" "tenant" {
  for_each = var.tenants
  provider = aws.security_lake

  subscriber_name        = each.key
  subscriber_description = lookup(each.value, "description", null)
  access_type            = "LAKEFORMATION"

  dynamic "source" {
    for_each = lookup(each.value, "sources", var.default_security_lake_sources)

    content {
      aws_log_source_resource {
        source_name    = source.key
        source_version = source.value
      }
    }
  }

  subscriber_identity {
    principal   = each.value.tenant_account_id
    external_id = each.value.subscriber_external_id
  }

  depends_on = [
    aws_securitylake_data_lake.this,
    aws_lakeformation_data_lake_settings.defaults
  ]

  tags = merge(var.tags, { Tenant = each.key })
}
