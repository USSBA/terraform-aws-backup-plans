# This example demonstrates how to create multiple backup vaults with different configurations
# to handle various backup scenarios in a production environment.

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

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

  enabled    = true
  vault_name = "${var.environment}-app-data-backup"

  # Backup schedule and settings
  backup_schedule           = "cron(0 2 * * ? *)" # 2 AM UTC (9 PM EST)
  start_window_minutes      = 120                 # 2-hour window to start the backup
  completion_window_minutes = 360                 # 6-hour window to complete the backup

  # Resource selection via ARNs (module hardcodes Environment=prod tag)
  resource_arns = [
    "arn:aws:ec2:us-east-1:*:volume/*",
    "arn:aws:rds:us-east-1:*:db:*",
    "arn:aws:s3:::app-data-*/*"
  ]

  # Exclude resources with specific tags
  exclude_conditions = [
    {
      key   = "aws:ResourceTag/BackupExclude"
      value = "true"
    },
    {
      key   = "aws:ResourceTag/Name"
      value = "*test*"
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

  # Tags for backup resources
  tags_vault = merge(local.common_tags, {
    Component       = "backup"
    Name            = "${var.environment}-app-data-backup"
    BackupRetention = "${local.current_settings.retention_days}-days"
    ColdStorage     = local.current_settings.cold_storage_days > 0 ? "enabled" : "disabled"
    DataSensitivity = "medium"
  })

  tags_plan = {
    Component = "backup"
    Schedule  = "daily"
    Window    = "overnight"
  }
}

# Example 2: Database Backup
# This example demonstrates how to back up database resources using resource type selection
module "database_backup" {
  source = "../.."

  enabled    = true
  vault_name = "${var.environment}-database-backup"

  # Backup schedule during maintenance window
  backup_schedule           = "cron(0 2 * * ? *)" # 2 AM UTC (9 PM EST)
  start_window_minutes      = 180                 # 3-hour window to start the backup
  completion_window_minutes = 480                 # 8-hour window to complete the backup

  # Database resource selection via ARNs
  resource_arns = [
    "arn:aws:rds:us-east-1:*:db:production-*",
    "arn:aws:dynamodb:us-east-1:*:table/production-*",
    "arn:aws:docdb:us-east-1:*:cluster:production-*"
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

  # Tags for backup resources
  tags_vault = merge(local.common_tags, {
    Component       = "database-backup"
    Name            = "${var.environment}-database-backup"
    BackupRetention = "${local.current_settings.retention_days * 2}-days" # Double retention for databases
    ColdStorage     = local.current_settings.cold_storage_days > 0 ? "enabled" : "disabled"
    DataSensitivity = "high"
    RTO             = "4h"  # Recovery Time Objective
    RPO             = "24h" # Recovery Point Objective
  })

  tags_plan = {
    Component = "database-backup"
    Schedule  = "daily"
    Window    = "maintenance"
  }

  # Opt-in settings for database services
  opt_in_settings = {
    "Aurora"     = true
    "DynamoDB"   = true
    "RDS"        = true
    "DocumentDB" = true
    "Neptune"    = true
  }
}

# Example 3: Disaster Recovery with Cross-Region Replication
# This example shows how to set up a disaster recovery strategy with cross-region backups
module "disaster_recovery" {
  source = "../.."

  enabled    = var.environment == "production" # Only enable DR for production
  vault_name = "${var.environment}-dr-vault"

  # Backup schedule during off-peak hours
  backup_schedule           = "cron(0 4 * * ? *)" # 4 AM UTC (12 AM EST)
  start_window_minutes      = 240                 # 4-hour window to start the backup
  completion_window_minutes = 720                 # 12-hour window to complete the backup

  # Critical resource selection for DR
  resource_arns = [
    "arn:aws:rds:us-east-1:*:db:critical-*",
    "arn:aws:dynamodb:us-east-1:*:table/critical-*",
    "arn:aws:ec2:us-east-1:*:volume/vol-critical-*"
  ]

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

  # Vault-specific tags with extended retention for DR
  tags_vault = merge(local.common_tags, {
    Component       = "disaster-recovery"
    Name            = "${var.environment}-dr-backup"
    BackupRetention = "1-year"
    ColdStorage     = "enabled"
    DataSensitivity = "critical"
    RTO             = "8h"  # Recovery Time Objective
    RPO             = "24h" # Recovery Point Objective
    Compliance      = "hipaa,gdpr"
  })

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
    "Aurora"          = true
    "DynamoDB"        = true
    "EBS"             = true
    "EC2"             = true
    "EFS"             = true
    "FSx"             = true
    "RDS"             = true
    "Storage Gateway" = true
    "VirtualMachine"  = true
  }
}

# Example 4: S3 Bucket Backup with Versioning
# This example shows how to back up S3 buckets with versioning enabled
module "s3_backup" {
  source = "../.."

  enabled    = true
  vault_name = "${var.environment}-s3-backup"

  # Backup schedule during off-peak hours
  backup_schedule           = "cron(0 3 * * ? *)" # 3 AM UTC (10 PM EST)
  start_window_minutes      = 180                 # 3-hour window to start the backup
  completion_window_minutes = 360                 # 6-hour window to complete the backup

  # S3 bucket selection via ARNs
  resource_arns = [
    "arn:aws:s3:::${var.environment}-app-data-*/*",
    "arn:aws:s3:::${var.environment}-user-uploads-*/*"
  ]

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

  # Vault-specific tags
  tags_vault = merge(local.common_tags, {
    Component       = "s3-backup"
    Name            = "${var.environment}-s3-backup"
    BackupRetention = "${local.current_settings.retention_days}-days"
    ColdStorage     = local.current_settings.cold_storage_days > 0 ? "enabled" : "disabled"
    DataSensitivity = "medium"
  })

  # Plan-specific tags
  tags_plan = {
    Schedule = "daily"
    Type     = "s3"
  }
}
