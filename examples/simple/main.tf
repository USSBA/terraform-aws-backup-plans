# Simple AWS Backup Example
# This example demonstrates the minimal configuration needed to get started with AWS Backup

# Configure the AWS provider
provider "aws" {
  region = "us-east-1"
}

# Configure cross-region provider (required by module)
provider "aws" {
  alias  = "cross_region"
  region = "us-west-2"
}

# Opinionated backup - backs up ALL resources tagged Environment=prod
module "production_backup" {
  source = "../.."

  # Minimal configuration - that's it!
  vault_name = "production-backup-vault"

  # Provider configuration (required)
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  # Optional: customize tags
  tags_vault = {
    Environment = "production"
    ManagedBy   = "terraform"
  }
}

# Override example - target specific resources
module "database_backup" {
  source = "../.."

  vault_name      = "database-backup-vault"
  backup_schedule = "cron(0 2 * * ? *)" # 2 AM UTC

  # Override auto-discovery with specific resources
  resource_arns = [
    "arn:aws:rds:us-east-1:123456789012:db:critical-db-*",
    "arn:aws:dynamodb:us-east-1:123456789012:table/critical-*"
  ]

  # Provider configuration (required)
  providers = {
    aws              = aws
    aws.cross_region = aws.cross_region
  }

  tags_vault = {
    Environment = "production"
    DataClass   = "critical"
  }
}

# Example output to show backup vault ARN
output "backup_vault_arn" {
  description = "ARN of the created backup vault"
  value       = module.production_backup.vault_name
}

output "backup_schedule" {
  description = "Backup schedule that was configured"
  value       = module.production_backup.backup_schedule
}