# Daily Backup Plan
# - Runs on configurable schedule (default: daily @ 05:00 AM UTC)
# - Backups can be transitioned to cold storage (configurable, default: 30 days)
# - Backups can be automatically deleted (configurable, default: 120 days total)
# - Cross-region copies inherit the same lifecycle settings

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
    target_vault_name = try(one(aws_backup_vault.daily[*].name), "")
    schedule          = var.backup_schedule
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    dynamic "lifecycle" {
      for_each = var.cold_storage_after_days != null || var.delete_after_days != null ? [1] : []
      content {
        cold_storage_after = var.cold_storage_after_days
        delete_after       = var.delete_after_days
      }
    }

    dynamic "copy_action" {
      for_each = local.create_cross_region_resources ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region["cross_region"].arn

        dynamic "lifecycle" {
          for_each = var.cold_storage_after_days != null || var.delete_after_days != null ? [1] : []
          content {
            cold_storage_after = var.cold_storage_after_days
            delete_after       = var.delete_after_days
          }
        }
      }
    }
  }
}

resource "aws_backup_selection" "daily" {
  count = local.daily_backup_count

  iam_role_arn = try(one(aws_iam_role.service_role[*].arn), "")
  name         = var.vault_name
  plan_id      = try(one(aws_backup_plan.daily[*].id), "")

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
