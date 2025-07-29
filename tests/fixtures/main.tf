# Test configuration for the backup module

# Provider configuration
provider "aws" {
  region = "us-east-1" # You can change this to your preferred region
}

# Include the module being tested
module "backup" {
  source = "../../"
}

# Outputs for testing
output "backup_vault_arn" {
  value = module.backup.backup_vault_arn
}

output "iam_role_arn" {
  value = module.backup.iam_role_arn
}

output "backup_plan_id" {
  value = module.backup.backup_plan_id
}
