#!/bin/bash

# k6 Docker Wrapper Script
# Run k6 load tests using Docker instead of installing k6 locally

set -e

SCRIPT_FILE="${1:-load_test.js}"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: Test script '$SCRIPT_FILE' not found"
    echo "Usage: ./k6_docker.sh [script_file]"
    echo "Example: ./k6_docker.sh load_test.js"
    exit 1
fi

echo "Running k6 load test using Docker..."
echo "Script: $SCRIPT_FILE"
echo ""

# Run k6 in Docker with host networking
docker run --rm -i \
    --network=host \
    -v "$(pwd):/scripts" \
    docker.io/grafana/k6:latest \
    run /scripts/"$SCRIPT_FILE"
