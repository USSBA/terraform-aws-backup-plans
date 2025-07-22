# This example demonstrates how to create multiple backup vaults with different configurations
# to handle various backup scenarios in a production environment.

variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, staging, prod)"
  default     = "production"
  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "Environment must be one of: development, staging, production"
  }
}

# Configure the AWS Provider for the primary region
provider "aws" {
  region = "us-east-1"
  # Add other provider configuration as needed (profile, assume role, etc.)
}

# Configure the AWS Provider for cross-region backups
provider "aws" {
  alias  = "cross_region"
  region = "us-west-2" # Default cross-region destination
  # Add other provider configuration as needed (profile, assume role, etc.)
}

# Common tags to be applied to all resources
locals {
  common_tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    Project     = "Backup Strategy"
    CostCenter  = "IT-123"
  }

  # Common backup settings based on environment
  backup_settings = {
    development = {
      retention_days    = 7
      cold_storage_days = 0
      cross_region      = false
    }
    staging = {
      retention_days    = 14
      cold_storage_days = 30
      cross_region      = false
    }
    production = {
      retention_days    = 30
      cold_storage_days = 90
      cross_region      = true
    }
  }

  current_settings = local.backup_settings[var.environment]
}

# Example 1: Application Data Backup
# This example shows how to back up application data using tag-based selection
module "app_data_backup" {
  source = "../.."

  region     = "us-east-1"
  enabled    = true
  vault_name = "${var.environment}-app-data-backup"

  # Backup schedule and settings
  backup_schedule           = "cron(0 2 * * ? *)" # 2 AM UTC (9 PM EST)
  start_window_minutes      = 120                 # 2-hour window to start the backup
  completion_window_minutes = 360                 # 6-hour window to complete the backup

  # Tag-based selection for application data
  use_tags               = true
  daily_backup_tag_key   = "BackupPolicy"
  daily_backup_tag_value = "daily"

  # Additional resource tags for more specific selection
  backup_resource_tags = {
    Environment = var.environment
    DataClass   = "application"
    BackupTier  = "standard"
  }

  # Exclude resources with specific tags
  exclude_conditions = [
    {
      condition_type = "STRINGEQUALS"
      key            = "aws:ResourceTag/BackupExclude"
      value          = "true"
    },
    {
      condition_type = "STRINGLIKE"
      key            = "aws:ResourceTag/Name"
      value          = "*test*"
    }
  ]

  # IAM role configuration with least privilege
  service_role_name = "backup-role-${var.environment}-app-data"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonEBSReadOnlyAccess"
  ]

  # Enable cross-region backup for production
  cross_region_backup_enabled = local.current_settings.cross_region
  cross_region_destination    = "us-west-2"

  # Provider configuration
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "backup"
    Name      = "${var.environment}-app-data-backup"
  })

  # Vault-specific tags
  tags_vault = {
    BackupRetention = "${local.current_settings.retention_days}-days"
    ColdStorage     = local.current_settings.cold_storage_days > 0 ? "enabled" : "disabled"
    DataSensitivity = "medium"
  }

  # Plan-specific tags
  tags_plan = {
    Schedule = "daily"
    Window   = "overnight"
  }
}

# Example 2: Database Backup
# This example demonstrates how to back up database resources using resource type selection
module "database_backup" {
  source = "../.."

  region     = "us-east-1"
  enabled    = true
  vault_name = "${var.environment}-database-backup"

  # Backup schedule during maintenance window
  backup_schedule           = "cron(0 2 * * ? *)" # 2 AM UTC (9 PM EST)
  start_window_minutes      = 180                 # 3-hour window to start the backup
  completion_window_minutes = 480                 # 8-hour window to complete the backup

  # Resource type based selection for databases
  use_tags = false
  backup_resource_types = [
    "RDS",
    "DYNAMODB",
    "DOCDB",
    "NEPTUNE",
    "ELASTICACHE"
  ]

  # Explicitly include specific resources by ARN if needed
  resource_arns = [
    # Example: "arn:aws:rds:us-east-1:123456789012:db:production-db-1"
  ]

