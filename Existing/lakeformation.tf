# Lake Formation hardening for existing Security Lake deployments

###############################################################################
# Lake Formation: disable IAMAllowedPrincipals defaults (existing deployments)
###############################################################################

resource "aws_lakeformation_data_lake_settings" "defaults" {
  provider   = aws.security_lake
  catalog_id = var.security_lake_account_id

  admins = [
    "arn:aws:iam::${var.security_lake_account_id}:role/${var.security_lake_admin_role_name}"
  ]

  parameters = {
    CROSS_ACCOUNT_VERSION = "4"
  }
}
