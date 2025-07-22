# Test Vault A (Resource-based backup, non-cross-region)
run "vault_a_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_a"
  }

  assert {
    condition     = module.backup.vault_name == "rds-vault"
    error_message = "Vault A name should be 'rds-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 5 * * ? *)"
    error_message = "Vault A schedule should be 'cron(0 5 * * ? *)'"
  }


}

# Test Vault B (Tag-based backup, non-cross-region)
run "vault_b_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_b"
  }

  assert {
    condition     = module.backup.vault_name == "s3-vault"
    error_message = "Vault B name should be 's3-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 6 * * ? *)"
    error_message = "Vault B schedule should be 'cron(0 6 * * ? *)'"
  }
}