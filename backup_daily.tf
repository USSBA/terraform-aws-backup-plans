# Daily Backup Plan
# - Runs every day @ 08:00 AM UTC
# - Backups are transitioned to cold storage after 30 days
# - Backups are then removed after 120 total days (30 in warm storage, 90 in cold storage)

resource "aws_backup_vault" "daily" {
  count = local.daily_backup_count

  name = var.vault_name
  tags = merge(var.tags, var.tags_vault)
}

resource "aws_backup_vault" "daily_cross_region" {
  count = local.create_cross_region_resources ? 1 : 0

  name     = "${var.vault_name}-cross-region"
  tags     = merge(var.tags, var.tags_vault)
  provider = aws.cross_region
}

resource "aws_backup_plan" "daily" {
  count = local.daily_backup_count

  name = var.vault_name
  tags = merge(var.tags, var.tags_plan)

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

  dynamic "selection_tag" {
    for_each = var.use_tags ? [1] : []
    
    content {
      type  = "STRINGEQUALS"
      key   = var.daily_backup_tag_key
      value = var.daily_backup_tag_value
    }
  }

  dynamic "selection_tag" {
    for_each = var.use_tags ? var.backup_resource_tags : {}
    
    content {
      type  = "STRINGEQUALS"
      key   = selection_tag.key
      value = selection_tag.value
    }
  }

  resources = var.use_tags ? null : var.backup_resource_types

  # Ensure at least one selection method is provided
  lifecycle {
    precondition {
      condition     = (var.use_tags && (length(keys(var.backup_resource_tags)) > 0 || (var.daily_backup_tag_key != "" && var.daily_backup_tag_value != ""))) || (!var.use_tags && length(var.backup_resource_types) > 0)
      error_message = <<-EOT
        When use_tags is true, either backup_resource_tags must be non-empty or daily_backup_tag_key and daily_backup_tag_value must be set.
        When use_tags is false, backup_resource_types must be non-empty.
      EOT
    }
  }
}
