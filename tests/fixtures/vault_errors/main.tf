# Mock provider for testing error scenarios
provider "aws" {
  region                      = var.region
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    sts    = "http://localhost:45678"
    iam    = "http://localhost:45678"
    backup = "http://localhost:45678"
  }
}

provider "aws" {
  alias                       = "cross_region"
  region                      = var.cross_region_destination
  access_key                  = "mock_access_key"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    sts    = "http://localhost:45678"
    iam    = "http://localhost:45678"
    backup = "http://localhost:45678"
  }
}

variable "region" {
  type    = string
  default = "us-east-1"
}

variable "cross_region_destination" {
  type    = string
  default = "us-west-2"
}

variable "test_scenario" {
  type        = string
  description = "Test scenario to run"
  default     = "valid"

  validation {
    condition = contains([
      "valid",
      "invalid_schedule",
      "missing_role",
      "invalid_arn",
      "empty_vault_name"
    ], var.test_scenario)
    error_message = "Invalid test scenario specified."
  }
}

# Define test scenarios
locals {
  scenarios = {
    valid = {
      enabled           = true
      vault_name        = "test-vault"
      backup_schedule   = "cron(0 2 * * ? *)"
      service_role_name = "test-backup-role"
      resource_arns     = ["arn:aws:rds:us-east-1:123456789012:db:test-db"]
    }

    invalid_schedule = {
      enabled           = true
      vault_name        = "test-vault"
      backup_schedule   = "invalid-cron-expression"
      service_role_name = "test-backup-role"
      resource_arns     = ["arn:aws:rds:us-east-1:123456789012:db:test-db"]
    }

    missing_role = {
      enabled           = true
      vault_name        = "test-vault"
      backup_schedule   = "cron(0 2 * * ? *)"
      service_role_name = ""
      resource_arns     = ["arn:aws:rds:us-east-1:123456789012:db:test-db"]
    }

    invalid_arn = {
      enabled           = true
      vault_name        = "test-vault"
      backup_schedule   = "cron(0 2 * * ? *)"
      service_role_name = "test-backup-role"
      resource_arns     = ["invalid-arn-format"]
    }

    empty_vault_name = {
      enabled           = true
      vault_name        = ""
      backup_schedule   = "cron(0 2 * * ? *)"
      service_role_name = "test-backup-role"
      resource_arns     = ["arn:aws:rds:us-east-1:123456789012:db:test-db"]
    }
  }

  current_scenario = local.scenarios[var.test_scenario]
}

module "backup" {
  source = "../../.."

  providers = {
    aws.cross_region = aws.cross_region
  }

  enabled                     = local.current_scenario.enabled
  vault_name                  = local.current_scenario.vault_name
  backup_schedule             = local.current_scenario.backup_schedule
  service_role_name           = local.current_scenario.service_role_name
  resource_arns               = local.current_scenario.resource_arns
  cross_region_backup_enabled = false
  daily_backup_enabled        = true

  start_window_minutes      = 60
  completion_window_minutes = 180
  opt_in_settings           = {}
  sns_topic_arn             = ""
}

output "vault_name" {
  value = module.backup.vault_name
}

output "backup_schedule" {
  value = module.backup.backup_schedule
}

