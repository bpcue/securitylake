# Revoke IAM_ALLOWED_PRINCIPALS

###############################################################################
# Remove IAM_ALLOWED_PRINCIPALS from each shared table
###############################################################################

resource "null_resource" "revoke_default_permissions" {
  for_each = local.active_tables

  triggers = {
    database = each.value.database_name
    table    = each.value.table_name
  }

  provisioner "local-exec" {
    when    = "create"
    command = <<-EOT
      set -euo pipefail
      aws lakeformation batch-revoke-permissions --region ${var.home_region} --cli-input-json '{
        "Entries": [{
          "Id": "lf-revoke-${each.key}",
          "Principal": { "DataLakePrincipalIdentifier": "IAM_ALLOWED_PRINCIPALS" },
          "Resource": {
            "Table": {
              "CatalogId": "${local.catalog_account_id}",
              "DatabaseName": "${each.value.database_name}",
              "Name": "${each.value.table_name}"
            }
          },
          "Permissions": ["ALL"],
          "PermissionsWithGrantOption": ["ALL"]
        }]
      }' || echo "No IAM_ALLOWED_PRINCIPALS grant found for ${each.value.database_name}.${each.value.table_name}"
    EOT
  }
}
