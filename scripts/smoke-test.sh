#!/bin/bash
set -e

echo "🔍 Running smoke tests..."

if [ -n "$STAGING_URL" ]; then
    URL=$STAGING_URL
    ENV="staging"
elif [ -n "$PRODUCTION_URL" ]; then
    URL=$PRODUCTION_URL
    ENV="production"
else
    echo "❌ No URL specified for smoke tests"
    exit 1
fi

echo "Testing $ENV environment: $URL"

# Test HTTP response
echo "Testing HTTP response..."
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" $URL)
if [ "$HTTP_STATUS" -ne 200 ]; then
    echo "❌ Smoke test failed: HTTP status $HTTP_STATUS"
    exit 1
fi

# Test database connection
echo "Testing database connection..."
if curl -s $URL | grep -q "Database connection failed"; then
    echo "❌ Smoke test failed: Database connection error"
    exit 1
fi

# Test essential pages
echo "Testing essential pages..."
for endpoint in "" "/admin" "/user/login" "/node"; do
    if ! curl -s -f $URL$endpoint > /dev/null; then
        echo "❌ Smoke test failed: Endpoint $endpoint not accessible"
        exit 1
    fi
    echo "✅ Endpoint $endpoint accessible"
done

# Test write permissions
echo "Testing file system permissions..."
if curl -s $URL | grep -q "The directory sites/default/files is not writable"; then
    echo "❌ Smoke test failed: File system not writable"
    exit 1
fi

echo "✅ All smoke tests passed for $ENV environment!"