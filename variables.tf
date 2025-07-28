# Region Configuration
variable "region" {
  type        = string
  description = "The AWS region in which all backup resources will be created. Applies to all resources unless overridden elsewhere. Default: us-east-1."
  default     = "us-east-1"
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

# Resource Selection
variable "resource_arns" {
  type        = list(string)
  description = "Required list of specific resource ARNs or ARN patterns to include in backup selection. Example: ['arn:aws:ec2:region:account-id:volume/*']."
  validation {
    condition     = length(var.resource_arns) < 1
    error_message = "Must provide at least 1 resource ARN: note that wildcard ARN match patterns may be used."
  }
}

variable "environment_tag_value" {
  type        = string
  description = "Optional: The value of the Environment resource tag used in the aws_backup_selection. Default: 'prod'."
  default     = "prod"
  validation {
    condition     = length(var.environment_tag_value) < 1
    error_message = "The environment_tag_value must contain at least 1 alphanumberic character."
  }
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

# Vault Notifications
variable "sns_topic_arn" {
  type        = string
  description = "ARN of the SNS topic to receive backup vault notifications (e.g., backup job completion, failures). Leave blank to disable notifications. Default: empty string."
  default     = ""
}
