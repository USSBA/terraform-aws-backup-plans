terraform {
  required_version = "~> 0.12.9"
  required_providers {
    aws = "~> 2.30"
  }
}

data "aws_iam_policy_document" "service_link" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["backup.amazonaws.com"]
    }
  }
}

locals {
  enabled_count = var.enabled ? 1 : 0
}
resource "aws_iam_role" "service_role" {
  count              = local.enabled_count
  name               = "backup-service-role"
  assume_role_policy = data.aws_iam_policy_document.service_link.json
}

resource "aws_iam_role_policy_attachment" "service_role_attachment" {
  count      = local.enabled_count
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = var.enabled ? aws_iam_role.service_role[0].name : ""
}


## Weekly Plan

locals {
  weekly_backup_enabled = var.enabled && var.weekly_backup_enabled
  weekly_backup_count   = var.enabled && var.weekly_backup_enabled ? 1 : 0
}
resource "aws_backup_vault" "weekly" {
  count = local.weekly_backup_count
  name  = "weekly"
}

resource "aws_backup_plan" "weekly" {
  count = local.weekly_backup_count
  name  = "weekly"

  rule {
    rule_name         = "weekly"
    target_vault_name = aws_backup_vault.weekly[0].name
    schedule          = "cron(0 0 ? * SUN *)"

    lifecycle {
      delete_after = 90
    }
  }
}

resource "aws_backup_selection" "weekly" {
  count        = local.weekly_backup_count
  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "weekly"
  plan_id      = aws_backup_plan.weekly[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.weekly_backup_tag_key
    value = var.weekly_backup_tag_value
  }
}

# Quarterly Plan

locals {
  quarterly_backup_enabled = var.enabled && var.quarterly_backup_enabled
  quarterly_backup_count   = var.enabled && var.quarterly_backup_enabled ? 1 : 0
}
resource "aws_backup_vault" "quarterly" {
  count = local.quarterly_backup_count
  name  = "quarterly"
}

resource "aws_backup_plan" "quarterly" {
  count = local.quarterly_backup_count
  name  = "quarterly"

  rule {
    rule_name         = "quarterly"
    target_vault_name = aws_backup_vault.quarterly[0].name
    schedule          = "cron(0 0 L 3,6,9,12 ? *)"

    lifecycle {
      cold_storage_after = 365
    }
  }
}

resource "aws_backup_selection" "quarterly" {
  count        = local.quarterly_backup_count
  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = "quarterly"
  plan_id      = aws_backup_plan.quarterly[0].id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = var.quarterly_backup_tag_key
    value = var.quarterly_backup_tag_value
  }
}
