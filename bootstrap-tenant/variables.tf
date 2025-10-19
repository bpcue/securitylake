variable "bootstrap_region" {
  description = "Region where the tenant account IAM role should be created."
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name for the tenant query role."
  type        = string
  default     = "SecurityLakeQueryRole"
}

variable "trusted_principal_arns" {
  description = "Principals allowed to assume the query role (e.g., SSO users, apps)."
  type        = list(string)
}

variable "athena_output_bucket_arn" {
  description = "Optional S3 bucket ARN that will store Athena query results."
  type        = string
  default     = null
}
