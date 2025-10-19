# Security Lake Admin Role Bootstrap

Run this module with credentials that already have IAM permission in the delegated Security Lake account. It creates the IAM role that the primary Terraform stack assumes to manage Security Lake, Lake Formation, Lambda, and supporting resources.

Example usage:

```bash
cd bootstrap-securitylake
terraform init
terraform apply \
  -var 'trusted_principal_arns=["arn:aws:iam::123456789012:role/SecurityLakeDelegationTerraform"]'
```

Optionally supply `additional_policy_arns` if you want to attach AWS-managed policies alongside the inline policy defined here. The output `security_lake_admin_role_arn` feeds the `security_lake_admin_role_name` variable in the main stack.
