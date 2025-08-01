terraform {
  required_version = "~> 1.9.5"
  required_providers {
    # AWS provider is required for backup vault, IAM role, and region settings resources
    # Cross-region provider (aws.cross_region) is optional and passed via providers block when needed
    # Without this the module will throw warnings about missing providers.
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      configuration_aliases = [aws.cross_region]
    }
  }
}

provider "aws" {
  alias  = "cross_region"
  region = var.cross_region_destination
}
