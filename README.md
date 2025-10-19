# AWS Security Lake – Multi-tenant Terraform Deployment

This repository provisions Amazon Security Lake in a delegated administrator account and enforces tenant isolation with Lake Formation row/column filters. OU membership is supplied via S3 so new accounts inherit the correct access automatically.

## Architecture Overview

1. **Delegated administrator** (Security Lake account) runs this Terraform.
2. **Management account** is only used to delegate Security Lake via AWS Organizations.
3. **Subscriber accounts** accept the RAM share (or auto-accept via Organizations) and create Lake Formation resource links to query their scoped data.
4. **OU inventory publisher** (deployed by this stack) listens to Organizations events and writes the list of member accounts for each tenant OU to S3 as JSON. Terraform reads this snapshot to build filters.

```
Organizations ──(accounts change)──▶ EventBridge ──▶ Lambda ──▶ S3 (ou-id.json)
                                                      │
Delegated Security Lake acct ──Terraform──────────────┘
```

## Prerequisites

### 1. IAM Roles

| Account | Role | Purpose |
|---------|------|---------|
| Management | `organization_management_role_name` | Allows Terraform to call `organizations:register-delegated-administrator`. Use `bootstrap-management/` to create it if needed. |
| Security Lake delegated account | `security_lake_admin_role_name` | Lets Terraform enable Security Lake, manage Lake Formation, and create subscribers. Use `bootstrap-securitylake/` to create it if needed. |
| Subscriber (per tenant) | `query_role_arn` | Receives Lake Formation `DESCRIBE`/`SELECT` permissions through resource links (see `bootstrap-tenant/` for a helper). |

The machine running Terraform must be able to assume both the management and Security Lake admin roles (via AWS SSO, chained profiles, or federated credentials).

### 2. OU Inventory Automation

This Terraform stack deploys an EventBridge + Lambda solution that keeps `s3://${ou_inventory_bucket}/${ou_inventory_prefix}/${ou_id}.json` synchronized with the current membership of each tenant OU (drawing the OU IDs from the `tenants` map). No external setup is required—set `create_ou_inventory_bucket = true` if you want Terraform to create the bucket, or pre-create it and ensure the Security Lake admin role can write to it.

Example object written by the Lambda:

```json
{
  "ou_id": "ou-exampleroot-tenantA",
  "accounts": [
    "111111111111",
    "222222222222"
  ],
  "generated_at": "2025-01-01T00:00:00+00:00"
}
```

### 3. AWS CLI

The `null_resource` uses `aws lakeformation batch-revoke-permissions` to remove the default `IAM_ALLOWED_PRINCIPALS` grants. Install and configure the AWS CLI in the environment running Terraform (it will inherit the same assumed role credentials).

## Usage

1. **Bootstrap IAM roles** (optional) using the helpers in `bootstrap-management/` and `bootstrap-securitylake/` if these roles do not already exist.
2. **Clone** this repository.
3. Choose the appropriate deployment:
   - Root directory: enables Security Lake and configures sharing end to end.
   - `Existing/`: only applies governance (no enabling/delegation) for an already running Security Lake setup.
4. **Create** a `terraform.tfvars` (or use environment variables) to define required inputs.
5. **Run** the standard Terraform workflow:

```bash
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

### Sample `terraform.tfvars`

```hcl
home_region                        = "us-east-1"
organization_management_account_id = "123456789012"
organization_management_role_name  = "OrganizationAccountAccessRole"
security_lake_account_id           = "210987654321"
security_lake_admin_role_name      = "SecurityLakeTerraform"
ou_inventory_bucket                = "tenant-account-inventory"
ou_inventory_prefix                = "ous"
create_ou_inventory_bucket         = true

tables = {
  cloudtrail = {
    database_name = "aws_security_lake_db"
    table_name    = "aws_security_lake_cloudtrail"
  }
}

tenants = {
  tenantA = {
    tenant_account_id      = "345678901234"
    subscriber_external_id = "tenantA-external"
    query_role_arn         = "arn:aws:iam::345678901234:role/SecurityLakeQuery"
    ou_id                  = "ou-exampleroot-tenantA"
    description            = "Tenant A Security Operations"
  }
}

tags = {
  Project = "SecurityLake"
  Owner   = "SecurityTeam"
}
```

## What Terraform Builds

### In the Security Lake Delegated Account
- Delegated administrator registration (management account).
- `AmazonSecurityLakeMetaStoreManager` role with scoped Glue/LF permissions.
- `aws_securitylake_data_lake` resource (enables Security Lake).
- EventBridge + Lambda automation that refreshes OU membership JSON in the specified S3 bucket (and a daily safety-net schedule).
- Lake Formation settings with `IAM_ALLOWED_PRINCIPALS` disabled.
- Per-tenant Lake Formation Data Cells Filters plus `DESCRIBE`/`SELECT` grants.
- `IAM_ALLOWED_PRINCIPALS` revocation on every shared table.

### In Subscriber Accounts
- `aws_securitylake_subscriber` (RAM share + `LAKEFORMATION` access type).  
  *Subscribers must accept the share if automatic acceptance is not enabled.*
- After acceptance, subscribers create resource links in their own Glue catalog:

```bash
# Example tenant steps (Athena console or CLI)
aws lakeformation create-resource-link \
  --region us-east-1 \
  --resource-arn arn:aws:glue:us-east-1:210987654321:table/aws_security_lake_db/aws_security_lake_cloudtrail \
  --name tenantA_cloudtrail \
  --database tenantA_securitylake_db
```

The resource link surfaces only the filtered data defined by Terraform.

## Outputs

- `security_lake_subscribers` – ARNs and RAM share identifiers per tenant.
- `tenant_row_filters` – PartiQL expressions applied for each tenant/table combination.

Use these outputs to document access policies or feed further automation.

## Operational Guidance

- **Inventory freshness:** If OU membership files are stale, tenant filters will lag behind. Schedule a daily reconciliation job even if EventBridge is in place.
- **Subscriber acceptance:** Automate RAM acceptance from tenant pipelines or request manual confirmation within 12 hours of creation.
- **Testing:** After `terraform apply`, run sample Athena queries in each tenant account to confirm row-level scoping behaves as expected.
- **Change management:** When onboarding a new log source, add it to `tables` and rerun Terraform. When onboarding a new tenant, add an entry to `tenants`; Terraform calculates filters automatically.

## Cleanup

1. Ensure tenants delete resource links and unsubscribe if required.
2. Run `terraform destroy` from the delegated Security Lake account.
3. Optionally disable Security Lake and revoke delegated administrator access.
