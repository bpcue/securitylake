###############################################################################
# Input variables
###############################################################################

variable "home_region" {
  description = "Region hosting Security Lake (rollup Region)."
  type        = string
}

variable "organization_management_account_id" {
  description = "AWS Organizations management account ID."
  type        = string
}

variable "organization_management_role_name" {
  description = "Role Terraform assumes in the management account (e.g. OrganizationAccountAccessRole)."
  type        = string
}

variable "security_lake_account_id" {
  description = "Account ID delegated as Amazon Security Lake administrator."
  type        = string
}

variable "security_lake_admin_role_name" {
  description = "Role Terraform assumes inside the Security Lake account."
  type        = string
}

variable "ou_inventory_bucket" {
  description = "S3 bucket containing OU membership JSON documents."
  type        = string
}

variable "create_ou_inventory_bucket" {
  description = "Set to true to let Terraform create and manage the OU inventory S3 bucket."
  type        = bool
  default     = false
}

variable "ou_inventory_prefix" {
  description = "Prefix within the inventory bucket for OU JSON files."
  type        = string
  default     = "ous"
}

variable "default_security_lake_sources" {
  description = "Default log sources to share with each tenant subscriber (source => version)."
  type        = map(string)
  default = {
    CLOUD_TRAIL_MGMT = "2.0"
    VPC_FLOW         = "2.0"
  }
}

variable "tables" {
  description = "Catalog tables to expose (keyed by identifier used in tenant overrides)."
  type = map(object({
    database_name = string
    table_name    = string
  }))
}

variable "tenants" {
  description = <<DESC
Tenant configuration keyed by tenant identifier:
  tenant_account_id        – Account ID that owns the subscriber slot
  subscriber_external_id   – External ID the tenant provides for RAM/resource-link trust
  query_role_arn           – IAM role in the tenant account granted Lake Formation permissions
  ou_id                    – AWS Organizations OU containing tenant member accounts
  description              – Optional description for RAM share
  sources                  – Optional per-tenant source map (defaults to default_security_lake_sources)
  include_accounts         – Optional additional account IDs beyond the OU membership
  table_overrides          – Optional map keyed by var.tables entries with:
                               * allowed_columns (list)
                               * row_filter_expression (PartiQL string)
DESC
  type = map(object({
    tenant_account_id      = string
    subscriber_external_id = string
    query_role_arn         = string
    ou_id                  = string
    description            = optional(string)
    sources                = optional(map(string))
    include_accounts       = optional(list(string))
    table_overrides = optional(map(object({
      allowed_columns       = optional(list(string))
      row_filter_expression = optional(string)
    })))
  }))
}

variable "tags" {
  description = "Tags applied to all provisioned resources."
  type        = map(string)
  default     = {}
}
