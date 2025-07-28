output "vault_id" {
  description = "The name of the created backup vault"
  value       = aws_backup_vault.daily.id
}

output "vault_arn" {
  description = "The ARN of the created backup vault"
  value       = aws_backup_vault.daily.arn
}

output "plan_id" {
  description = "The name of the created backup plan"
  value       = aws_backup_plan.daily.arn
}

output "plan_arn" {
  description = "The ARN of the created backup pan"
  value       = aws_backup_plan.daily.arn
}

output "service_role_name" {
  description = "The name of the IAM service role"
  value       = aws_iam_role.service_role.name
}

output "service_role_arn" {
  description = "The ARN of the IAM service role"
  value       = aws_iam_role.service_role.arn
}
