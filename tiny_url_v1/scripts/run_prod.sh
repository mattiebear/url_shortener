#!/bin/bash
# Run the production release

set -e

# Set required environment variables
export PHX_SERVER=true
export PORT=4000
export DATABASE_URL="ecto://postgres:postgres@localhost/tiny_url_dev"

echo "Starting production server on port $PORT..."
echo "Press Ctrl+C to stop"
echo ""

# Run the release
_build/prod/rel/tiny_url/bin/tiny_url start
