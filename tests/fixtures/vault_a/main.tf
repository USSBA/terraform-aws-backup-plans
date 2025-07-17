# Mock provider for testing
provider "aws" {
  region     = var.region
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style          = true
  
  # Use mock endpoints for local testing
  endpoints {
    sts = "http://localhost:45678"  # Mock endpoint for local testing
  }
}

# Mock cross-region provider
provider "aws" {
  alias  = "cross_region"
  region = var.cross_region_destination
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style          = true
  
  # Use mock endpoints for local testing
  endpoints {
    sts = "http://localhost:45678"  # Mock endpoint for local testing
  }
}

# Define variables used in this fixture
variable "region" {
  type    = string
  default = "us-west-2"
}

variable "cross_region_destination" {
  type    = string
  default = "us-east-1"
}

module "backup" {
  source = "../../.."
  
  providers = {
    aws.cross_region = aws.cross_region
  }
  
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