  # IAM role configuration with database-specific permissions
  service_role_name = "backup-role-${var.environment}-databases"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonDocDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonNeptuneFullAccess",
    "arn:aws:iam::aws:policy/AmazonElastiCacheFullAccess"
  ]

  # Enable cross-region backup for production
  cross_region_backup_enabled = local.current_settings.cross_region
  cross_region_destination    = "us-west-2"

  # Provider configuration
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "database-backup"
    Name      = "${var.environment}-database-backup"
  })

  # Vault-specific tags
  tags_vault = {
    BackupRetention = "${local.current_settings.retention_days * 2}-days" # Double retention for databases
    ColdStorage     = local.current_settings.cold_storage_days > 0 ? "enabled" : "disabled"
    DataSensitivity = "high"
    RTO             = "4h"  # Recovery Time Objective
    RPO             = "24h" # Recovery Point Objective
  }

  # Plan-specific tags
  tags_plan = {
    Schedule = "daily"
    Window   = "maintenance"
  }

  # Opt-in settings for database services
  opt_in_settings = {
    "ResourcesTypeOptInPreference" = {
      "Aurora"     = true,
      "DynamoDB"   = true,
      "RDS"        = true,
      "DocumentDB" = true,
      "Neptune"    = true
    }
  }
}

# Example 3: Disaster Recovery with Cross-Region Replication
# This example shows how to set up a disaster recovery strategy with cross-region backups
module "disaster_recovery" {
  source = "../.."

  region     = "us-east-1"
  enabled    = var.environment == "production" # Only enable DR for production
  vault_name = "${var.environment}-dr-vault"

  # Backup schedule during off-peak hours
  backup_schedule           = "cron(0 4 * * ? *)" # 4 AM UTC (12 AM EST)
  start_window_minutes      = 240                 # 4-hour window to start the backup
  completion_window_minutes = 720                 # 12-hour window to complete the backup

  # Tag-based selection for critical resources only
  use_tags               = true
  daily_backup_tag_key   = "DisasterRecovery"
  daily_backup_tag_value = "required"

  # Additional selection criteria
  backup_resource_tags = {
    Environment = var.environment
    DataClass   = "critical"
  }

  # Cross-region backup configuration
  cross_region_backup_enabled = true
  cross_region_destination    = "us-west-2" # DR region (different AWS region)

  # IAM role configuration with minimal required permissions
  service_role_name = "backup-role-${var.environment}-dr"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForRestores",
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
    "arn:aws:iam::aws:policy/AmazonRDSReadOnlyAccess"
  ]

  # Provider configuration
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "disaster-recovery"
    Name      = "${var.environment}-dr-backup"
  })

  # Vault-specific tags with extended retention for DR
  tags_vault = {
    BackupRetention = "1-year"
    ColdStorage     = "enabled"
    DataSensitivity = "critical"
    RTO             = "8h"  # Recovery Time Objective
    RPO             = "24h" # Recovery Point Objective
    Compliance      = "hipaa,gdpr"
  }

  # Plan-specific tags
  tags_plan = {
    Schedule = "daily"
    Purpose  = "disaster-recovery"
    Priority = "high"
  }

  # SNS topic for backup notifications
  sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:backup-notifications"

  # Opt-in settings for DR resources
  opt_in_settings = {
    "ResourcesTypeOptInPreference" = {
      "Aurora"          = true,
      "DynamoDB"        = true,
      "EBS"             = true,
      "EC2"             = true,
      "EFS"             = true,
      "FSx"             = true,
      "RDS"             = true,
      "Storage Gateway" = true,
      "VirtualMachine"  = true
    }
  }
}

# Example 4: S3 Bucket Backup with Versioning
# This example shows how to back up S3 buckets with versioning enabled
module "s3_backup" {
  source = "../.."

  region     = "us-east-1"
  enabled    = true
  vault_name = "${var.environment}-s3-backup"

  # Backup schedule during off-peak hours
  backup_schedule           = "cron(0 3 * * ? *)" # 3 AM UTC (10 PM EST)
  start_window_minutes      = 180                 # 3-hour window to start the backup
  completion_window_minutes = 360                 # 6-hour window to complete the backup

  # Target S3 buckets with specific tags
  use_tags               = true
  daily_backup_tag_key   = "S3Backup"
  daily_backup_tag_value = "enabled"

  # Additional selection criteria
  backup_resource_tags = {
    Environment = var.environment
    DataClass   = "s3"
  }

  # IAM role configuration with S3 permissions
  service_role_name = "backup-role-${var.environment}-s3"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess"
  ]

  # Enable cross-region backup for production
  cross_region_backup_enabled = local.current_settings.cross_region
  cross_region_destination    = "us-west-2"

  # Provider configuration
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "s3-backup"
    Name      = "${var.environment}-s3-backup"
  })

  # Vault-specific tags
  tags_vault = {
    BackupRetention = "${local.current_settings.retention_days}-days"
    ColdStorage     = local.current_settings.cold_storage_days > 0 ? "enabled" : "disabled"
    DataSensitivity = "medium"
  }

  # Plan-specific tags
  tags_plan = {
    Schedule = "daily"
    Type     = "s3"
  }
}
