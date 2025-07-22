output "vault_name" {
  description = "The name of the created backup vault"
  value       = try(aws_backup_vault.daily[0].name, "")
}

output "backup_schedule" {
  description = "The configured backup schedule"
  value       = try([for rule in aws_backup_plan.daily[0].rule : rule.schedule][0], "")
}

output "iam_role_arn" {
  description = "ARN of the IAM role used for backups"
  value       = try(aws_iam_role.service_role[0].arn, "")
}
