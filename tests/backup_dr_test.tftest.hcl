# Test Disaster Recovery Configuration
run "dr_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_dr"
  }

  assert {
    condition     = module.backup.vault_name == "disaster-recovery-vault"
    error_message = "DR vault name should be 'disaster-recovery-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 4 * * ? *)"
    error_message = "DR vault schedule should be 'cron(0 4 * * ? *)'"
  }
}

# Test DR with different regions
run "dr_cross_region_configuration" {
  command = plan

  variables {
    region                   = "us-west-1"
    cross_region_destination = "us-east-2"
  }

  module {
    source = "./fixtures/vault_dr"
  }

  assert {
    condition     = module.backup.vault_name == "disaster-recovery-vault"
    error_message = "DR vault should maintain consistent naming across regions"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 4 * * ? *)"
    error_message = "DR vault schedule should be consistent across regions"
  }
}