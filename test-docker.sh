#!/bin/bash
set -e

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    cp .env.example .env
    echo "Created .env file from example"
fi

# Build and start the containers
echo "Building and starting containers..."
docker-compose up -d

# Function to check if LocalStack is ready
localstack_ready() {
    docker-compose exec -T localstack awslocal sts get-caller-identity >/dev/null 2>&1
    return $?
}

# Wait for LocalStack to be ready
echo "Waiting for LocalStack to be ready..."
max_retries=12
retry_count=0

until localstack_ready; do
    retry_count=$((retry_count + 1))
    if [ $retry_count -ge $max_retries ]; then
        echo "LocalStack failed to start after $max_retries attempts" >&2
        exit 1
    fi
    
    echo "LocalStack not ready yet, waiting... (attempt $retry_count of $max_retries)"
    sleep 5
done

echo -e "\033[0;32mLocalStack is ready!\033[0m"

# Run tests from the tests directory
echo -e "\033[1;36mRunning tests...\033[0m"
docker-compose exec -w /workspace/tests test-runner terraform init
docker-compose exec -w /workspace/tests test-runner terraform test

echo -e "\033[0;32mTests completed!\033[0m"
