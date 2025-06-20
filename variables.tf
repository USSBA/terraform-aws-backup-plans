# Backup Configuration
variable "enabled" {
  type        = bool
  description = "Optional; Enable/disable creation of all resources in this module. Defaults to true."
  default     = true
}

variable "start_window_minutes" {
  type        = number
  description = "Optional; Amount of time (in minutes) before starting a backup job. Defaults to 60."
  default     = 60
}

variable "completion_window_minutes" {
  type        = number
  description = "Optional; Amount of time (in minutes) a backup job can run before it is automatically canceled. Defaults to 180."
  default     = 180
}

variable "opt_in_settings" {
  type        = map(any)
  description = "Optional; Region-specific opt-in choices for AWS Backup. Use 'aws backup describe-region-settings' CLI command to see available options. Defaults to empty map."
  default     = {}
}

# Cross Region Settings
variable "cross_region_backup_enabled" {
  type        = bool
  description = "Optional; Enable/disable cross-region backups. Defaults to false."
  default     = false
}

variable "cross_region_destination" {
  type        = string
  description = "Optional; The region of the cross-region backup copy. Defaults to 'us-west-2'."
  default     = "us-west-2"
}

# Daily Backup Settings
variable "daily_backup_enabled" {
  type        = bool
  description = "Optional; Enable/disable daily backups. Defaults to true."
  default     = true
}

variable "daily_backup_tag_key" {
  type        = string
  description = "Optional; Tag key for backing up resources daily. Defaults to 'BackupDaily'."
  default     = "BackupDaily"
}

variable "daily_backup_tag_value" {
  type        = string
  description = "Optional; Tag value for backing up resources daily. Defaults to 'true'."
  default     = "true"
}

# Vault Notifications
variable "sns_topic_arn" {
  type        = string
  description = "Optional; Topic ARN where backup vault notifications are directed."
  default     = ""
}

# Tags
variable "tags" {
  type        = map(any)
  description = "Optional; Key-value map of tags for all applicable resources."
  default     = {}
}

variable "tags_vault" {
  type        = map(any)
  description = "Optional; Key-value map of tags for backup vaults."
  default     = {}
}

variable "tags_plan" {
  type        = map(any)
  description = "Optional; Key-value map of tags for backup plans."
  default     = {}
}
