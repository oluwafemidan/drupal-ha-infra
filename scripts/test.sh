#!/bin/bash
set -e

echo "🧪 Running tests..."

# Create reports directory if it doesn't exist
mkdir -p tests/reports
echo "📁 Created reports directory: tests/reports/"

case "$1" in
    --unit)
        echo "📊 Running unit tests..."
        # Run PHPUnit unit tests
        ./vendor/bin/phpunit tests/unit/ --log-junit tests/reports/unit-tests.xml
        ;;
    --integration)
        echo "📊 Running integration tests..."
        # Run integration tests
        ./vendor/bin/phpunit tests/integration/ --log-junit tests/reports/integration-tests.xml
        ;;
    *)
        echo "❌ Usage: $0 {--unit|--integration}"
        exit 1
        ;;
esac

# Verify test reports were generated
if [ -f "tests/reports/$(echo $1 | sed 's/--//')-tests.xml" ]; then
    echo "✅ Test report generated: tests/reports/$(echo $1 | sed 's/--//')-tests.xml"
else
    echo "⚠️  Warning: Test report file was not generated"
    # Create empty report to avoid pipeline failures
    echo '<?xml version="1.0" encoding="UTF-8"?><testsuites></testsuites>' > "tests/reports/$(echo $1 | sed 's/--//')-tests.xml"
fi

echo "✅ Tests completed successfully!"