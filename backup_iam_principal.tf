data "aws_iam_policy_document" "service_link" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "service_role" {
  count              = local.enabled_count
  name               = var.service_role_name != "" ? var.service_role_name : "backup-service-role-${var.vault_name}"
  assume_role_policy = data.aws_iam_policy_document.service_link.json
  
  # Add tags to the role for better resource management
  tags = merge(
    var.tags,
    {
      Name = var.service_role_name != "" ? var.service_role_name : "backup-service-role-${var.vault_name}"
    }
  )
}

locals {
  # Define required policies
  required_policies = [
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Backup",
    "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForRestores",
    "arn:aws:iam::aws:policy/AWSBackupServiceRolePolicyForS3Restore"
  ]
  
  # Combine required policies with additional policies, ensuring no duplicates
  all_policies = distinct(concat(
    local.required_policies,
    var.additional_managed_policies
  ))
}

# Attach all policies to the IAM role using a single resource with for_each
resource "aws_iam_role_policy_attachment" "managed_policies" {
  for_each = local.enabled_count > 0 ? toset(local.all_policies) : toset([])
  
  policy_arn = each.key
  role       = aws_iam_role.service_role[0].name
  
  # Ensure the role exists before attaching policies
  depends_on = [aws_iam_role.service_role]
}
