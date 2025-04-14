#!/bin/bash

# Get the absolute path of the current directory
CURRENT_DIR=$(pwd)

# Build the Docker image
echo "Building Docker image..."
docker build -t llm-dev-env -f python311.Dockerfile .

# Run the Docker container with volume mounting
echo "Starting Docker container..."
docker run -it \
    -p 8888:8888 \
    -v "${CURRENT_DIR}:/app/my_apps" \
    --name llm-dev-container \
    llm-dev-env

# If the container was stopped, remove it
echo "Cleaning up..."
docker rm llm-dev-container 
