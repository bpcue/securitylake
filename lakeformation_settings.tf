# Lake Formation default settings

###############################################################################
# Lake Formation: disable IAMAllowedPrincipals defaults
###############################################################################

resource "aws_lakeformation_data_lake_settings" "defaults" {
  provider   = aws.security_lake
  catalog_id = local.catalog_account_id

  admins = [
    local.security_lake_role
  ]

  parameters = {
    CROSS_ACCOUNT_VERSION = "4"
  }
}
