# Test Docker setup for Windows
Write-Host "Testing Docker setup..."

# Create .env file if it doesn't exist
if (-not (Test-Path .env)) {
    Copy-Item .env.example .env
    Write-Host "Created .env file from example"
}

# Build and start the containers
Write-Host "Building and starting containers..."
docker-compose up -d

# Function to check if LocalStack is ready
function Test-LocalStackReady {
    try {
        $result = docker-compose exec -T localstack awslocal sts get-caller-identity 2>&1
        return $LASTEXITCODE -eq 0
    } catch {
        return $false
    }
}

# Wait for LocalStack to be ready
$maxRetries = 12
$retryCount = 0
Write-Host "Waiting for LocalStack to be ready..."
do {
    if (Test-LocalStackReady) {
        break
    }
    
    $retryCount++
    if ($retryCount -ge $maxRetries) {
        Write-Host "LocalStack failed to start after $maxRetries attempts" -ForegroundColor Red
        exit 1
    }
    
    Write-Host "LocalStack not ready yet, waiting... (attempt $retryCount of $maxRetries)"
    Start-Sleep -Seconds 5
} while ($true)

Write-Host "LocalStack is ready!" -ForegroundColor Green

# Run tests
Write-Host "Running tests..." -ForegroundColor Cyan
# Run tests from the tests directory
docker-compose exec -w /workspace/tests test-runner terraform init
docker-compose exec -w /workspace/tests test-runner terraform test

Write-Host "Tests completed!" -ForegroundColor Green
