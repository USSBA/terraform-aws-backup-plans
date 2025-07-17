# Region Configuration
variable "region" {
  type        = string
  description = "The AWS region where resources will be created. Defaults to us-east-1."
  default     = "us-east-1"
}

# Backup Configuration
variable "enabled" {
  type        = bool
  description = "Optional; Enable/disable creation of all resources in this module. Defaults to true."
  default     = true
}

variable "service_role_name" {
  type        = string
  description = "Optional; Name of the IAM role to be created for AWS Backup. If not specified, a name will be generated using the format 'backup-service-role-{vault_name}'"
  default     = ""
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

# Vault Settings
variable "vault_name" {
  type        = string
  description = "Optional; Name of the backup vault to create. Defaults to 'DefaultBackupVault'."
  default     = "DefaultBackupVault"
}

variable "backup_schedule" {
  type        = string
  description = "Optional; Cron expression defining the backup schedule. Defaults to 'cron(0 5 * * ? *)' (daily at 5 AM UTC)."
  default     = "cron(0 5 * * ? *)"
}

# Vault Notifications
variable "sns_topic_arn" {
  type        = string
  description = "Optional; Topic ARN where backup vault notifications are directed."
  default     = ""
}

# Backup Resource Types
variable "backup_resource_types" {
  type        = list(string)
  description = "List of resource types to back up (e.g., 'AWS::EC2::Volume', 'AWS::RDS::DBInstance'). Used when use_tags is false."
  default     = []
}

variable "use_tags" {
  type        = bool
  description = "Whether to use tag-based selection for backup resources. If false, uses explicit resource types instead."
  default     = true
}

variable "backup_resource_tags" {
  type        = map(any)
  description = "Optional; Key-value map of tags for selecting resources to back up. Used when use_tags is true."
  default     = {}
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

variable "additional_managed_policies" {
  type        = list(string)
  description = "Optional; List of up to 18 additional IAM policy ARNs to attach to the backup service role. These will be combined with the required AWS Backup policies for a total of up to 20 policies."
  default     = []

  validation {
    condition     = length(var.additional_managed_policies) <= 18
    error_message = "A maximum of 18 additional managed policies can be specified (20 total including required AWS Backup policies)."
  }
}
