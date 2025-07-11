provider "aws" {
  region = "us-west-2"
}

module "backup" {
  source = "../../../"
  
  enabled                    = true
  vault_name                 = "s3-vault"
  backup_schedule            = "cron(0 6 * * ? *)"
  use_tags                   = true
  backup_resource_tags       = {
    "Backup" = "Daily"
  }
  service_role_name          = "backup-service-role-s3"
  additional_managed_policies = [
    "arn:aws:iam::123456789012:policy/ExtraPolicy"
  ]
  cross_region_backup_enabled = false
  daily_backup_enabled       = true
  
  # Explicitly set all required variables to avoid any defaults causing issues
  start_window_minutes      = 60
  completion_window_minutes = 180
  opt_in_settings           = {}
  sns_topic_arn            = ""
  backup_resource_types     = []  # Empty since we're using tags
}

output "vault_name" {
  value = module.backup.vault_name
}

output "backup_schedule" {
  value = module.backup.backup_schedule
}

output "iam_role_arn" {
  value = module.backup.iam_role_arn
}
