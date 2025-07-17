# Example 1: Tag-based backup for production resources
module "production_backup" {
  source = "../.."

  vault_name      = "production-backup-vault"
  backup_schedule = "cron(0 2 * * ? *)" # 2 AM UTC
  use_tags        = true

  # Tag-based selection using multiple tags
  daily_backup_tag_key   = "Environment"
  daily_backup_tag_value = "production"

  # Additional tags for more specific selection
  backup_resource_tags = {
    BackupTier = "daily"
    Critical   = "true"
  }

  # IAM role with a custom name for better identification
  service_role_name = "backup-role-production"

  # Additional permissions for production resources
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonEC2FullAccess"
  ]
}

# Example 2: Resource-type-based backup for specific services
module "database_backup" {
  source = "../.."

  vault_name      = "database-backup-vault"
  backup_schedule = "cron(0 3 * * ? *)" # 3 AM UTC
  use_tags        = false               # Explicitly disable tag-based selection

  # Explicit resource type selection
  backup_resource_types = [
    "RDS",
    "DOCDB",
    "DYNAMODB"
  ]

  # IAM role with database-specific permissions
  service_role_name = "backup-role-databases"

  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AmazonRDSFullAccess",
    "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess",
    "arn:aws:iam::aws:policy/AmazonDocDBFullAccess"
  ]
}

# Example 3: Cross-region backup with custom retention
module "disaster_recovery" {
  source = "../.."

  vault_name      = "dr-backup-vault"
  backup_schedule = "cron(0 4 * * ? *)" # 4 AM UTC
  use_tags        = true

  # Tag-based selection for critical resources
  daily_backup_tag_key   = "DisasterRecovery"
  daily_backup_tag_value = "required"

  # Cross-region backup configuration
  cross_region_backup_enabled = true
  cross_region_destination    = "us-west-2" # DR region

  # IAM role with cross-region permissions
  service_role_name = "backup-role-dr"

  # Additional policies that might be needed for cross-account/region access
  additional_managed_policies = [
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForRestores"
  ]
}
