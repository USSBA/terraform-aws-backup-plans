variable "enabled" {
  type        = bool
  description = "enable/disable creation of all resources in this module"
  default     = true
}
variable "start_window_minutes" {
  type        = number
  description = "Amount if time (in minutes) before starting a backup job"
  default     = 60
}
variable "completion_window_minutes" {
  type        = number
  description = "Amount of time (in minutes) a backup job can run before it is automatically canceled"
  default     = 180
}
variable "vault_notification_sns_topic_arn" {
  type        = string
  description = "Topic ARN where vault notifications will be directed"
  default     = ""
}
#https://docs.aws.amazon.com/aws-backup/latest/devguide/sns-notifications.html
variable "vault_notification_events" {
  type        = list(string)
  description = "List of vault notification events. See https://docs.aws.amazon.com/aws-backup/latest/devguide/sns-notifications.html"
  default     = [
    "BACKUP_JOB_STARTED",
    "BACKUP_JOB_COMPLETED",
    "COPY_JOB_STARTED",
    "COPY_JOB_SUCCESSFUL",
    "COPY_JOB_FAILED",
    "RESTORE_JOB_STARTED",
    "RESTORE_JOB_COMPLETED",
    "RECOVERY_POINT_MODIFIED",
    "S3_BACKUP_OBJECT_FAILED",
    "S3_RESTORE_OBJECT_FAILED",
  ]
}

# cross region settings
variable "cross_region_backup_enabled" {
  type        = bool
  description = "enable/disable cross-region backups.  Defaults to 'false'"
  default     = false
}
variable "cross_region_destination" {
  type        = string
  description = "The region of the cross-region backup copy.  Default is 'us-west-2'"
  default     = "us-west-2"
}

# daily backup settings
variable "daily_backup_enabled" {
  type        = bool
  description = "enable/disable daily backups"
  default     = true
}
variable "daily_backup_tag_key" {
  type        = string
  description = "Tag Key for backing up resources daily"
  default     = "BackupDaily"
}
variable "daily_backup_tag_value" {
  type        = string
  description = "Tag Value for backing up resources daily"
  default     = "true"
}

# weekly backup settings
variable "weekly_backup_enabled" {
  type        = bool
  description = "enable/disable weekly backups"
  default     = true
}
variable "weekly_backup_tag_key" {
  type        = string
  description = "Tag Key for backing up resources weekly"
  default     = "BackupWeekly"
}
variable "weekly_backup_tag_value" {
  type        = string
  description = "Tag Value for backing up resources weekly"
  default     = "true"
}

# quarterly backup settings
variable "quarterly_backup_enabled" {
  type        = bool
  description = "enable/disable quarterly backups"
  default     = true
}
variable "quarterly_backup_tag_key" {
  type        = string
  description = "Tag Key for backing up resources quarterly"
  default     = "BackupQuarterly"
}
variable "quarterly_backup_tag_value" {
  type        = string
  description = "Tag Value for backing up resources quarterly"
  default     = "true"
}

# tagging
variable "tags" {
  type        = map(any)
  description = "Optional; Map of key-value tags to apply to all applicable resources"
  default     = {}
}
variable "tags_vault" {
  type        = map(any)
  description = "Optional; Map of key-value tags to apply to all backup vaults"
  default     = {}
}
variable "tags_plan" {
  type        = map(any)
  description = "Optional; Map of key-value tags to apply to all backup plans"
  default     = {}
}
