# Mock provider for testing SNS notifications
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
    sns    = "http://localhost:45678"
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
    sns    = "http://localhost:45678"
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

# Mock SNS topic for testing
resource "aws_sns_topic" "backup_notifications" {
  name = "test-backup-notifications"

  tags = {
    Purpose     = "backup-testing"
    Environment = "test"
  }
}

module "backup" {
  source = "../../.."

  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  enabled         = true
  vault_name      = "sns-test-vault"
  backup_schedule = "cron(0 5 * * ? *)"

  service_role_name = "backup-service-role-sns-test"
  resource_arns     = ["arn:aws:rds:us-east-1:123456789012:db:test-db"]

  # Configure SNS notifications with static ARN for testing
  sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:test-backup-notifications"

  cross_region_backup_enabled = false
  daily_backup_enabled        = true

  start_window_minutes      = 60
  completion_window_minutes = 180
  opt_in_settings           = {}

  tags_vault = {
    TestType = "sns-notifications"
  }

  tags_plan = {
    TestType = "sns-notifications"
    Purpose  = "testing"
  }
}

output "vault_name" {
  value = module.backup.vault_name
}

output "backup_schedule" {
  value = module.backup.backup_schedule
}

output "sns_topic_arn" {
  value = aws_sns_topic.backup_notifications.arn
}