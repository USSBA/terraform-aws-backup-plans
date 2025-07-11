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

## Notes

- Cold storage is currently only supported for backups of Amazon EBS, Amazon EFS, Amazon DynamoDB, Amazon Timestream, SAP HANA on EC2, and VMware Backup.
- Cold storage backup for DynamoDB is only available when you opt in to advanced features for DynamoDB.
- Resources that do not support cold storage will only be retained for the 30 days in warm storage.

## AWS Backup Managed Policies

This module attaches the following required AWS managed policies by default:

### Required Policies

- `arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup`

### Service Quotas and Limits

#### AWS Backup Service Limits
- **Backup Vaults**: 100 per AWS account per region (soft limit, can be increased)
- **Backup Plans**: 100 per AWS account per region
- **Recovery Points**: 100,000 per backup vault
- **Resource Selection**: 500 resources per backup plan

#### IAM Service Limits
- **Managed Policies per Role**: 20 (10 AWS-managed + 10 customer-managed)
- **Role Name Length**: 64 characters maximum
- **Policy Size**: 2,048 characters for inline policies, 6,144 characters for managed policies

#### Cross-Region Backup
- **Copy Jobs**: 10,000 per account per region
- **Concurrent Copy Jobs**: 1,000 per account per region

> **Note**: These are default limits and can be increased by contacting AWS Support.

### Best Practices
1. Use meaningful names for `vault_name` and `service_role_name` to easily identify resources
2. When using `additional_managed_policies`, ensure they don't exceed the 20-policy limit per role
3. For large-scale deployments, consider using tag-based resource selection to stay within resource limits
4. Monitor your backup jobs using CloudWatch metrics and alarms
5. Regularly test restores to ensure your backup strategy meets your recovery objectives

## Usage

### Basic

```terraform
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"
}
```

### A bit more customization

```terraform
module "backup-plans" {
  source  = "USSBA/backup-plans/aws"
  version = "~> 7.0"

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
