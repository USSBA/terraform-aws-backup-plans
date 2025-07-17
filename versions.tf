terraform {
  required_version = ">= 1.12.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
      configuration_aliases = [
        aws.cross_region # Alias for cross-region provider
      ]
    }
  }
}

# Cross-region provider is conditionally created when cross_region_backup_enabled is true
resource "aws_backup_region_settings" "cross_region" {
  count = local.create_cross_region_resources ? 1 : 0

  # Use the cross-region provider alias
  provider = aws.cross_region # Using underscore to match the alias in the test fixture

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
