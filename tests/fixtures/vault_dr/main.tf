# Mock provider for testing
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

# Mock cross-region provider for DR
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

module "backup" {
  source = "../../.."

  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  enabled         = true
  vault_name      = "disaster-recovery-vault"
  backup_schedule = "cron(0 4 * * ? *)"

  service_role_name = "backup-service-role-dr"

  # Use ARN-based selection for critical DR resources
  resource_arns = [
    "arn:aws:rds:us-east-1:123456789012:db:critical-prod-db",
    "arn:aws:dynamodb:us-east-1:123456789012:table/critical-prod-table",
    "arn:aws:ec2:us-east-1:123456789012:volume/vol-*"
  ]

  # Note: Module hardcodes Environment=prod tag selection

  # Enable cross-region backup for DR
  cross_region_backup_enabled = true
  cross_region_destination    = var.cross_region_destination
  daily_backup_enabled        = true

  # Extended backup windows for DR
  start_window_minutes      = 240 # 4 hour start window
  completion_window_minutes = 720 # 12 hour completion window

  # DR-specific opt-in settings
  opt_in_settings = {
    "Aurora"   = true
    "DynamoDB" = true
    "EBS"      = true
    "EC2"      = true
    "EFS"      = true
    "RDS"      = true
  }

  # SNS notifications for DR backups
  sns_topic_arn = "arn:aws:sns:us-east-1:123456789012:backup-dr-notifications"

  # Tags for DR resources
  tags_vault = {
    Purpose     = "disaster-recovery"
    Environment = "production"
    Compliance  = "required"
  }

  tags_plan = {
    Purpose  = "disaster-recovery"
    Priority = "critical"
  }
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