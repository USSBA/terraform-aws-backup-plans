# Enterprise AWS Backup Example

This example demonstrates an enterprise-grade backup strategy with multiple backup tiers and compliance requirements.

## Architecture

This example creates three distinct backup strategies:

1. **Critical Database Backup** - Daily backups for production databases
2. **Application Data Backup** - Daily backups for application resources  
3. **Compliance Backup** - Weekly backups for long-term retention

## Features Demonstrated

- **Multi-tier backup strategy** with different schedules and retention
- **Environment-aware configuration** (dev/staging/prod)
- **Cross-region backup** for production and compliance
- **SNS notifications** for backup status monitoring
- **Tag-based resource selection** for flexible targeting
- **Comprehensive opt-in settings** for different AWS services

## Prerequisites

- AWS CLI configured with administrative permissions
- Terraform 1.0+
- Resources tagged appropriately for backup selection

## Usage

1. Set your environment and cost center:
```bash
export TF_VAR_environment="prod"
export TF_VAR_cost_center="IT-001"
```

2. Deploy the infrastructure:
```bash
terraform init
terraform plan
terraform apply
```

## Resource Tagging Strategy

For this example to work effectively, tag your AWS resources:

### Critical Database Resources
```hcl
tags = {
  BackupTier = "critical"
  Environment = "prod"
  DataClass = "database"
}
```

### Standard Application Resources  
```hcl
tags = {
  BackupTier = "standard"
  Environment = "prod"
  DataClass = "application"
}
```

### Compliance Resources
```hcl
tags = {
  ComplianceBackup = "required"
  Environment = "prod"
  DataClass = "compliance"
  Retention = "7-years"
}
```

## Environment Configurations

| Environment | Retention | Cross-Region | Notifications |
|-------------|-----------|--------------|---------------|
| dev         | 7 days    | No           | Errors only   |
| staging     | 14 days   | No           | Completions   |
| prod        | 90 days   | Yes          | All events    |

## Monitoring

All backup events are sent to the SNS topic: `{environment}-backup-notifications`

Subscribe to this topic to receive:
- Backup job completions
- Backup failures  
- Cross-region copy status
- Compliance backup reports

## Customization

### Backup Schedules
- **Database**: Daily at 2 AM UTC (`cron(0 2 * * ? *)`)
- **Application**: Daily at 3 AM UTC (`cron(0 3 * * ? *)`) 
- **Compliance**: Weekly on Sunday at 1 AM UTC (`cron(0 1 ? * SUN *)`)

### Adding New Backup Types
To add additional backup strategies, create new module blocks following the existing pattern and update the outputs section.

## Cost Optimization

- Dev/staging environments use shorter retention and no cross-region copies
- Compliance backups run weekly instead of daily
- Resource targeting uses tags to avoid backing up unnecessary resources