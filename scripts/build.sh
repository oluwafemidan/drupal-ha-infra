#!/bin/bash
set -e

echo "🚀 Building Drupal application..."

# Create reports directory for tests (if it doesn't exist)
mkdir -p tests/reports

# Install dependencies
composer install --no-dev --optimize-autoloader

# Build frontend assets (if using theme)
if [ -d "web/themes/custom/my_theme" ]; then
    echo "🎨 Building theme assets..."
    cd web/themes/custom/my_theme
    npm install
    npm run build
    cd ../../../..
fi

# Create build artifact (exclude test reports and other non-essential files)
tar -czf drupal-build-$(date +%Y%m%d%H%M%S).tar.gz \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='node_modules' \
    --exclude='vendor' \
    --exclude='tests/reports/*.xml' \
    --exclude='drupal-build-*.tar.gz' \
    .

echo "✅ Build completed successfully! Artifact: drupal-build-*.tar.gz"