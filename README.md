# terraform-aws-backup-plans

This module implements a daily backup plan with a 30-day warm storage retention period and a 90-day cold (Glacier) storage retention period.

## Features

- Configures the AWS Backup service to run daily backups
- Daily backups are retained in warm storage for 30 days and then transferred to cold storage for 90 additional days
- Out of the box will this module will look for a tag key-value of `BackupDaily: true` to initiate a backup
- Grants necessary service role permissions

## Prerequisites

To use this module, ensure you have the following:

- **Terraform:** ~> 1.9
- **AWS Provider:** ~> 5.0
- **AWS Account:** Configured with appropriate permissions

## Inputs

| Name                         | Description                                                                                            | Type        | Default         | Required  |
|------------------------------|--------------------------------------------------------------------------------------------------------|-------------|-----------------|-----------|
| `enabled`                    | Enable/disable creation of all resources in this module.                                               | `bool`      | `true`          | ❌ No     |
| `start_window_minutes`       | Amount of time (in minutes) **before** starting a backup job.                                          | `number`    | `60`            | ❌ No     |
| `completion_window_minutes`  | Amount of time (in minutes) a backup job can run **before** it is automatically canceled.              | `number`    | `180`           | ❌ No     |
| `opt_in_settings`            | Region-specific opt-in choices for AWS Backup (Use `aws backup describe-region-settings` for options). | `map(any)`  | `{}`            | ❌ No     |
| `cross_region_backup_enabled`| Enable/disable cross-region backup **copies**.                                                         | `bool`      | `false`         | ❌ No     |
| `cross_region_destination`   | The region to send cross-region backup copies to.                                                      | `string`    | `"us-west-2"`   | ❌ No     |
| `daily_backup_enabled`       | Enable/disable daily backups.                                                                          | `bool`      | `true`          | ❌ No     |
| `daily_backup_tag_key`       | Tag **key** used to select resources for daily backup.                                                 | `string`    | `"BackupDaily"` | ❌ No     |
| `daily_backup_tag_value`     | Tag **value** used to select resources for daily backup.                                               | `string`    | `"true"`        | ❌ No     |
| `sns_topic_arn`              | Optional SNS topic ARN to receive backup vault notifications.                                          | `string`    | `""`            | ❌ No     |
| `tags`                       | Key/value map of tags to apply to **all** resources.                                                   | `map(any)`  | `{}`            | ❌ No     |
| `tags_vault`                 | Key/value map of tags to apply to backup **vaults**.                                                   | `map(any)`  | `{}`            | ❌ No     |
| `tags_plan`                  | Key/value map of tags to apply to backup **plans**.                                                    | `map(any)`  | `{}`            | ❌ No     |
| `additional_managed_policies` | List of up to 18 additional IAM policy ARNs to attach to the backup service role. | `list(string)` | `[]` | ❌ No |
| `vault_name` | Name of the backup vault. | `string` | `"backup-vault"` | ❌ No |
| `service_role_name` | Name of the IAM role to be created for AWS Backup. If not specified, a name will be generated using the format 'backup-service-role-{vault_name}'. | `string` | `""` | ❌ No |
| `backup_schedule` | Cron expression defining the backup schedule. | `string` | `"cron(0 5 * * ? *)"` | ❌ No |
| `use_tags` | Whether to use tag-based selection for backup resources. If false, uses explicit resource types instead. | `bool` | `true` | ❌ No |
| `backup_resource_types` | List of resource types to back up when `use_tags` is false. | `list(string)` | `[]` | ❌ No |
| `exclude_conditions` | List of key-value pairs to exclude resources from backup. Uses string_equals condition. | `list(object({key=string, value=string}))` | `[]` | ❌ No |

## Exclusion Conditions

You can exclude specific resources from being backed up using the `exclude_conditions` variable. This is useful when you want to back up most resources with a specific tag but exclude certain ones.

### Example: Excluding Resources

```hcl
module "backup" {
  source = "USSBA/backup-plans/aws"
  
  # ... other configurations ...
  
  # Exclude resources with specific tags
  exclude_conditions = [
    {
      key   = "aws:ResourceTag/Environment"
      value = "test"
    },
    {
      key   = "aws:ResourceTag/Backup"
      value = "false"
    }
  ]
}
```

### Notes on Exclusion Conditions

