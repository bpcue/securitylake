# Delegate Security Lake administration

###############################################################################
# AWS Organizations – delegate Security Lake to the central account
###############################################################################

resource "aws_organizations_delegated_administrator" "security_lake" {
  provider          = aws.org
  account_id        = var.security_lake_account_id
  service_principal = "securitylake.amazonaws.com"
}
