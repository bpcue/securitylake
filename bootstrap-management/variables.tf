variable "bootstrap_region" {
  description = "Region to target for IAM operations."
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name for the delegation role Terraform will assume in the management account."
  type        = string
  default     = "SecurityLakeDelegationTerraform"
}

variable "trusted_principal_arns" {
  description = "List of principal ARNs allowed to assume the delegation role (e.g., automation account or humans)."
  type        = list(string)
}
