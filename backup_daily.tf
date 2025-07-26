# Daily Backup Plan
# - Runs every day @ 08:00 AM UTC
# - Backups are transitioned to cold storage after 30 days
# - Backups are then removed after 120 total days (30 in warm storage, 90 in cold storage)

resource "aws_backup_vault" "daily" {
  count = local.daily_backup_count

  name = var.vault_name
  tags = var.tags_vault
}

resource "aws_backup_vault" "daily_cross_region" {
  for_each = local.create_cross_region_resources ? { "cross_region" = true } : {}

  name     = "${var.vault_name}-cross-region"
  tags     = var.tags_vault
  provider = aws.cross_region
}

resource "aws_backup_plan" "daily" {
  count = local.daily_backup_count

  name = var.vault_name
  tags = var.tags_plan

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.daily[0].name
    schedule          = var.backup_schedule
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      cold_storage_after = 30  # Days until transition to Glacier
      delete_after       = 120 # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
    }

    dynamic "copy_action" {
      for_each = local.create_cross_region_resources ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region["cross_region"].arn

        lifecycle {
          cold_storage_after = 30  # Days until transition to Glacier
          delete_after       = 120 # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
        }
      }
    }
  }
}

resource "aws_backup_selection" "daily" {
  count = local.daily_backup_count

  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = var.vault_name
  plan_id      = aws_backup_plan.daily[0].id

  # Include specific resources if ARNs provided, otherwise auto-discover via tags
  resources = length(var.resource_arns) > 0 ? var.resource_arns : null

  # Always select by Environment=prod tag
  dynamic "selection_tag" {
    for_each = [1]
    content {
      type  = "STRINGEQUALS"
      key   = "Environment"
      value = "prod"
    }
  }

  # Add exclusion conditions if any are specified
  dynamic "condition" {
    for_each = var.exclude_conditions

    content {
      string_equals {
        key   = condition.value.key
        value = condition.value.value
      }
    }
  }

  # Auto-discovery: When no resource ARNs are specified, 
  # backup selection relies on the Environment=prod tag filter to discover resources
}
