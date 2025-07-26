terraform {
  required_version = ">= 1.12.0"
  required_providers {
    # AWS provider is required for backup vault, IAM role, and region settings resources
    # Cross-region provider (aws.cross_region) is optional and passed via providers block when needed
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.cross_region]
    }
  }
}

