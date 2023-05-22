locals {
  enabled_count = var.enabled ? 1 : 0

  daily_backup_enabled = var.enabled && var.daily_backup_enabled
  daily_backup_count   = var.enabled && var.daily_backup_enabled ? 1 : 0

  weekly_backup_enabled = var.enabled && var.weekly_backup_enabled
  weekly_backup_count   = var.enabled && var.weekly_backup_enabled ? 1 : 0

  quarterly_backup_enabled = var.enabled && var.quarterly_backup_enabled
  quarterly_backup_count   = var.enabled && var.quarterly_backup_enabled ? 1 : 0
}

