#!/bin/bash

# Get the absolute path of the current directory
CURRENT_DIR=$(pwd)

# Build the Docker image
echo "Building Docker image..."
docker build -t llm-dev-env -f python312.Dockerfile .

# Run the Docker container with volume mounting and port mapping
echo "Starting Docker container..."
docker run -it \
    -p 8888:8888 \
    -p 5000-5009:5000-5009 \
    -p 8000-8009:8000-8009 \
    -p 8501-8509:8501-8509 \
    -p 9999:9999 \
    -v "${CURRENT_DIR}:/app/my_apps" \
    --name llm-dev-container \
    llm-dev-env

# If the container was stopped, remove it
echo "Cleaning up..."
docker stop llm-dev-container
#docker rm llm-dev-container
