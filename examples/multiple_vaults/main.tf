variable "environment" {
  type        = string
  description = "The environment name (e.g., dev, staging, prod)"
  default     = "production"
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
  }
}

# Example 1: Tag-based backup for production resources
module "production_backup" {
  source = "../.."

  region     = "us-east-1"
  enabled    = true
  vault_name = "production-backup-vault"

  # Backup schedule and settings
  backup_schedule           = "cron(0 5 * * ? *)" # 5 AM UTC (default)
  start_window_minutes      = 60
  completion_window_minutes = 180

  # Tag-based selection
  use_tags               = true
  daily_backup_tag_key   = "BackupDaily"
  daily_backup_tag_value = "true"

  # Additional resource tags for more specific selection
  backup_resource_tags = {
    Environment = "production"
    BackupTier  = "daily"
    Critical    = "true"
  }

  # IAM role configuration
  service_role_name = "backup-role-${var.environment}-production"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]

  # Provider configuration
  providers = {
    aws              = aws              # Primary provider for resources
    aws.cross_region = aws.cross_region # Cross-region provider (required by the module)
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "backup"
    Name      = "production-backup"
  })

  tags_vault = {
    BackupRetention = "30-days"
  }

  tags_plan = {
    Schedule = "daily"
  }
}

# Example 2: Resource-type-based backup for specific services
module "database_backup" {
  source = "../.."

  region     = "us-east-1"
  enabled    = true
  vault_name = "database-backup-vault"

  # Backup schedule and settings
  backup_schedule           = "cron(0 5 * * ? *)" # 5 AM UTC
  start_window_minutes      = 120                 # Longer window for database backups
  completion_window_minutes = 240                 # 4 hour completion window

  # Resource type based selection
  use_tags = false
  backup_resource_types = [
    "RDS",
    "DOCDB",
    "DYNAMODB"
  ]

  # IAM role configuration
  service_role_name = "backup-role-${var.environment}-databases"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonDocDBFullAccess"
  ]

  # Provider configuration
  providers = {
    aws              = aws              # Primary provider for resources
    aws.cross_region = aws.cross_region # Cross-region provider (required by the module)
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "database-backup"
    Name      = "database-backup"
  })

  tags_vault = {
    BackupRetention = "90-days"
    DataSensitivity = "high"
  }

  tags_plan = {
    Schedule = "daily"
  }
}

# Example 3: Cross-region backup with custom retention
module "disaster_recovery" {
  source = "../.."

  region     = "us-east-1"
  enabled    = true
  vault_name = "dr-backup-vault"

  # Backup schedule and settings
  backup_schedule           = "cron(0 6 * * ? *)" # 6 AM UTC
  start_window_minutes      = 60
  completion_window_minutes = 180

  # Tag-based selection for critical resources
  use_tags               = true
  daily_backup_tag_key   = "DisasterRecovery"
  daily_backup_tag_value = "required"

  # Cross-region backup configuration
  cross_region_backup_enabled = true
  cross_region_destination    = "us-west-2" # DR region

  # IAM role configuration
  service_role_name = "backup-role-${var.environment}-dr"
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForRestores"
  ]

  # Provider configuration
  providers = {
    aws              = aws              # Primary provider for resources
    aws.cross_region = aws.cross_region # Cross-region provider for DR
  }

  # Tags for resources
  tags = merge(local.common_tags, {
    Component = "disaster-recovery"
    Name      = "cross-region-dr"
  })

  tags_vault = {
    BackupRetention = "1-year"
    DataSensitivity = "critical"
  }

  tags_plan = {
    Schedule = "daily"
    Purpose  = "disaster-recovery"
  }

  # Opt-in settings for the region
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
