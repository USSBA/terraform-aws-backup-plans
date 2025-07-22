# Daily Backup Plan
# - Runs every day @ 08:00 AM UTC
# - Backups are transitioned to cold storage after 30 days
# - Backups are then removed after 120 total days (30 in warm storage, 90 in cold storage)

resource "aws_backup_vault" "daily" {
  count = local.daily_backup_count

  name = var.vault_name
  tags = var.tags_vault
}

resource "aws_backup_vault" "daily_cross_region" {
  count = local.create_cross_region_resources ? 1 : 0

  name     = "${var.vault_name}-cross-region"
  tags     = var.tags_vault
  provider = aws.cross_region
}

resource "aws_backup_plan" "daily" {
  count = local.daily_backup_count

  name = var.vault_name
  tags = var.tags_plan

  rule {
    rule_name         = "daily"
    target_vault_name = aws_backup_vault.daily[0].name
    schedule          = var.backup_schedule
    start_window      = var.start_window_minutes
    completion_window = var.completion_window_minutes

    lifecycle {
      cold_storage_after = 30  # Days until transition to Glacier
      delete_after       = 120 # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
    }

    dynamic "copy_action" {
      for_each = local.create_cross_region_resources ? ["copy backups to the new region"] : []
      content {
        destination_vault_arn = aws_backup_vault.daily_cross_region[0].arn

        lifecycle {
          cold_storage_after = 30  # Days until transition to Glacier
          delete_after       = 120 # Days until permanent deletion (Must be 90 days greater than cold_storage_after.)
        }
      }
    }
  }
}

resource "aws_backup_selection" "daily" {
  count = local.daily_backup_count

  iam_role_arn = aws_iam_role.service_role[0].arn
  name         = var.vault_name
  plan_id      = aws_backup_plan.daily[0].id

  # Include resources by ARN patterns if specified
  resources = var.resource_arns

  # Always select by Environment=prod tag
  dynamic "selection_tag" {
    for_each = [1]
    content {
      type  = "STRINGEQUALS"
      key   = "Environment"
      value = "prod"
    }
  }

  # Add exclusion conditions if any are specified
  dynamic "condition" {
    for_each = var.exclude_conditions

    content {
      string_equals {
        key   = condition.value.key
        value = condition.value.value
      }
    }
  }

  # Ensure at least one valid selection method is provided
  lifecycle {
    precondition {
      condition = (
        length(var.resource_arns) > 0
      )
      error_message = <<-EOT
        At least one resource ARN must be specified in resource_arns.
      EOT
    }
  }
}
