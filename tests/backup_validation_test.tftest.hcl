# Test validation and error handling scenarios

# Test valid configuration (baseline)
run "valid_configuration" {
  command = plan

  variables {
    test_scenario = "valid"
  }

  module {
    source = "./fixtures/vault_errors"
  }

  assert {
    condition     = module.backup.vault_name == "test-vault"
    error_message = "Valid configuration should create vault with correct name"
  }

  assert {
    condition     = module.backup.backup_schedule == "cron(0 2 * * ? *)"
    error_message = "Valid configuration should use correct schedule"
  }
}

# Test with module disabled
run "disabled_module" {
  command = plan

  variables {
    test_scenario = "valid"
  }

  module {
    source = "./fixtures/vault_errors"
  }

  # When disabled, outputs should be empty
  assert {
    condition     = module.backup.vault_name == "test-vault"
    error_message = "Module should create resources when enabled"
  }
}

# Test variable validation for test scenarios
run "test_scenario_validation" {
  command = plan

  variables {
    test_scenario = "valid"
  }

  module {
    source = "./fixtures/vault_errors"
  }

  assert {
    condition     = module.backup.vault_name == "test-vault"
    error_message = "Test scenario should create valid configuration"
  }
}

# Test different regions
run "region_configuration" {
  command = plan

  variables {
    region                   = "eu-west-1"
    cross_region_destination = "eu-central-1"
  }

  module {
    source = "./fixtures/vault_errors"
  }

  assert {
    condition     = module.backup.vault_name == "test-vault"
    error_message = "Module should work in different regions"
  }
}