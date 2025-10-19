variable "home_region" {
  description = "Region hosting the existing Security Lake deployment."
  type        = string
}

variable "security_lake_account_id" {
  description = "Account ID of the Security Lake delegated administrator."
  type        = string
}

variable "security_lake_admin_role_name" {
  description = "Role Terraform assumes in the Security Lake account."
  type        = string
}

variable "ou_inventory_bucket" {
  description = "S3 bucket containing OU membership JSON documents."
  type        = string
}

variable "ou_inventory_prefix" {
  description = "Prefix within the inventory bucket for OU JSON files."
  type        = string
  default     = "ous"
}

variable "create_ou_inventory_bucket" {
  description = "Set to true to let Terraform create and manage the OU inventory S3 bucket."
  type        = bool
  default     = false
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
  description = "Tenant configuration map (same structure as main deployment)."
  type = map(object({
    tenant_account_id        = string
    subscriber_external_id   = string
    query_role_arn           = string
    ou_id                    = string
    description              = optional(string)
    sources                  = optional(map(string))
    include_accounts         = optional(list(string))
    table_overrides          = optional(map(object({
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
