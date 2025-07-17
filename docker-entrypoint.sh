#!/bin/sh
set -e

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
until awslocal sts get-caller-identity --endpoint-url=http://localstack:4566 >/dev/null 2>&1; do
  echo "LocalStack not ready yet, waiting..."
  sleep 1
done

echo "LocalStack is ready!"

# Initialize Terraform
echo "Initializing Terraform..."
terraform init

# Execute the CMD
if [ "$#" -gt 0 ]; then
  exec "$@"
fi
