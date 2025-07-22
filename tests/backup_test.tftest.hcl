# Test file for AWS Backup module - Vault B Configuration

# Test Vault B (ARN-based backup, non-cross-region)
run "vault_b_configuration" {
  command = plan

  # Use the fixture module
  module {
    source = "./fixtures/vault_b"
  }

  # Basic assertions with detailed error messages
  # Only checking values that are known during plan phase
  assert {
    condition     = module.backup.vault_name == "s3-vault"
    error_message = "Vault B name should be 's3-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 6 * * ? *)"
    error_message = "Vault B schedule should be 'cron(0 6 * * ? *)'"
  }
}
