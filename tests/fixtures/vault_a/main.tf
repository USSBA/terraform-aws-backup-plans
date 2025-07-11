provider "aws" {
  region = "us-west-2"
}

module "backup" {
  source = "../../../"
  
  enabled                    = true
  vault_name                 = "rds-vault"
  backup_schedule            = "cron(0 5 * * ? *)"
  use_tags                   = false
  backup_resource_types      = ["rds:db"]
  service_role_name          = "backup-service-role-rds"
  cross_region_backup_enabled = false
  daily_backup_enabled       = true
  
  # Explicitly set all required variables to avoid any defaults causing issues
  start_window_minutes      = 60
  completion_window_minutes = 180
  opt_in_settings           = {}
  sns_topic_arn            = ""
  backup_resource_tags      = {}
}

output "vault_name" {
  value = module.backup.vault_name
}

output "backup_schedule" {
  value = module.backup.backup_schedule
}

output "backup_resource_types" {
  value = module.backup.backup_resource_types
}

output "iam_role_arn" {
  value = module.backup.iam_role_arn
}
