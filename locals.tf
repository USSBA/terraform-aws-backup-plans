locals {
  enabled_count = var.enabled ? 1 : 0

  daily_backup_enabled = var.enabled && var.daily_backup_enabled
  daily_backup_count   = var.enabled && var.daily_backup_enabled ? 1 : 0

  # SNS notification count - only create if SNS topic is provided
  sns_notification_count = var.enabled && var.daily_backup_enabled && var.sns_topic_arn != "" ? 1 : 0

  # Determine if cross-region resources should be created
  create_cross_region_resources = var.enabled && var.daily_backup_enabled && var.cross_region_backup_enabled
}
