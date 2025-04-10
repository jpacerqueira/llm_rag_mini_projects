#!/bin/bash

# Create necessary directories
mkdir -p trino_data/etc trino_data/etc/catalog trino_data/data

# Create Trino configuration
cat > trino_data/etc/config.properties << EOF
coordinator=true
node-scheduler.include-coordinator=true
http-server.http.port=8080
query.max-memory=4GB
query.max-memory-per-node=1GB
discovery.uri=http://0.0.0.0:8080
EOF

cat > trino_data/etc/node.properties << EOF
node.environment=production
node.id=ffffffff-ffff-ffff-ffff-ffffffffffff
node.data-dir=/var/trino/data
EOF

cat > trino_data/etc/catalog/hive.properties << EOF
connector.name=hive
hive.metastore.uri=thrift://0.0.0.0:9083
EOF

# Create JVM configuration
cat > trino_data/etc/jvm.config << EOF
-server
-Xmx8G
-Xms8G
-XX:InitialRAMPercentage=80
-XX:MaxRAMPercentage=80
-XX:+UseG1GC
-XX:G1HeapRegionSize=32M
-XX:+ExplicitGCInvokesConcurrent
-XX:+HeapDumpOnOutOfMemoryError
-XX:+ExitOnOutOfMemoryError
-XX:ReservedCodeCacheSize=512M
-XX:PerMethodRecompilationCutoff=10000
-XX:PerBytecodeRecompilationCutoff=10000
-Djdk.attach.allowAttachSelf=true
-Djdk.nio.maxCachedBufferSize=2000000
-XX:+UseStringDeduplication
-XX:+UseCompressedOops
-XX:+OptimizeStringConcat
-XX:+UseNUMA
-XX:+PerfDisableSharedMem
-XX:+AlwaysPreTouch
-XX:+UseTransparentHugePages
-XX:+UseLargePages
EOF

# Start custom Hive-Metastore
docker pull naushadh/hive-metastore:latest
docker run -d \
    --name hive-metastore \
    --network rag-network \
    -p 9083:9083 \
    -v $(pwd)/trino_data/etc/catalog/hive.properties:/etc/hive/conf/hive-site.xml \
    -e DATABASE_HOST=postgres_rag_db \
    -e DATABASE_PORT=5432 \
    -e DATABASE_USER=postgres \
    -e DATABASE_PASSWORD=password \
    -e DATABASE_DB=hive \
    naushadh/hive-metastore:latest

# Wait for Hive-Metastore to start
echo "Waiting 20secs. for Trino to start..."
sleep 20

# Start Trino using Docker
docker run -d \
    --name trinodb \
    --network rag-network \
    -p 8080:8080 \
    -v $(pwd)/trino_data/etc:/etc/trino \
    -v $(pwd)/trino_data/data:/var/trino/data \
    -e JAVA_HOME=/usr/lib/jvm/temurin/jdk-24+36 \
    trinodb/trino:474 
#   trinodb/trino:latest

# Wait for Trino to start
echo "Waiting 120secs. for Trino to start..."
sleep 120

# Run the initialization script
docker exec -i trinodb trino --server http://host.docker.internal:8080 --catalog hive --schema cloud_risk_portal_rag_data < init_trino.sql

echo "Trino setup completed!"
echo "Trino is running at http://localhost:8080"
echo "You can connect using: docker exec -it trinodb trino" 