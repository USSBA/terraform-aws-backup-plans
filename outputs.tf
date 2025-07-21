output "vault_name" {
  description = "The name of the created backup vault"
  value       = try(aws_backup_vault.daily[0].name, "")
}

output "backup_schedule" {
  description = "The configured backup schedule"
  value       = try([for rule in aws_backup_plan.daily[0].rule : rule.schedule][0], "")
}

output "backup_resource_types" {
  description = "List of resource types targeted for backup"
  value       = var.backup_resource_types
}

output "iam_role_arn" {
  description = "ARN of the IAM role used for backups"
  value       = try(aws_iam_role.service_role[0].arn, "")
}

output "backup_selection" {
  description = "The backup selection configuration including selection tags"
  value = local.daily_backup_count > 0 ? [{
    selection_tag = concat(
      var.use_tags && var.daily_backup_tag_key != "" && var.daily_backup_tag_value != "" ? [
        {
          key   = var.daily_backup_tag_key
          value = var.daily_backup_tag_value
          type  = "STRINGEQUALS"
        }
      ] : [],
      [for k, v in var.backup_resource_tags : {
        key   = k
        value = v
        type  = "STRINGEQUALS"
      }]
    )
  }] : []
}
