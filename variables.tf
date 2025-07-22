# Region Configuration
variable "region" {
  type        = string
  description = "The AWS region in which all backup resources will be created. Applies to all resources unless overridden elsewhere. Default: us-east-1."
  default     = "us-east-1"
}

# Backup Configuration
variable "enabled" {
  type        = bool
  description = "Whether to enable creation of all resources in this module. Set to false to disable all resource creation. Default: true."
  default     = true
}

variable "service_role_name" {
  type        = string
  description = "Name of the IAM role to be created for AWS Backup. If not specified, a name will be generated in the format 'backup-service-role-{vault_name}'. Default: empty string (auto-generated)."
  default     = ""
}

variable "start_window_minutes" {
  type        = number
  description = "The amount of time (in minutes) before a backup job is allowed to start after being scheduled. Default: 60."
  default     = 60
}

variable "completion_window_minutes" {
  type        = number
  description = "The maximum amount of time (in minutes) a backup job can run before it is automatically canceled. Default: 180."
  default     = 180
}

variable "opt_in_settings" {
  type        = map(any)
  description = "Region-specific opt-in settings for AWS Backup advanced features. Use the AWS CLI 'aws backup describe-region-settings' to see available options. Default: empty map."
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

# Resource Selection
variable "backup_resource_types" {
  type        = list(string)
  description = "List of resource types to back up (e.g., 'AWS::EC2::Volume', 'AWS::RDS::DBInstance'). Used when use_tags is false and resource_arns is empty."
  default     = []
}

variable "use_tags" {
  type        = bool
  description = "Whether to use tag-based selection for backup resources. If false, uses explicit resource types or ARNs instead."
  default     = true
}

variable "backup_resource_tags" {
  type        = map(any)
  description = "Key-value map of tags for selecting resources to back up. Used when use_tags is true."
  default     = {}
}

variable "resource_arns" {
  type        = list(string)
  description = "List of resource ARNs or ARN patterns to include in the backup selection. Can be used with or without tag-based selection."
  default     = []
}

variable "exclude_conditions" {
  type = list(object({
    key   = string # e.g., "aws:ResourceTag/Environment" or "aws:ResourceTag/Backup"
    value = string # The value to match against the key for exclusion
  }))
  description = "List of key-value pairs to exclude resources from backup. Uses string_equals condition to match resources that should be excluded."
  default     = []
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
