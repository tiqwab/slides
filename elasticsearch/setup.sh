#!/bin/bash

set -eux

# Remove if already started
docker-compose stop || true
docker-compose rm || true

# Start Elasticsearch
docker-compose up -d

# Wait until Elasticsearch ready
set +e
for i in $(seq 10); do
    curl 'http://localhost:9200/_cluster/health?wait_for_status=green&timeout=1m' 2>&1 > /dev/null
    if [ $? -eq 0 ]; then
        break
    else
        echo "waiting for Elasticsearch setup..."
    fi
    sleep 3
done
set -e

# Create an index
curl -H "Content-Type: application/json" -XPUT http://localhost:9200/index1 -d '{
    "settings": {
        "index": {
            "number_of_shards": 3,
            "number_of_replicas": 0
        }
    }
}'

echo "created index1"
