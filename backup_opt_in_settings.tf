resource "aws_backup_region_settings" "opt_in" {
  resource_type_opt_in_preference = var.opt_in_settings
}

# Cross-region provider is conditionally created when cross_region_backup_enabled is true
resource "aws_backup_region_settings" "cross_region" {
  provider = aws.cross_region
  count    = var.cross_region_backup_enabled ? 1 : 0

  resource_type_opt_in_preference = var.opt_in_settings
}
