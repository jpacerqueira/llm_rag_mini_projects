#!/bin/bash

# Create necessary directories
mkdir -p trino_data/etc trino_data/data

# Create Trino configuration
cat > trino_data/etc/config.properties << EOF
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8080
query.max-memory=5GB
query.max-memory-per-node=1GB
query.max-total-memory-per-node=2GB
discovery-server.enabled=true
discovery.uri=http://localhost:8080
EOF

cat > trino_data/etc/node.properties << EOF
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
node.data-dir=/var/trino/data
EOF

cat > trino_data/etc/catalog/hive.properties << EOF
connector.name=hive
hive.metastore.uri=thrift://localhost:9083
EOF

# Start Trino using Docker
docker run -d \
    --name trino \
    -p 8080:8080 \
    -v $(pwd)/trino_data/etc:/etc/trino \
    -v $(pwd)/trino_data/data:/var/trino/data \
    --network rag-network \
    trinodb/trino:latest

# Wait for Trino to start
echo "Waiting for Trino to start..."
sleep 30

# Run the initialization script
docker exec -i trino trino --catalog hive --schema default < init_trino.sql

echo "Trino setup completed!"
echo "Trino is running at http://localhost:8080"
echo "You can connect using: docker exec -it trino trino" 