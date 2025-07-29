# terraform-aws-backup-plans

[![Integration Tests](https://github.com/USSBA/terraform-aws-backup-plans/actions/workflows/tests.yml/badge.svg)](https://github.com/USSBA/terraform-aws-backup-plans/actions/workflows/tests.yml)

This module implements an AWS Backup solution that automatically backs up resources tagged with `Environment=prod` and `Backup=true` for a given set of matching ARN patterns.

## Features

- **Backup Plans** - Configurable scheduling with cron expressions
- **Cross-Region Backup** - Optional backup replication to different AWS regions
- **IAM Role Management** - Automatic service role creation with default policy attachments
- **SNS Notifications** - Optional backup job status notifications

## Prerequisites

To use this module, ensure you have the following:

- **Terraform:** ~> 1.12.0
- **AWS Provider:** ~> 5.0
- **AWS Account:** Configured with appropriate permissions

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| `region` | The AWS region where resources will be created. | `string` | `"us-east-1"` | ❌ No |
| `start_window_minutes` | Time window (minutes) before starting a backup job. | `number` | `60` | ❌ No |
| `completion_window_minutes` | Maximum time (minutes) a backup job can run before being canceled. | `number` | `180` | ❌ No |
| `cross_region_backup_enabled` | Enable/disable cross-region backup copies. | `bool` | `false` | ❌ No |
| `cross_region_destination` | Destination region for cross-region backups. | `string` | `"us-west-2"` | ❌ No |
| `vault_name` | Name of the backup vault. | `string` | `"DefaultBackupVault"` | ❌ No |
| `backup_schedule` | Cron expression for backup schedule. | `string` | `"cron(0 5 * * ? *)"` (5 AM UTC) | ❌ No |
| `sns_topic_arn` | SNS topic ARN for backup vault notifications. | `string` | `""` | ❌ No |
| `resource_arns` | Optional list of specific resource ARNs or ARN patterns to include in backup selection. If empty, the module will automatically discover all resources with Environment=prod tag. | `list(string)` | `[]` | ❌ No |
| `additional_managed_policies` | Additional IAM policy ARNs (max 16) to attach to the backup service role. Combined with required AWS Backup policies (max 20 total). | `list(string)` | `[]` | ❌ No |

## Usage

### Opinionated (Recommended) - Auto-Discovery

The simplest way to use this module is to let it automatically discover all your production resources:

```hcl
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "cross_region"
  region = "us-west-2"
}

# Minimal configuration - backs up ALL resources tagged Environment=prod
module "production_backup" {
  source = "path/to/terraform-aws-backup-plans"

  backup_schedule             =  "cron(0 2 * * ? *)"  # 2 AM UTC daily
  vault_name                  =  "production-rds-vault"
  resource_arns               =  ["arn:aws:rds:us-east-1:000000000000:cluster:*"]
  cross_region_backup_enabled = true
  cross_region_destination    = "us-west-2"

  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }
}
```

### Important Notes

- **Tag Requirements**: Resources must be tagged with `Environment=prod` and `Backup=true` to be included in backups
- **Provider Configuration**: Cross-region provider is required even if cross-region backup is disabled

## Vault Naming Convention

### Name Format

- Use hyphens (`-`) as word separators in vault names (e.g., `production-backup-vault`)
- Avoid using underscores (`_`) as they are being deprecated in favor of hyphens
- Vault names must be between 1 and 50 characters long
- Must be unique within an AWS Region for your AWS account

### Migrating from Underscores to Hyphens

When renaming a vault from using underscores to hyphens, follow these steps to ensure a smooth transition without data loss:

1. **Create the New Vault**

   - Update your Terraform configuration with the new vault name using hyphens
   - Run `terraform plan` to verify the changes
   - Apply the changes with `terraform apply` to create the new vault

2. **Copy Backups to the New Vault**

   Use the AWS CLI to copy recovery points from the old vault to the new one:

   ```bash
   # List recovery points in the old vault
   OLD_VAULT="old_vault_name"
   NEW_VAULT="new-vault-name"

   # Get list of recovery points
   RECOVERY_POINTS=$(aws backup list-recovery-points-by-backup-vault \
     --backup-vault-name $OLD_VAULT \
     --query 'RecoveryPoints[].RecoveryPointArn' \
     --output text)

   # Copy each recovery point to the new vault
   for RP_ARN in $RECOVERY_POINTS; do
     BACKUP_JOB_ID=$(aws backup start-copy-job \
       --recovery-point-arn $RP_ARN \
       --source-backup-vault-name $OLD_VAULT \
       --destination-backup-vault-arn arn:aws:backup:REGION:ACCOUNT_ID:backup-vault:$NEW_VAULT \
       --iam-role-arn arn:aws:iam::ACCOUNT_ID:role/service-role/AWSBackupDefaultServiceRole \
       --query 'CopyJobId' \
       --output text)
     echo "Started copy job $BACKUP_JOB_ID for $RP_ARN"
   done
   ```

3. **Verify the Copy Operations**

   ```bash
   # Check status of copy jobs
   aws backup describe-copy-job --copy-job-id YOUR_COPY_JOB_ID

   # List recovery points in the new vault to verify
   aws backup list-recovery-points-by-backup-vault --backup-vault-name $NEW_VAULT
   ```

4. **Update References**

   - Update any IAM policies, backup plans, or other resources that reference the old vault name
   - Update any monitoring or alerting systems

5. **Retire the Old Vault (Optional)**

   - After verifying all backups are successfully copied and accessible in the new vault
   - Consider removing the old vault if it's no longer needed
   - You may want to keep it for a transition period to ensure everything works as expected

### Example Vault Names

```hcl
# Recommended format with hyphens
module "backup" {
  source     = "USSBA/backup-plans/aws"
  vault_name = "production-backup-vault"
}

# Deprecated format with underscores (avoid)
module "backup_old" {
  source     = "USSBA/backup-plans/aws"
  vault_name = "production_backup_vault"  # Not recommended
}
```

## Notes

- Cold storage is currently only supported for backups of Amazon EBS, Amazon EFS, Amazon DynamoDB, Amazon Timestream, SAP HANA on EC2, and VMware Backup.
- Cold storage backup for DynamoDB is only available when you opt in to advanced features for DynamoDB.
- Resources that do not support cold storage will only be retained for the 30 days in warm storage.

## AWS Backup Managed Policies

### Required Policies
This module automatically attaches the following AWS managed policies to the backup service role:

- `arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup` - Required for backup operations
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup` - Required for S3 backup operations
- `arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores` - Required for restore operations
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore` - Required for S3 restore operations

### Additional Available AWS Managed Policies
You can attach up to 16 additional managed policies using the `additional_managed_policies` variable. Here are some commonly used AWS managed policies for backup operations:

#### Backup Operation Policies
- `arn:aws:iam::aws:policy/AWSBackupFullAccess` - Full access to AWS Backup features
- `arn:aws:iam::aws:policy/AWSBackupOperatorAccess` - Permissions for backup operators
- `arn:aws:iam::aws:policy/AWSBackupAuditAccess` - Read-only access to view backup configurations
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForBackup` - Permissions for backup operations
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForRestores` - Permissions for restore operations

#### Service-Specific Backup Policies
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup` - For S3 backup operations
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore` - For S3 restore operations
- `arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackupTest` - For backup testing
- `arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForSAPHANA` - For SAP HANA database backups

### Service Quotas and Limits

#### AWS Backup Service Limits
- **Backup Vaults**: 100 per AWS account per region (soft limit, can be increased)
- **Backup Plans**: 100 per AWS account per region
- **Recovery Points**: 100,000 per backup vault
- **Resource Selection**: 500 resources per backup plan

#### IAM Service Limits
- **Managed Policies per Role**: 20 total (default limit of 10, can be increased to 20)
- **Role Name Length**: 64 characters maximum
- **Policy Size**: 6,144 characters maximum for managed policies
- **Policy Document Size**: 10,240 characters maximum

#### Cross-Region Backup
- **Copy Jobs**: 10,000 per account per region
- **Concurrent Copy Jobs**: 1,000 per account per region

> **Note**: The default limit for managed policies per role is 10 (5 AWS-managed + 5 customer-managed). You can request an increase to 20 (10 AWS-managed + 10 customer-managed) through the AWS Support Center.

### Best Practices

#### Naming and Organization
1. Use meaningful, descriptive names for `vault_name` and `service_role_name` to easily identify resources
2. Follow a consistent naming convention across all backup resources (e.g., `{env}-{app}-{purpose}`)
3. Use tags consistently to manage and organize backup resources

#### Policy Management
1. When using `additional_managed_policies`, ensure they don't exceed the 20-policy limit per role
2. Prefer using AWS managed policies over custom policies when possible
3. Regularly review and audit IAM policies for least privilege access

#### Resource Selection
1. Use tag-based resource selection (` = true`) for dynamic environments
2. For static environments, consider using explicit resource ARNs for better control
3. Use the `exclude_conditions` variable to filter out resources that shouldn't be backed up
4. When backing up S3 buckets, ensure versioning is enabled for point-in-time recovery

#### Monitoring and Maintenance
1. Set up CloudWatch Alarms for backup job failures
2. Monitor backup storage usage and retention periods
3. Regularly test restores to ensure your backup strategy meets your recovery objectives
4. Review and update backup policies as your infrastructure evolves

#### Security
1. Enable encryption for all backup vaults (enabled by default)
2. Use AWS KMS CMKs for encryption when additional control over encryption keys is required
3. Implement backup vault access policies to restrict who can manage backups
4. Enable MFA delete for critical backup vaults

## Usage Examples

### Basic Configuration
```terraform
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
}
```

## IAM Permissions

### Required Permissions
The IAM role created by this module requires the following permissions:
- `backup:CreateBackupVault`
- `backup:CreateBackupPlan`
- `backup:CreateBackupSelection`
- `backup:StartBackupJob`
- `backup:StartCopyJob` (if cross-region backup is enabled)
- Plus various read permissions for resource discovery and monitoring

### Custom IAM Policies
You can attach up to 16 additional managed policies to the backup service role. Some useful policies include:

```terraform
module "backup-with-custom-policies" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"

  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonEFSFullAccess"
  ]
}
```

## Troubleshooting

### Common Issues

#### Backup Job Fails with "Insufficient Permissions"
1. Verify the IAM role has the necessary permissions
2. Check if the role's trust relationship allows the backup service to assume it
3. Ensure any additional policies attached don't conflict with required permissions

#### Resources Not Being Backed Up
1. Verify the resource tags match your backup selection criteria
2. Check if the resource type is supported by AWS Backup
3. Ensure the IAM role has permissions to back up the specific resource type

#### Cross-Region Backup Fails
1. Verify the destination region is enabled in your AWS account
2. Check if there are any VPC endpoint or network ACL restrictions
3. Ensure the IAM role has permissions to create resources in the destination region

## Contributing

We welcome contributions.
To contribute please read our [CONTRIBUTING](CONTRIBUTING.md) document.

All contributions are subject to the license and in no way imply compensation for contributions.

## Code of Conduct

We strive for a welcoming and inclusive environment for all SBA projects.

Please follow this guidelines in all interactions:

- Be Respectful: use welcoming and inclusive language.
- Assume best intentions: seek to understand other's opinions.

## Security Policy

Please do not submit an issue on GitHub for a security vulnerability.
Instead, contact the development team through [HQVulnerabilityManagement](mailto:HQVulnerabilityManagement@sba.gov).
Be sure to include **all** pertinent information.

The agency reserves the right to change this policy at any time.
