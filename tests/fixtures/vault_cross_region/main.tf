# Main provider for the primary region
provider "aws" {
  region = "us-west-2"
}

# Provider for the cross-region destination
provider "aws" {
  alias  = "cross_region"  # Using underscore instead of hyphen to avoid issues
  region = "us-east-1"
}

module "backup" {
  source = "../../../"
  
  enabled                    = true
  vault_name                 = "cross-region-vault"
  backup_schedule            = "cron(0 7 * * ? *)"
  use_tags                   = true
  backup_resource_tags       = {
    "Backup" = "CrossRegion"
  }
  service_role_name          = "backup-service-role-cross-region"
  
  # Enable cross-region backups
  cross_region_backup_enabled = true
  cross_region_destination    = "us-east-1"
  daily_backup_enabled       = true
  
  # Explicitly set all required variables
  start_window_minutes      = 60
  completion_window_minutes = 180
  opt_in_settings           = {}
  sns_topic_arn            = ""
  backup_resource_types     = []  # Using tags for selection
  
  # Required for cross-region
  providers = {
    aws = aws.cross_region   # Match the alias with underscore
  }
}

output "vault_name" {
  value = module.backup.vault_name
}

output "backup_schedule" {
  value = module.backup.backup_schedule
}

output "cross_region_backup_enabled" {
  value = module.backup.cross_region_backup_enabled
}

output "cross_region_destination" {
  value = module.backup.cross_region_destination
}

output "iam_role_arn" {
  value = module.backup.iam_role_arn
}
