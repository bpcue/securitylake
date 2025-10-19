# Tenant Query Role Bootstrap

Use this helper with credentials in each tenant account to create the IAM role that Lake Formation grants permissions to. The resulting role ARN feeds the `query_role_arn` field in your `tenants` map.

Example:

```bash
cd bootstrap-tenant
terraform init
terraform apply \
  -var 'trusted_principal_arns=["arn:aws:iam::210987654321:role/SecurityLakeTerraform"]' \
  -var 'athena_output_bucket_arn=arn:aws:s3:::tenant-athena-results'
```

Adjust the trusted principals and output bucket as needed for your environment.
