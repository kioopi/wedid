#!/bin/bash
set -e

# Script to start the application using Docker Compose

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "Docker is not running. Please start Docker and try again."
    exit 1
fi

if [ -n "$GHCR_PAT" ]; then
    echo $GHCR_PAT | docker login ghcr.io -u kioopi --password-stdin
fi

# Pull the latest image
docker compose pull

# Restart the application
docker compose up -d

# Clean up unused images
docker image prune -f
