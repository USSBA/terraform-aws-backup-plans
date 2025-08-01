# Daily Backup Plan
# - Runs on configurable schedule (default: daily @ 05:00 AM UTC)
# - Backups can be transitioned to cold storage (default: 30 days)
# - Backups can be automatically deleted (default: 120 days total)
# - Cross-region copies inherit the same lifecycle settings and opt_in settings

resource "aws_backup_vault" "daily" {
  name = var.vault_name
}

resource "aws_backup_vault" "daily_cross_region" {
  count = var.cross_region_backup_enabled ? 1 : 0

  name     = "${var.vault_name}-cross-region"
  provider = aws.cross_region
}

resource "aws_backup_plan" "daily" {
  name = var.vault_name

  rule {
    rule_name                    = "daily"
    target_vault_name            = aws_backup_vault.daily.name
    schedule                     = var.backup_schedule
    schedule_expression_timezone = var.backup_schedule_timzone
    start_window                 = var.start_window_minutes
    completion_window            = var.completion_window_minutes

    lifecycle {
      # Days until transition to Glacier
      cold_storage_after = 30
      # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
      delete_after = 120 # 30 + 90 = 120
    }

    dynamic "copy_action" {
      for_each = var.cross_region_backup_enabled ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region[0].arn

        lifecycle {
          # Days until transition to Glacier
          cold_storage_after = 30
          # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
          delete_after = 120 # 30 + 90 = 120
        }
      }
    }
  }
}

resource "aws_backup_selection" "daily" {
  name         = var.vault_name
  plan_id      = aws_backup_plan.daily.id
  iam_role_arn = aws_iam_role.service_role.arn
  resources    = var.backup_selection_resource_arns

  condition {
    dynamic "string_equals" {
      for_each = var.backup_selection_conditions.string_equals
      content {
        key   = string_equals.key
        value = string_equals.value
      }
    }
    dynamic "string_like" {
      for_each = var.backup_selection_conditions.string_like
      content {
        key   = string_like.key
        value = string_like.value
      }
    }
    dynamic "string_not_equals" {
      for_each = var.backup_selection_conditions.string_not_equals
      content {
        key   = string_not_equals.key
        value = string_not_equals.value
      }
    }
    dynamic "string_not_like" {
      for_each = var.backup_selection_conditions.string_not_like
      content {
        key   = string_not_like.key
        value = string_not_like.value
      }
    }
  }
}
