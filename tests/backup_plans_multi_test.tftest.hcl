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
}
