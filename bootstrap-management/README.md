# Management Account Role Bootstrap

Run this mini-module with credentials that already have permissions in the AWS Organizations **management** account. It creates the IAM role that the main Security Lake Terraform stack will assume to register the delegated administrator.

```bash
cd bootstrap-management
terraform init
terraform apply -var 'trusted_principal_arns=["arn:aws:iam::210987654321:role/SecurityLakeTerraform"]'
```

Adjust the trusted principals to whatever automation or user identities should be allowed to run the main stack. The output `delegation_role_arn` feeds the `organization_management_role_name` variable.