- Exclusion conditions use exact string matching (`string_equals`).
- The `key` should be a valid tag key, typically in the format `aws:ResourceTag/<tagname>`.
- Multiple conditions are combined with AND logic - a resource must match all conditions to be excluded.
- Exclusion conditions are applied after the initial resource selection (by tags or resource types).

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
You can attach up to 18 additional managed policies using the `additional_managed_policies` variable. Here are some commonly used AWS managed policies for backup operations:

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
1. Use tag-based resource selection (`use_tags = true`) for dynamic environments
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

### Resource-Specific Backup Vaults

#### RDS Database Backups
```terraform
module "rds-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  vault_name = "rds-backup-vault"
  
  # Target only RDS databases
  use_tags = false
  backup_resource_types = ["AWS::RDS::DBInstance"]
  
  # Add RDS-specific policies
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess"
  ]
}
```

#### S3 Bucket Backups
```terraform
module "s3-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  vault_name = "s3-backup-vault"
  
  # Target specific S3 buckets by tag
  use_tags = true
  backup_resource_tags = {
    BackupS3 = "true"
  }
  
  # S3 backup policies are included by default
}
```

### Advanced Configuration

```terraform
module "custom-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  # Vault configuration
  vault_name = "production-backups"
  
  # Backup schedule (runs daily at 2 AM UTC)
  backup_schedule = "cron(0 2 * * ? *)"
  
  # Resource selection
  use_tags = true
  backup_resource_tags = {
    Environment = "production"
    Backup      = "enabled"
  }
  
  # Exclude test resources
  exclude_conditions = [
    {
      condition_type = "STRINGEQUALS"
      key            = "aws:ResourceTag/Environment"
      value          = "test"
    }
  ]
  
  # Cross-region backup
  cross_region_backup_enabled = true
  cross_region_destination   = "us-west-2"
  
  # Additional IAM policies
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  ]
  
  # Tags
  tags = {
    Terraform   = "true"
    Environment = "production"
  }
  
  tags_vault = {
    BackupRetention = "90-days"
  }
  
  tags_plan = {
    BackupWindow = "daily"
  }
}
```

## Resource Targeting

### Tag-Based Selection
By default, the module uses tag-based selection to identify resources for backup. You can customize the tag key and value:

```terraform
module "tag-based-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  daily_backup_tag_key   = "BackupPolicy"
  daily_backup_tag_value = "daily"
}
```

### Resource Type Selection
For more control, you can specify resource types directly:

```terraform
module "type-based-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  use_tags = false
  backup_resource_types = [
    "AWS::RDS::DBInstance",
    "AWS::DynamoDB::Table",
    "AWS::EFS::FileSystem"
  ]
}
```

### Advanced Resource Selection
For complex scenarios, you can combine multiple selection methods:

```terraform
module "advanced-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  # Use tags for dynamic resources
  use_tags = true
  backup_resource_tags = {
    Backup = "enabled"
  }
  
  # Include specific resources by ARN
  resource_arns = [
    "arn:aws:rds:us-east-1:123456789012:db:production-db"
  ]
  
  # Exclude resources with specific tags
  exclude_conditions = [
    {
      condition_type = "STRINGEQUALS"
      key            = "aws:ResourceTag/Environment"
      value          = "test"
    },
    {
      condition_type = "STRINGLIKE"
      key            = "aws:ResourceTag/Name"
      value          = "*-test-*"
    }
  ]
}
```

## Cross-Region Backups

To enable cross-region backups, simply set `cross_region_backup_enabled` to `true` and specify the destination region:

```terraform
module "cross-region-backup" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  cross_region_backup_enabled = true
  cross_region_destination   = "us-west-2"  # Destination region for backup copies
  
  # Optional: Customize the backup vault name in the destination region
  vault_name = "primary-region-backups"
}
```

## Monitoring and Notifications

To receive notifications about backup events, specify an SNS topic ARN:

```terraform
module "backup-with-notifications" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
  
  sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:backup-notifications"
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
You can attach up to 18 additional managed policies to the backup service role. Some useful policies include:

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

  # Change the daily backup tag key-value to `AutoBackups = very-yes` for triggering
  daily_backup_tag_key   = "AutoBackups"
  daily_backup_tag_value = "very-yes"
}
```

### Cross-region

To enable cross region copies of backup plans, you must set the `cross_region_backup_enabled` variable to true and optionally set the destination region (defaults to us-west-2)

```terraform
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"

  cross_region_backup_enabled = true
  cross_region_destination = "us-west-2"
}
```

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
