resource "aws_backup_region_settings" "opt_in" {
  count = local.daily_backup_count

  resource_type_opt_in_preference = var.opt_in_settings
}
# Cross-region provider is conditionally created when cross_region_backup_enabled is true
resource "aws_backup_region_settings" "cross_region" {
  for_each = local.create_cross_region_resources ? { "cross_region" = true } : {}

  # Use the cross-region provider alias
  provider = aws.cross_region

  # Configure which resource types are included in backups by default
  resource_type_opt_in_preference = {
    "Aurora"          = true
    "DocumentDB"      = true
    "DynamoDB"        = true
    "EBS"             = true
    "EC2"             = true
    "EFS"             = true
    "FSx"             = true
    "Neptune"         = true
    "RDS"             = true
    "Storage Gateway" = true
    "VirtualMachine"  = true
  }
}