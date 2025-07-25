# Enterprise AWS Backup Example
# This example demonstrates enterprise-grade backup configuration with multiple backup strategies

variable "environment" {
  type        = string
  description = "Environment name"
  default     = "prod"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "cost_center" {
  type        = string
  description = "Cost center for billing"
  default     = "IT-001"
}

# Configure providers
provider "aws" {
  region = "us-east-1"
}

provider "aws" {
  alias  = "dr_region"
  region = "us-west-2"
}

# Common locals
locals {
  common_tags = {
    Environment      = var.environment
    ManagedBy        = "Terraform"
    CostCenter       = var.cost_center
    BackupCompliance = "required"
  }

  # Environment-specific backup settings
  backup_config = {
    dev = {
      retention_days     = 7
      cross_region       = false
      notification_level = "ERROR"
    }
    staging = {
      retention_days     = 14
      cross_region       = false
      notification_level = "COMPLETED"
    }
    prod = {
      retention_days     = 90
      cross_region       = true
      notification_level = "ALL"
    }
  }

  current_config = local.backup_config[var.environment]
}

# SNS topic for backup notifications (enterprise requirement)
resource "aws_sns_topic" "backup_notifications" {
  name = "${var.environment}-backup-notifications"

  tags = merge(local.common_tags, {
    Purpose = "backup-notifications"
  })
}

# 1. Critical Database Backup (RDS/Aurora)
module "database_backup" {
  source = "../.."

  enabled         = true
  vault_name      = "${var.environment}-database-vault"
  backup_schedule = "cron(0 2 * * ? *)" # 2 AM UTC

  # Database resource selection via ARNs
  resource_arns = [
    "arn:aws:rds:us-east-1:*:db:${var.environment}-*",
    "arn:aws:dynamodb:us-east-1:*:table/${var.environment}-*",
    "arn:aws:docdb:us-east-1:*:cluster:${var.environment}-*"
  ]

  # Cross-region for production
  cross_region_backup_enabled = local.current_config.cross_region
  cross_region_destination    = "us-west-2"

  # Extended windows for large databases
  start_window_minutes      = 180 # 3 hours
  completion_window_minutes = 480 # 8 hours

  service_role_name = "backup-role-${var.environment}-database"

  # SNS notifications
  sns_topic_arn = aws_sns_topic.backup_notifications.arn

  # Opt-in for database services
  opt_in_settings = {
    "Aurora"     = true
    "RDS"        = true
    "DynamoDB"   = true
    "DocumentDB" = true
  }

  providers = {
    aws              = aws
    aws.cross_region = aws.dr_region
  }

  tags = merge(local.common_tags, {
    Component = "database-backup"
    Priority  = "critical"
  })
}

# 2. Application Data Backup (EBS, EFS)
module "application_backup" {
  source = "../.."

  enabled         = true
  vault_name      = "${var.environment}-application-vault"
  backup_schedule = "cron(0 3 * * ? *)" # 3 AM UTC

  # Application resource selection via ARNs
  resource_arns = [
    "arn:aws:ec2:us-east-1:*:volume/${var.environment}-*",
    "arn:aws:efs:us-east-1:*:file-system/${var.environment}-*",
    "arn:aws:ec2:us-east-1:*:instance/${var.environment}-*"
  ]

  cross_region_backup_enabled = local.current_config.cross_region
  cross_region_destination    = "us-west-2"

  service_role_name = "backup-role-${var.environment}-application"
  sns_topic_arn     = aws_sns_topic.backup_notifications.arn

  opt_in_settings = {
    "EBS" = true
    "EFS" = true
    "EC2" = true
  }

  providers = {
    aws              = aws
    aws.cross_region = aws.dr_region
  }

  tags = merge(local.common_tags, {
    Component = "application-backup"
    Priority  = "standard"
  })
}

# 3. Archive/Compliance Backup (Long-term retention)
module "compliance_backup" {
  source = "../.."

  enabled         = true
  vault_name      = "${var.environment}-compliance-vault"
  backup_schedule = "cron(0 1 ? * SUN *)" # Weekly on Sunday at 1 AM

  # Compliance resource selection via ARNs
  resource_arns = [
    "arn:aws:rds:us-east-1:*:db:compliance-*",
    "arn:aws:dynamodb:us-east-1:*:table/compliance-*",
    "arn:aws:s3:::compliance-*/*",
    "arn:aws:efs:us-east-1:*:file-system/compliance-*"
  ]

  # Always enable cross-region for compliance
  cross_region_backup_enabled = true
  cross_region_destination    = "us-west-2"

  # Longer windows for compliance backups
  start_window_minutes      = 240 # 4 hours
  completion_window_minutes = 720 # 12 hours

  service_role_name = "backup-role-${var.environment}-compliance"
  sns_topic_arn     = aws_sns_topic.backup_notifications.arn

  # Comprehensive opt-in for compliance
  opt_in_settings = {
    "Aurora"          = true
    "DynamoDB"        = true
    "EBS"             = true
    "EC2"             = true
    "EFS"             = true
    "FSx"             = true
    "RDS"             = true
    "Storage Gateway" = true
  }

  providers = {
    aws              = aws
    aws.cross_region = aws.dr_region
  }

  tags = merge(local.common_tags, {
    Component = "compliance-backup"
    Priority  = "compliance"
    Retention = "long-term"
  })
}

# Outputs for monitoring and integration
output "backup_vault_arns" {
  description = "ARNs of all created backup vaults"
  value = {
    database    = module.database_backup.vault_name
    application = module.application_backup.vault_name
    compliance  = module.compliance_backup.vault_name
  }
}

output "backup_schedules" {
  description = "Backup schedules for all vaults"
  value = {
    database    = module.database_backup.backup_schedule
    application = module.application_backup.backup_schedule
    compliance  = module.compliance_backup.backup_schedule
  }
}

output "sns_topic_arn" {
  description = "SNS topic ARN for backup notifications"
  value       = aws_sns_topic.backup_notifications.arn
}