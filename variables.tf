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

# Cross-Region Backup Settings
variable "cross_region_backup_enabled" {
  type        = bool
  description = "Whether to enable cross-region backup copies. If true, backups will be copied to another AWS region specified by 'cross_region_destination'. Default: false."
  default     = false
}

variable "cross_region_destination" {
  type        = string
  description = "The AWS region to which cross-region backup copies will be sent if enabled. Default: 'us-west-2'."
  default     = "us-west-2"
}

# Daily Backup Settings
variable "daily_backup_enabled" {
  type        = bool
  description = "Whether to enable daily backups. If false, daily backup jobs will not be scheduled. Default: true."
  default     = true
}

variable "daily_backup_tag_key" {
  type        = string
  description = "The resource tag key used to select resources for daily backup (e.g., 'BackupDaily'). Default: 'BackupDaily'."
  default     = "BackupDaily"
}

variable "daily_backup_tag_value" {
  type        = string
  description = "The resource tag value used to select resources for daily backup (e.g., 'true'). Default: 'true'."
  default     = "true"
}

# Vault Settings
variable "vault_name" {
  type        = string
  description = "Name of the backup vault to create. Must be unique within your AWS account and region. Default: 'DefaultBackupVault'."
  default     = "DefaultBackupVault"
}

variable "backup_schedule" {
  type        = string
  description = "Cron expression (in AWS format) that defines when the backup job runs. Example: 'cron(0 5 * * ? *)' runs daily at 5 AM UTC. Default: 'cron(0 5 * * ? *)'."
  default     = "cron(0 5 * * ? *)"
}

# Vault Notifications
variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic to receive backup vault notifications (e.g., backup job completion, failures). Leave blank to disable notifications. Default: empty string."
  default     = ""
}

# Resource Selection
variable "backup_resource_types" {
  type        = list(string)
  description = "List of AWS resource types to include in the backup plan (e.g., 'AWS::EC2::Volume', 'AWS::RDS::DBInstance'). Used only when 'use_tags' is false and 'resource_arns' is empty. Default: empty list."
  default     = []
}

variable "use_tags" {
  type        = bool
  description = "Whether to select resources for backup based on tags. If true, resources with matching 'backup_resource_tags' will be included. If false, 'backup_resource_types' and/or 'resource_arns' are used. Default: true."
  default     = true
}

variable "backup_resource_tags" {
  type        = map(any)
  description = "Key-value pairs of tags used to select resources for backup when 'use_tags' is true. Example: { Environment = 'prod' }. Default: empty map."
  default     = {}
}

variable "resource_arns" {
  type        = list(string)
  description = "List of resource ARNs or ARN patterns to include in the backup selection. Can be used with or without tag-based selection. Example: ['arn:aws:ec2:region:account-id:volume/*']. Default: empty list."
  default     = []
}

variable "exclude_conditions" {
  type = list(object({
    key   = string # e.g., "aws:ResourceTag/Environment" or "aws:ResourceTag/Backup"
    value = string # The value to match against the key for exclusion
  }))
  description = "List of key-value conditions to exclude resources from backup. Each object must have a 'key' (such as 'aws:ResourceTag/Environment') and a 'value'. Only resources matching all conditions will be excluded. Default: empty list."
  default     = []
}

# Tagging
variable "tags" {
  type        = map(any)
  description = "Key-value map of tags to apply to all resources created by this module. Default: empty map."
  default     = {}
}

variable "tags_vault" {
  type        = map(any)
  description = "Key-value map of tags to apply specifically to backup vaults. Default: empty map."
  default     = {}
}

variable "tags_plan" {
  type        = map(any)
  description = "Key-value map of tags to apply specifically to backup plans. Default: empty map."
  default     = {}
}

# Additional Managed Policies
variable "additional_managed_policies" {
  type        = list(string)
  description = "List of up to 18 additional IAM policy ARNs to attach to the backup service role. These are combined with the required AWS Backup policies for a maximum of 20 policies per role. Default: empty list."
  default     = []

  validation {
    condition     = length(var.additional_managed_policies) <= 18
    error_message = "A maximum of 18 additional managed policies can be specified (20 total including required AWS Backup policies)."
  }
}
