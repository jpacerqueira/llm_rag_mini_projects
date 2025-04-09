#!/bin/bash

# Create a directory for DuckDB data
mkdir -p duckdb_data

# Initialize DuckDB and run the initialization script
duckdb duckdb_data/cloud_risk_portal.duckdb < init_duckdb.sql

# Verify the setup
echo "DuckDB setup completed. Database file created at: duckdb_data/cloud_risk_portal.duckdb"
echo "You can connect to the database using: duckdb duckdb_data/cloud_risk_portal.duckdb" 