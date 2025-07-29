# Test Tag-based Resource Selection
run "tag_based_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_tags"
  }

  assert {
    condition     = module.backup.vault_name == "tag-based-vault"
    error_message = "Tag-based vault name should be 'tag-based-vault'"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 3 * * ? *)"
    error_message = "Tag-based vault schedule should be 'cron(0 3 * * ? *)'"
  }
}

# Test with different tag configurations
run "tag_configuration_variations" {
  command = plan

  variables {
    region = "us-east-1"
  }

  module {
    source = "./fixtures/vault_tags"
  }

  assert {
    condition     = module.backup.vault_name != ""
    error_message = "Vault name should not be empty"
  }

  assert {
    condition     = module.backup.vault_name == "tag-based-vault"
    error_message = "Tag-based vault should be created successfully"
  }
}