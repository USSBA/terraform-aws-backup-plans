# Multiple Backup Vaults Example

This example demonstrates how to create multiple backup vaults with different configurations to handle various backup scenarios in a production environment.

## Architecture

This example creates four distinct backup vaults:

1. **Application Data Backup** - Daily backups for application resources with tag-based exclusions
2. **Database Backup** - Daily backups for production databases with extended windows  
3. **Disaster Recovery** - Critical resource backups with cross-region replication
4. **S3 Backup** - Daily backups for S3 buckets and object data

## Features Demonstrated

- **Environment-specific configuration** (development/staging/production)
- **Multiple backup strategies** with different schedules and retention policies
- **Cross-region backup** for production disaster recovery
- **Tag-based resource selection** and exclusion
- **IAM role customization** with service-specific permissions
- **SNS notifications** for backup monitoring
- **Comprehensive opt-in settings** for AWS Backup services

## Prerequisites

- AWS CLI configured with appropriate permissions
- Terraform 1.12.0+
- AWS resources properly tagged for backup selection

## Usage

1. Set your environment:
```bash
export TF_VAR_environment="production"  # or "development" or "staging"
```

2. Deploy the infrastructure:
```bash
terraform init
terraform plan
terraform apply
```

## Environment Configurations

| Environment | Retention | Cold Storage | Cross-Region |
|-------------|-----------|--------------|--------------|
| development | 7 days    | Disabled     | No           |
| staging     | 14 days   | 30 days      | No           |
| production  | 30 days   | 90 days      | Yes          |

## Resource Tagging Requirements

### Application Resources
```hcl
tags = {
  Environment = "production"  # Required for backup inclusion
  Application = "web-app"
  # BackupExclude = "true"   # Optional: exclude from backups
}
```

### Database Resources  
```hcl
tags = {
  Environment = "production"  # Required for backup inclusion
  Component   = "database"
  Tier        = "production"
}
```

### Critical Resources (for DR)
```hcl
tags = {
  Environment = "production"  # Required for backup inclusion
  Criticality = "high"
  BackupTier  = "critical"
}
```

## Backup Schedules

- **Application Data**: Daily at 2 AM UTC (`cron(0 2 * * ? *)`)
- **Database**: Daily at 2 AM UTC (`cron(0 2 * * ? *)`) 
- **Disaster Recovery**: Daily at 4 AM UTC (`cron(0 4 * * ? *)`)
- **S3 Backup**: Daily at 3 AM UTC (`cron(0 3 * * ? *)`)

## IAM Roles

Each backup vault uses a dedicated IAM role with minimal required permissions:

- `backup-role-{environment}-app-data` - EBS and S3 read access
- `backup-role-{environment}-databases` - Database service full access
- `backup-role-{environment}-dr` - Standard backup and restore policies
- `backup-role-{environment}-s3` - S3 read-only access

## Exclusion Patterns

The application backup excludes resources with:
- `BackupExclude = "true"` tag
- Names containing "test" (e.g., `*test*`)

## Monitoring

For production environments with disaster recovery enabled, backup notifications are sent to:
`arn:aws:sns:us-east-1:123456789012:backup-dr-notifications`

## Cost Optimization

- **Development**: Minimal retention, no cold storage, no cross-region
- **Staging**: Medium retention, cold storage enabled, no cross-region  
- **Production**: Full retention, cold storage, cross-region replication for DR only

## Customization

### Adding New Vault Types
Create additional module blocks following the existing pattern:

```hcl
module "new_backup_type" {
  source = "../.."
  
  enabled    = true
  vault_name = "${var.environment}-new-vault"
  
  # Configure as needed...
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }
}
```

### Modifying Retention
Adjust the `backup_settings` local variable to change retention policies per environment.

### Cross-Region Configuration
Cross-region backups are automatically enabled for production environments and target `us-west-2` by default.