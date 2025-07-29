FROM python:3.9-slim

WORKDIR /app

# Install curl for healthchecks
RUN apt-get update && apt-get install -y curl && rm -rf /var/lib/apt/lists/*

# Copy the mock backup service
COPY mock_backup.py .

# Install dependencies
RUN pip install boto3

# Expose port
EXPOSE 5000

# Run the mock service
CMD ["python", "mock_backup.py"]