terraform {
  required_version = ">= 0.13"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 2.30, < 4.0.0"
    }
  }
}

provider "aws" {
  alias  = "cross-region"
  region = var.cross_region_destination
}
