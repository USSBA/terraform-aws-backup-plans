variable "enabled" {
  type        = bool
  description = "enable/disable creation of all resources in this module"
  default     = true
}
variable "weekly_backup_enabled" {
  type        = bool
  description = "enable/disable weekly backups"
  default     = true
}
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
