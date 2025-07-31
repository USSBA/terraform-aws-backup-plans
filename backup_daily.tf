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
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.daily.name
    schedule          = var.backup_schedule
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      # Days until transition to Glacier
      cold_storage_after = 30
      # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
      delete_after = 120 # 30 + 90 = 120
    }

    dynamic "copy_action" {
      for_each = var.cross_region_backup_enabled ? [1] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region["cross_region"].arn

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
  resources    = var.resource_arns

  condition {
    selection_tag {
      type  = "STRINGEQUALS"
      key   = "Environment"
      value = var.environment_tag_value # default: 'prod'
    }

    selection_tag {
      type  = "STRINGEQUALS"
      key   = "Backup"
      value = "true"
    }
  }
}
