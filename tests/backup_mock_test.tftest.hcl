# Mock test configuration for the backup module

# Test with mock Backup service
run "mock_backup_test" {
  command = plan

  # Verify the backup vault name is set
  assert {
    condition     = module.backup.vault_name == "test-vault"
    error_message = "Backup vault name should be 'test-vault'"
  }

  # Verify the backup schedule is set correctly
  assert {
    condition     = module.backup.backup_schedule == "cron(0 5 * * ? *)"
    error_message = "Backup schedule should be set to 'cron(0 5 * * ? *)'"
  }

  # Verify the IAM role ARN is set
  assert {
    condition     = module.backup.iam_role_arn != ""
    error_message = "IAM role ARN should be set"
  }
}
