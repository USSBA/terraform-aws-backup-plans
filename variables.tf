variable "enabled" {
  type        = bool
  description = "enable/disable creation of all resources in this module"
  default     = true
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
