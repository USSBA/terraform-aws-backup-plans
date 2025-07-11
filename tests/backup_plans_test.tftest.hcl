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

  assert {
    condition     = length(module.backup.backup_resource_types) == 1 && module.backup.backup_resource_types[0] == "rds:db"
    error_message = "Vault A should have exactly one resource type 'rds:db'"
  }
  
  assert {
    condition     = !module.backup.cross_region_backup_enabled
    error_message = "Vault A should have cross-region backups disabled"
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

  assert {
    condition     = length(module.backup.iam_role_arn) > 0
    error_message = "Vault B should have an IAM role created"
  }
  
  assert {
    condition     = !module.backup.cross_region_backup_enabled
    error_message = "Vault B should have cross-region backups disabled"
  }
}

# Note: Cross-region backup tests have been moved to backup_plans_multi_test.tftest.hcl
