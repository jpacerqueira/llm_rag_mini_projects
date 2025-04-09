#!/bin/bash

# Check if OPER parameter is provided
OPER=${1:-0}

# Set environment variables
export POSTGRES_PASSWORD=password
export POSTGRES_HOST=postgres_rag_db
export POSTGRES_PORT=5432
export POSTGRES_USER=postgres
export POSTGRES_DB=cloud_risk_portal_rag_data
export OLLAMA_HOST=http://ollama_rag:11434
export LLM=llama3.2
export DBFILE=./init_postgresql.sql

if [ "$OPER" = "1" ]; then
    # Only manage sql-metadata-rag container
    echo "Managing sql-metadata-rag container only..."
    
    # Stop and remove existing container
    docker stop sql-metadata-rag || true
    docker rm sql-metadata-rag || true
    
    # Build and run the container
    echo "Building Docker image..."
    docker build -t sql-metadata-rag -f query_rag_data.Docker .
    
    if [ $? -ne 0 ]; then
        echo "Docker build failed. Exiting..."
        exit 1
    fi
    
    echo "Starting Docker container..."
    docker run -d \
        --name sql-metadata-rag \
        -p 8507:8507 \
        -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        -e POSTGRES_HOST=$POSTGRES_HOST \
        -e POSTGRES_PORT=$POSTGRES_PORT \
        -e POSTGRES_USER=$POSTGRES_USER \
        -e POSTGRES_DB=$POSTGRES_DB \
        -e OLLAMA_HOST=$OLLAMA_HOST \
        --network rag-network \
        --volume ./duckdb_data:/app/duckdb_data \
        sql-metadata-rag
    
    if [ $? -ne 0 ]; then
        echo "Failed to start container. Exiting..."
        exit 1
    fi
    
    echo "Container started successfully!"
    echo "Streamlit app is running at http://localhost:8507"
    echo "Showing container logs..."
    docker logs -f sql-metadata-rag
else
    # Full setup mode
    echo "Running full setup..."
    
    # Setup docker images and network
    docker stop sql-metadata-rag ollama_rag postgres_rag_db || true
    docker rm sql-metadata-rag ollama_rag postgres_rag_db || true
    docker network rm rag-network || true
    docker network create rag-network || true
    
    # Start Ollama container
    echo "Starting Ollama container..."
    docker run -d \
        --name ollama_rag \
        -p 11434:11434 \
        --network rag-network \
        ollama/ollama:0.5.0-rc1-rocm
    
    # Wait for Ollama to be ready
    echo "Waiting for Ollama to start..."
    sleep 10
    
    # Pull the required model
    echo "Pulling LLM model..."
    docker exec ollama_rag ollama pull $LLM
    
    # Run the setup_postgres.sh script
    echo "setup prostgresql"
    ./setup_postgres.sh $POSTGRES_USER $POSTGRES_PASSWORD $DBFILE
    echo "setup duckdb"
    ./setup_duckdb.sh
    echi "setup trino"
    ./setup_trino.sh
    
    # Build the Docker image
    echo "Building Docker image..."
    docker build -t sql-metadata-rag -f query_rag_data.Docker .
    
    if [ $? -ne 0 ]; then
        echo "Docker build failed. Exiting..."
        exit 1
    fi
    
    # Run the Docker container
    echo "Starting Docker container..."
    docker run -d \
        --name sql-metadata-rag \
        -p 8507:8507 \
        -e POSTGRES_PASSWORD=$POSTGRES_PASSWORD \
        -e POSTGRES_HOST=$POSTGRES_HOST \
        -e POSTGRES_PORT=$POSTGRES_PORT \
        -e POSTGRES_USER=$POSTGRES_USER \
        -e POSTGRES_DB=$POSTGRES_DB \
        -e OLLAMA_HOST=$OLLAMA_HOST \
        --network rag-network \
        --volume ./duckdb_data:/app/duckdb_data \
        sql-metadata-rag
    
    if [ $? -ne 0 ]; then
        echo "Failed to start container. Exiting..."
        exit 1
    fi
    
    echo "Container started successfully!"
    echo "Streamlit app is running at http://localhost:8507"
    echo "Showing container logs..."
    docker logs -f sql-metadata-rag
fi
