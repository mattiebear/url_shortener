#!/bin/bash

# k6 Podman Wrapper Script
# Run k6 load tests using Podman instead of Docker

set -e

SCRIPT_FILE="${1:-load_test.js}"

if [ ! -f "$SCRIPT_FILE" ]; then
    echo "Error: Test script '$SCRIPT_FILE' not found"
    echo "Usage: ./k6_podman.sh [script_file]"
    echo "Example: ./k6_podman.sh load_test.js"
    exit 1
fi

echo "Running k6 load test using Podman..."
echo "Script: $SCRIPT_FILE"
echo ""

# Run k6 in Podman with host networking
podman run --rm -i \
    --network=host \
    -v "$(pwd):/scripts" \
    docker.io/grafana/k6:latest \
    run /scripts/"$SCRIPT_FILE"
