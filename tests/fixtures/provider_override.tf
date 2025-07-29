# Override the AWS provider to use the mock Backup service
provider "aws" {
  region = "us-east-1"

  # Use LocalStack for all services except Backup
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  # Point to LocalStack for all services
  endpoints {
    s3         = "http://localstack:4566"
    iam        = "http://localstack:4566"
    sts        = "http://localstack:4566"
    cloudwatch = "http://localstack:4566"
    events     = "http://localstack:4566"
    backup     = "http://mock-backup:5000"
  }

  # Test credentials
  access_key = "test"
  secret_key = "test"
}
