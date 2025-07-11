resource "aws_backup_region_settings" "opt_in" {
  count = local.daily_backup_count
  
  resource_type_opt_in_preference = var.opt_in_settings
}
