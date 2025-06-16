# Daily Backup Plan
# - Runs every day @ 08:00 AM UTC
# - Backups are transitioned to cold storage after 30 days
# - Backups are then removed after 120 total days (30 in warm storage, 90 in cold storage)

resource "aws_backup_vault" "daily" {
  count = local.daily_backup_count

  name = "daily"
  tags = merge(var.tags, var.tags_vault)
}

resource "aws_backup_vault" "daily_cross_region" {
  count = var.cross_region_backup_enabled ? local.daily_backup_count : 0

  name     = "daily_cross_region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross-region
}

resource "aws_backup_plan" "daily" {
  count = local.daily_backup_count

  name = "daily"
  tags = merge(var.tags, var.tags_plan)

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.daily[0].name
    schedule          = "cron(0 8 ? * * *)"
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      cold_storage_after = 30  # Days until transition to Glacier
      delete_after       = 120 # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
    }

    dynamic "copy_action" {
      for_each = var.cross_region_backup_enabled ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region[0].arn

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
  name         = "daily"
  plan_id      = aws_backup_plan.daily[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.daily_backup_tag_key
    value = var.daily_backup_tag_value
  }
}
