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

resource "aws_iam_role" "service_role" {
  name               = "example"
  assume_role_policy = data.aws_iam_policy_document.service_link.json
}

resource "aws_iam_role_policy_attachment" "service_role_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.service_role.name
}


## Weekly Plan

resource "aws_backup_vault" "weekly" {
  name = "weekly"
}

resource "aws_backup_plan" "weekly" {
  name = "weekly"

  rule {
    rule_name         = "weekly"
    target_vault_name = aws_backup_vault.weekly.name
    schedule          = "cron(0 0 ? * SUN *)"

    lifecycle {
      delete_after = 90
    }
  }
}

resource "aws_backup_selection" "weekly" {
  iam_role_arn = aws_iam_role.service_role.arn
  name         = "weekly"
  plan_id      = aws_backup_plan.weekly.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupWeekly"
    value = "true"
  }
}

# Quarterly Plan

resource "aws_backup_vault" "quarterly" {
  name = "quarterly"
}

resource "aws_backup_plan" "quarterly" {
  name = "quarterly"

  rule {
    rule_name         = "quarterly"
    target_vault_name = aws_backup_vault.quarterly.name
    schedule          = "cron(0 0 L 3,6,9,12 * *)"

    lifecycle {
      cold_storage_after = 365
    }
  }
}

resource "aws_backup_selection" "quarterly" {
  iam_role_arn = aws_iam_role.service_role.arn
  name         = "quarterly"
  plan_id      = aws_backup_plan.quarterly.id

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "BackupQuarterly"
    value = "true"
  }
}
