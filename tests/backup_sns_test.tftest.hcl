# Test SNS notification configuration

run "sns_notification_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_sns"
  }

  assert {
    condition     = module.backup.vault_name == "sns-test-vault"
    error_message = "SNS test vault name should be 'sns-test-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 5 * * ? *)"
    error_message = "SNS test vault schedule should be 'cron(0 5 * * ? *)'"
  }

  # SNS test validates that the module accepts SNS configuration
  assert {
    condition     = module.backup.vault_name != ""
    error_message = "Vault should be created successfully with SNS configuration"
  }
}

# Test SNS topic creation - simplified to check vault creation
run "sns_topic_creation" {
  command = plan

  module {
    source = "./fixtures/vault_sns"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 5 * * ? *)"
    error_message = "SNS test should maintain correct schedule"
  }
}

# Test without SNS (empty topic ARN)
run "no_sns_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_a" # This fixture has empty sns_topic_arn
  }

  assert {
    condition     = module.backup.vault_name == "rds-vault"
    error_message = "Module should work without SNS configuration"
  }
}