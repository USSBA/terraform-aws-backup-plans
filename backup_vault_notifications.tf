# Vault Notification Events
# https://docs.aws.amazon.com/cli/latest/reference/backup/put-backup-vault-notifications.html

# daily
resource "aws_backup_vault_notifications" "daily" {
  count             = length(var.sns_topic_arn) > 0 ? local.daily_backup_count : 0
  backup_vault_name = aws_backup_vault.daily[0].name
  sns_topic_arn     = var.sns_topic_arn
  backup_vault_events = [
    "BACKUP_JOB_EXPIRED",
    "RECOVERY_POINT_MODIFIED",
    "BACKUP_PLAN_MODIFIED",
    "BACKUP_JOB_FAILED",
    "RESTORE_JOB_FAILED",
    "COPY_JOB_FAILED",
    "S3_BACKUP_OBJECT_FAILED",
    "S3_RESTORE_OBJECT_FAILED",
  ]
}
