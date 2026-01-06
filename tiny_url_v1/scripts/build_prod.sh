#!/bin/bash
# Build production release for load testing

set -e

echo "Building production release..."

# Build assets for production
echo "1. Building and minifying assets..."
MIX_ENV=prod mix assets.deploy

# Compile the release
echo "2. Compiling production release..."
MIX_ENV=prod mix release --overwrite

echo ""
echo "✓ Production build complete!"
echo ""
echo "To run the release:"
echo "  ./run_prod.sh"
echo ""
echo "The server will run on http://localhost:4000"
