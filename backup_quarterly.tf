## Quarterly Plan
# - Run every quarter on SUN 12:00:00 AM UTC (SAT 07:00:00 PM EST)
# - Run every quarter on the LAST day of MARCH, JUNE, SEPTEMBER, DECEMBER @ 12:00 AM UTC

resource "aws_backup_vault" "quarterly" {
  count = local.quarterly_backup_count

  name = "quarterly"
  tags = merge(var.tags, var.tags_vault)
}

resource "aws_backup_vault" "quarterly_cross_region" {
  count = var.cross_region_backup_enabled ? local.quarterly_backup_count : 0

  name     = "quarterly_cross_region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross-region
}

resource "aws_backup_plan" "quarterly" {
  count = local.quarterly_backup_count

  name = "quarterly"
  tags = merge(var.tags, var.tags_plan)

  rule {
    rule_name         = "quarterly"
    target_vault_name = aws_backup_vault.quarterly[0].name
    schedule          = "cron(0 0 L 3,6,9,12 ? *)"
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      cold_storage_after = 365
    }

    dynamic "copy_action" {
      for_each = var.cross_region_backup_enabled ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.quarterly_cross_region[0].arn
        lifecycle {
          cold_storage_after = 365
        }
      }
    }
  }
}

resource "aws_backup_selection" "quarterly" {
  count = local.quarterly_backup_count

  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "quarterly"
  plan_id      = aws_backup_plan.quarterly[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.quarterly_backup_tag_key
    value = var.quarterly_backup_tag_value
  }
}
