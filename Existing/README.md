# Existing Security Lake Hardening

Use the Terraform in this directory when Security Lake is already enabled and you only need to add tenant-specific sharing, data filters, and the supporting OU inventory automation. Unlike the root deployment, this configuration skips:

- Registering Security Lake as a delegated administrator
- Creating the Security Lake meta store manager role
- Enabling Security Lake itself

## Prerequisites

1. **Security Lake already enabled** in the delegated account.
2. **IAM role** (referenced by `security_lake_admin_role_name`) that Terraform can assume in that account.
3. **Tenant query roles** in each subscriber account (`query_role_arn`).
4. **OU inventory bucket** (optional) or allow Terraform to create it by setting `create_ou_inventory_bucket = true`.

## Usage

1. Populate `Existing/terraform.tfvars` (or pass variables another way).
2. Run:

```bash
cd Existing
terraform init
terraform plan
terraform apply
```

## Outputs

- `security_lake_subscribers` – New or updated subscribers
- `tenant_row_filters` – PartiQL expressions per tenant/table
