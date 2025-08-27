#!/bin/bash
set -e

echo "🔧 Setting up test environment..."

# Create necessary directories
mkdir -p tests/reports
mkdir -p tests/unit
mkdir -p tests/integration

# Set proper permissions
chmod -R 755 tests/

echo "✅ Test environment setup completed!"