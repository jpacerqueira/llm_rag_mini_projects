#!/bin/bash

# Check if required parameters are provided
if [ "$#" -ne 3 ]; then
    echo "Usage: $0 <username> <password> <sql_script_path>"
    echo "Example: $0 postgres mypassword ./init_postgresql.sql"
    exit 1
fi

# Assign parameters
DB_USER="$1"
DB_PASSWORD="$2"
SQL_SCRIPT="$3"

# Check if SQL script exists
if [ ! -f "$SQL_SCRIPT" ]; then
    echo "Error: SQL script file '$SQL_SCRIPT' not found!"
    exit 1
fi

# Create a Docker volume for persistent data
docker volume rm postgres_rag_data || true
docker volume create postgres_rag_data || true

# Run PostgreSQL container
docker run -d \
    --name postgres_rag_db \
    -e POSTGRES_USER="$DB_USER" \
    -e POSTGRES_PASSWORD="$DB_PASSWORD" \
    -e POSTGRES_DB="cloud_risk_portal_rag_data" \
    -v postgres_rag_data:/var/lib/postgresql/data \
    -v "$(pwd)/$SQL_SCRIPT:/docker-entrypoint-initdb.d/init.sql" \
    -p 5432:5432 \
    --network rag-network \
    postgres:17

# Wait for PostgreSQL to be ready
echo "Waiting for PostgreSQL to start..."
sleep 10

# Check if container is running
if [ "$(docker ps -q -f name=postgres_rag_db)" ]; then
    echo "PostgreSQL container is running successfully!"
    echo "Connection details:"
    echo "Host: postgres_rag_db"
    echo "Port: 5432"
    echo "Database: cloud_risk_portal_rag_data"
    echo "Username: $DB_USER"
    echo "Password: $DB_PASSWORD"
else
    echo "Error: PostgreSQL container failed to start!"
    docker logs postgres_rag_db
    exit 1
fi 