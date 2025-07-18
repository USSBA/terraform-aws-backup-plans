#!/bin/sh
set -e

# Set AWS environment variables for LocalStack
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=us-east-1
export AWS_ENDPOINT_URL=http://localstack:4566

# Function to check if LocalStack is responding
wait_for_localstack() {
  local max_attempts=30
  local attempt=0
  
  echo "Waiting for LocalStack to be ready..."
  
  # First check if the main endpoint is responding
  until curl -s http://localstack:4566/health >/dev/null; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      echo "LocalStack is not responding after $max_attempts attempts. Continuing anyway..."
      break
    fi
    echo "LocalStack not responding yet (attempt $attempt/$max_attempts)..."
    sleep 2
  done
  
  # Then check if we can make API calls
  until awslocal sts get-caller-identity >/dev/null 2>&1; do
    attempt=$((attempt + 1))
    if [ $attempt -ge $max_attempts ]; then
      echo "AWS API not responding after $max_attempts attempts. Continuing anyway..."
      break
    fi
    echo "AWS API not ready yet (attempt $attempt/$max_attempts)..."
    sleep 2
  done
  
  echo "LocalStack is ready for testing!"
}

# Wait for LocalStack to be ready
wait_for_localstack

# Initialize Terraform in the tests directory
echo "Initializing Terraform in the tests directory..."
cd /workspace/tests

# Initialize Terraform with local backend
cat > backend.tf <<EOL
terraform {
  backend "local" {}
}
EOL

# Initialize Terraform
terraform init -backend=false

# Execute the CMD
echo "Executing command: $@"
if [ "$#" -gt 0 ]; then
  exec "$@"
fi
