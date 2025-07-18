# Check if Docker is running
try {
    $dockerVersion = docker version --format '{{.Server.Version}}' 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "Docker is not running or not installed. Please start Docker Desktop and try again."
    }
    Write-Host "Docker is running (version: $dockerVersion)" -ForegroundColor Green
}
catch {
    Write-Error "Error: $_"
    exit 1
}

# Clean up any existing containers
Write-Host "`nCleaning up any existing containers..." -ForegroundColor Cyan
docker-compose down -v 2>&1 | Out-Null

# Build and start the containers
Write-Host "`nBuilding and starting Docker containers..." -ForegroundColor Cyan
docker-compose up -d --build

# Check if containers started successfully
$containers = docker-compose ps --services --all 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to start containers. Check the logs with 'docker-compose logs'"
    exit 1
}

Write-Host "`nContainers started successfully:" -ForegroundColor Green
$containers | ForEach-Object { Write-Host "- $_" }

# Wait for LocalStack to be ready
Write-Host "`nWaiting for LocalStack to be ready..." -ForegroundColor Cyan
$maxRetries = 30
$retryCount = 0
$localstackReady = $false

# First check if the LocalStack container is running at all
$containerRunning = $false
while (-not $containerRunning -and $retryCount -lt $maxRetries) {
    $containerStatus = docker inspect --format='{{.State.Status}}' localstack 2>&1
    if ($LASTEXITCODE -eq 0 -and $containerStatus -eq "running") {
        $containerRunning = $true
        Write-Host "LocalStack container is running" -ForegroundColor Green
        break
    }
    Write-Host "Waiting for LocalStack container to start... (attempt $($retryCount + 1)/$maxRetries)" -ForegroundColor Yellow
    $retryCount++
    Start-Sleep -Seconds 2
}

if (-not $containerRunning) {
    Write-Warning "LocalStack container did not start properly after $maxRetries attempts."
    Write-Host "Container logs:" -ForegroundColor Red
    docker logs localstack
    exit 1
}

# Now check if the LocalStack services are responding
$retryCount = 0
$servicesReady = $false

while (-not $servicesReady -and $retryCount -lt $maxRetries) {
    $health = docker inspect --format='{{.State.Health.Status}}' localstack 2>&1
    
    # Check if we can make API calls regardless of health status
    $apiCheck = docker exec localstack awslocal sts get-caller-identity 2>&1
    
    if ($LASTEXITCODE -eq 0) {
        $servicesReady = $true
        Write-Host "LocalStack services are responding!" -ForegroundColor Green
        break
    }
    
    Write-Host "Waiting for LocalStack services... (attempt $($retryCount + 1)/$maxRetries)" -ForegroundColor Yellow
    Write-Host "Health status: $health" -ForegroundColor Yellow
    Write-Host "API check: $apiCheck" -ForegroundColor Yellow
    
    $retryCount++
    Start-Sleep -Seconds 2
}

if (-not $servicesReady) {
    Write-Warning "LocalStack services did not become fully responsive after $maxRetries attempts."
    Write-Host "Container logs:" -ForegroundColor Red
    docker logs localstack
    Write-Host "`nAttempting to continue with tests anyway..." -ForegroundColor Yellow
}

# Run the tests in the test-runner container
Write-Host "`nRunning tests..." -ForegroundColor Cyan

# Create a test command script
$testCommand = @"
#!/bin/bash
set -e

# Change to the tests directory
cd /workspace/tests

# Create a local backend configuration
echo 'Initializing Terraform...'
cat > backend.tf <<EOL
terraform {
  backend "local" {}
}
EOL

# Initialize Terraform
echo 'Running terraform init...'
terraform init -backend=false

# Run the tests
echo 'Running terraform test...'
terraform test
"@

try {
    # Write the test command to a temporary file
    $tempScript = "test-command-$(Get-Date -Format 'yyyyMMddHHmmss').sh"
    $testCommand | Out-File -FilePath $tempScript -Encoding utf8 -NoNewline
    
    # Copy the script to the container
    Write-Host "Copying test script to container..." -ForegroundColor Cyan
    $containerId = docker-compose ps -q test-runner
    docker cp $tempScript "${containerId}:/tmp/run-tests.sh"
    
    # Make the script executable
    Write-Host "Making script executable..." -ForegroundColor Cyan
    docker exec $containerId chmod +x /tmp/run-tests.sh
    
    # Run the script and capture output
    Write-Host "Executing tests..." -ForegroundColor Cyan
    docker exec -i $containerId /tmp/run-tests.sh
    $testExitCode = $LASTEXITCODE
    
    # Clean up
    Remove-Item -Path $tempScript -Force -ErrorAction SilentlyContinue
}
catch {
    Write-Error "Error running tests: $_"
    $testExitCode = 1
}

# Output test results
if ($testExitCode -eq 0) {
    Write-Host "`nAll tests passed!" -ForegroundColor Green
} else {
    Write-Host "`nSome tests failed. Exit code: $testExitCode" -ForegroundColor Red
}

# Stop and remove the containers
Write-Host "`nStopping and removing containers..." -ForegroundColor Cyan
docker-compose down -v

# Exit with the test result code
exit $testExitCode