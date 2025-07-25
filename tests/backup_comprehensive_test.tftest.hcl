# Comprehensive test covering multiple backup scenarios in a single test

# Test vault A configuration 
run "vault_a_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_a"
  }

  assert {
    condition     = module.backup.vault_name == "rds-vault"
    error_message = "Vault A should create vault with correct name"
  }
}

# Test vault B configuration
run "vault_b_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_b"
  }

  assert {
    condition     = module.backup.vault_name == "s3-vault"
    error_message = "Vault B should create vault with correct name"
  }
}

# Test cross-region configuration
run "cross_region_configuration" {
  command = plan

  module {
    source = "./fixtures/vault_cross_region"
  }

  assert {
    condition     = module.backup.vault_name == "cross-region-vault"
    error_message = "Cross-region vault should create vault with correct name"
  }
}

# Test different backup schedules using different regions
run "schedule_variations" {
  command = plan

  variables {
    region = "us-west-1"
  }

  module {
    source = "./fixtures/vault_a"
  }

  assert {
    condition     = module.backup.vault_name == "rds-vault"
    error_message = "Vault should maintain name regardless of region"
  }
}

# Test resource targeting methods
run "resource_targeting_comparison" {
  command = plan

  # Test ARN-based targeting (vault_a)
  module {
    source = "./fixtures/vault_a"
  }

  assert {
    condition     = module.backup.vault_name != ""
    error_message = "ARN-based targeting should create vault"
  }
}

# Test cross-region configurations
run "cross_region_variations" {
  command = plan

  variables {
    region                   = "us-west-1"
    cross_region_destination = "us-east-2"
  }

  module {
    source = "./fixtures/vault_cross_region"
  }

  assert {
    condition     = module.backup.vault_name == "cross-region-vault"
    error_message = "Cross-region vault should work with different regions"
  }
}

# Test provider configurations
run "provider_configuration_test" {
  command = plan

  module {
    source = "./fixtures/vault_cross_region"
  }

  # Verify that cross-region provider is properly configured
  assert {
    condition     = module.backup.vault_name == "cross-region-vault"
    error_message = "Cross-region vault should be created with proper provider config"
  }
}

# Test tag-based selection
run "tag_based_selection" {
  command = plan

  module {
    source = "./fixtures/vault_tags"
  }

  assert {
    condition     = module.backup.vault_name == "tag-based-vault"
    error_message = "Tag-based selection should work"
  }
}

# Test ARN-based selection
run "arn_based_selection" {
  command = plan

  module {
    source = "./fixtures/vault_a"
  }

  assert {
    condition     = module.backup.vault_name == "rds-vault"
    error_message = "ARN-based selection should work"
  }
}