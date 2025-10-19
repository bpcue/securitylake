variable "bootstrap_region" {
  description = "Region to target for IAM operations (use the Security Lake home region)."
  type        = string
  default     = "us-east-1"
}

variable "role_name" {
  description = "Name for the Security Lake admin role Terraform will assume."
  type        = string
  default     = "SecurityLakeTerraform"
}

variable "trusted_principal_arns" {
  description = "List of principal ARNs allowed to assume the Security Lake admin role (e.g., pipelines, engineers)."
  type        = list(string)
}

variable "additional_policy_arns" {
  description = "Optional managed policies to attach to the role."
  type        = list(string)
  default     = []
}
