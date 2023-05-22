## Weekly Backup Plan
# - Runs every week on SUNDAY @ 12:00 AM UTC
# - Backups are removed after 90 days

resource "aws_backup_vault" "weekly" {
  count = local.weekly_backup_count

  name = "weekly"
  tags = merge(var.tags, var.tags_vault)
}

resource "aws_backup_vault" "weekly_cross_region" {
  count = var.cross_region_backup_enabled ? local.weekly_backup_count : 0

  name     = "weekly_cross_region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross-region
}

resource "aws_backup_plan" "weekly" {
  count = local.weekly_backup_count

  name = "weekly"
  tags = merge(var.tags, var.tags_plan)

  rule {
    rule_name         = "weekly"
    target_vault_name = aws_backup_vault.weekly[0].name
    schedule          = "cron(0 0 ? * SUN *)"
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      delete_after = 90
    }

    dynamic "copy_action" {
      for_each = var.cross_region_backup_enabled ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.weekly_cross_region[0].arn
        lifecycle {
          delete_after = 90
        }
      }
    }
  }
}

resource "aws_backup_selection" "weekly" {
  count = local.weekly_backup_count

  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "weekly"
  plan_id      = aws_backup_plan.weekly[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.weekly_backup_tag_key
    value = var.weekly_backup_tag_value
  }
}
