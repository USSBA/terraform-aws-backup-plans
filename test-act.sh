#!/bin/bash
set -e

echo "Testing GitHub Actions workflows with Act..."

# Check if act is installed
if ! command -v act &> /dev/null; then
    echo "Act is not installed. Please install it first: https://github.com/nektos/act#installation"
    exit 1
fi

# Run act with the test workflow
echo "Running GitHub Actions workflows locally..."
act -j format
act -j validate
act -j spellcheck

echo -e "\033[0;32mGitHub Actions workflows tested successfully!\033[0m"
