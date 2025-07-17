# Test GitHub Actions workflows with Act
Write-Host "Testing GitHub Actions workflows with Act..."

# Check if act is installed
if (-not (Get-Command act -ErrorAction SilentlyContinue)) {
    Write-Host "Act is not installed. Please install it first: https://github.com/nektos/act#installation" -ForegroundColor Red
    exit 1
}

# Run act with the test workflow
Write-Host "Running GitHub Actions workflows locally..." -ForegroundColor Cyan
act -j format
act -j validate
act -j spellcheck

Write-Host "`nGitHub Actions workflows tested successfully!" -ForegroundColor Green
