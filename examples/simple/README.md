# Simple AWS Backup Example

This example demonstrates both the **opinionated** (auto-discovery) and **override** approaches to using the AWS Backup module.

## What This Example Does

### Opinionated Backup (Recommended)
- Creates a backup vault with minimal configuration
- **Automatically discovers and backs up ALL resources** tagged with `Environment=prod`
- Uses sensible defaults for scheduling and retention
- **"Just works" approach** - perfect for most use cases

### Override Backup (Power Users)
- Shows how to target specific resources when needed
- Demonstrates custom scheduling
- Useful for specialized backup requirements

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform installed
- Resources tagged with `Environment=prod` for auto-discovery

## Usage

### Option 1: Opinionated (Recommended)
Just specify a vault name - the module handles everything else:

```bash
terraform init
terraform plan
terraform apply
```

All production resources will be automatically discovered and backed up.

### Option 2: Override for Specific Resources
The second module example shows how to target specific resources when you need fine-grained control.

## Tagging Requirements

For auto-discovery to work, tag your AWS resources:

```hcl
tags = {
  Environment = "prod"  # Required for backup inclusion
  # ... other tags
}
```

## Customization

- **Change timing**: Modify `backup_schedule` (uses cron format)
- **Cross-region backups**: Set `cross_region_backup_enabled = true`
- **Specific resources**: Use `resource_arns` to override auto-discovery
- **Exclude resources**: Use `exclude_conditions` for fine-grained exclusion