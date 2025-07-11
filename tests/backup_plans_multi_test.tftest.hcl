# Test Vault C (Cross-region backup)
run "vault_cross_region_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_cross_region"
  }

  assert {
    condition     = module.backup.vault_name == "cross-region-vault"
    error_message = "Cross-region vault name should be 'cross-region-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 7 * * ? *)"
    error_message = "Cross-region vault schedule should be 'cron(0 7 * * ? *)'"
  }

  assert {
    condition     = module.backup.cross_region_backup_enabled
    error_message = "Cross-region backup should be enabled"
  }
  
  assert {
    condition     = module.backup.cross_region_destination == "us-east-1"
    error_message = "Cross-region destination should be 'us-east-1'"
  }
  
  assert {
    condition     = length(module.backup.iam_role_arn) > 0
    error_message = "Cross-region vault should have an IAM role created"
  }
}
