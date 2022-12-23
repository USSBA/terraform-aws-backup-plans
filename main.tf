# Local Vars
locals {
  enabled_count = var.enabled ? 1 : 0
  enabled_notification_count = var.enabled && length(var.vault_notification_sns_topic_arn) > 0 ? 1 : 0

  daily_backup_enabled = var.enabled && var.daily_backup_enabled
  daily_backup_count   = var.enabled && var.daily_backup_enabled ? 1 : 0

  weekly_backup_enabled = var.enabled && var.weekly_backup_enabled
  weekly_backup_count   = var.enabled && var.weekly_backup_enabled ? 1 : 0

  quarterly_backup_enabled = var.enabled && var.quarterly_backup_enabled
  quarterly_backup_count   = var.enabled && var.quarterly_backup_enabled ? 1 : 0
}

# Assume Role Poliy for AWS Backup Service
data "aws_iam_policy_document" "service_link" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "service_role" {
  count              = local.enabled_count
  name               = "backup-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_link.json
}
resource "aws_iam_role_policy_attachment" "service_role_attachment" {
  count      = local.enabled_count
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = var.enabled ? aws_iam_role.service_role[0].name : ""
}
resource "aws_iam_role_policy_attachment" "s3_service_role_attachment" {
  count      = local.enabled_count
  policy_arn = "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup"
  role       = var.enabled ? aws_iam_role.service_role[0].name : ""
}

## Daily Backup Plan
# - Runs every day @ 08:00 AM UTC
# - Backups are removed after 30 days
resource "aws_backup_vault" "daily" {
  count = local.daily_backup_count
  name  = "daily"
  tags  = merge(var.tags, var.tags_vault)
}
resource "aws_backup_vault" "daily_cross_region" {
  count    = var.cross_region_backup_enabled ? local.daily_backup_count : 0
  name     = "daily_cross_region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross-region
}
resource "aws_backup_plan" "daily" {
  count = local.daily_backup_count
  name  = "daily"
  tags  = merge(var.tags, var.tags_plan)

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.daily[0].name
    schedule          = "cron(0 8 ? * * *)"
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      delete_after = 30
    }
    dynamic "copy_action" {
      for_each = var.cross_region_backup_enabled ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region[0].arn
        lifecycle {
          delete_after = 30
        }
      }
    }
  }
}
resource "aws_backup_selection" "daily" {
  count        = local.daily_backup_count
  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "daily"
  plan_id      = aws_backup_plan.daily[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.daily_backup_tag_key
    value = var.daily_backup_tag_value
  }
}

## Weekly Backup Plan
# - Runs every week on SUNDAY @ 12:00 AM UTC
# - Backups are removed after 90 days
resource "aws_backup_vault" "weekly" {
  count = local.weekly_backup_count
  name  = "weekly"
  tags  = merge(var.tags, var.tags_vault)
}
resource "aws_backup_vault" "weekly_cross_region" {
  count    = var.cross_region_backup_enabled ? local.weekly_backup_count : 0
  name     = "weekly_cross_region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross-region
}
resource "aws_backup_plan" "weekly" {
  count = local.weekly_backup_count
  name  = "weekly"
  tags  = merge(var.tags, var.tags_plan)

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
  count        = local.weekly_backup_count
  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "weekly"
  plan_id      = aws_backup_plan.weekly[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.weekly_backup_tag_key
    value = var.weekly_backup_tag_value
  }
}

## Quarterly Plan
# - Run every quarter on SUN 12:00:00 AM UTC (SAT 07:00:00 PM EST)
# - Run every quarter on the LAST day of MARCH, JUNE, SEPTEMBER, DECEMBER @ 12:00 AM UTC
resource "aws_backup_vault" "quarterly" {
  count = local.quarterly_backup_count
  name  = "quarterly"
  tags  = merge(var.tags, var.tags_vault)
}
resource "aws_backup_vault" "quarterly_cross_region" {
  count    = var.cross_region_backup_enabled ? local.quarterly_backup_count : 0
  name     = "quarterly_cross_region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross-region
}
resource "aws_backup_plan" "quarterly" {
  count = local.quarterly_backup_count
  name  = "quarterly"
  tags  = merge(var.tags, var.tags_plan)

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
  count        = local.quarterly_backup_count
  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "quarterly"
  plan_id      = aws_backup_plan.quarterly[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.quarterly_backup_tag_key
    value = var.quarterly_backup_tag_value
  }
}

# Opt-In Settings
resource "aws_backup_region_settings" "opt_in" {
  resource_type_opt_in_preference = {
    "CloudFormation"         = true
    "DocumentDB"             = true
    "DynamoDB"               = true
    "Aurora"                 = true
    "EBS"                    = true
    "EC2"                    = true
    "EFS"                    = true
    "FSx"                    = true
    "Neptune"                = true
    "RDS"                    = true
    "Redshift"               = true
    "SAP HANA on Amazon EC2" = true
    "Storage Gateway"        = true
    "S3"                     = true
    "Timestream"             = true
    "VirtualMachine"         = true
  }
}

# Vault Notifications
data "aws_iam_policy_document" "vault_notification" {
  count = local.enabled_notification_count
  statement {
    actions = ["sns:Publish", "sns:Subscribe"]
    #principals {
    #  type        = "Service"
    #  identifiers = ["backup.amazonaws.com"]
    #}
    resources = [
      var.vault_notification_sns_topic_arn,
    ]
  }
}
resource "aws_iam_policy" "vault_notification" {
  count       = local.enabled_notification_count
  name        = "backup-vault-notifications"
  path        = "/"
  description = "Vault Notifications"
  policy      = data.aws_iam_policy_document.vault_notification[0].json
}
resource "aws_iam_role_policy_attachment" "vault_notification" {
  count      = local.enabled_notification_count
  policy_arn = aws_iam_policy.vault_notification[0].arn
  role       = aws_iam_role.service_role[0].name
}
resource "aws_backup_vault_notifications" "daily" {
  count               = local.enabled_notification_count
  backup_vault_name   = aws_backup_vault.daily[0].name
  sns_topic_arn       = var.vault_notification_sns_topic_arn
  backup_vault_events = var.vault_notification_events
}
resource "aws_backup_vault_notifications" "weekly" {
  count               = local.enabled_notification_count
  backup_vault_name   = aws_backup_vault.weekly[0].name
  sns_topic_arn       = var.vault_notification_sns_topic_arn
  backup_vault_events = var.vault_notification_events
}
resource "aws_backup_vault_notifications" "quarterly" {
  count               = local.enabled_notification_count
  backup_vault_name   = aws_backup_vault.weekly[0].name
  sns_topic_arn       = var.vault_notification_sns_topic_arn
  backup_vault_events = var.vault_notification_events
}

