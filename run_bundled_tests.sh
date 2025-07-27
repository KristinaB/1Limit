#!/bin/bash

# Script to run all bundled tests in a single session for maximum speed ⚡️
# Usage: ./run_bundled_tests.sh

echo "🚀⚡️ Running Bundled UI Tests for Maximum Speed! 🦄✨"
echo "============================================="

echo "📱 Running all bundled test scenarios in a single app session..."

# Run all bundled tests
xcodebuild test \
    -scheme 1Limit \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:1LimitUITests/BundledUITests \
    2>&1 | xcpretty --test --color

echo ""
echo "✨ Bundled tests completed! 🌸🎯"
echo "💡 This approach runs multiple test scenarios in one app session"
echo "⚡️ Much faster than individual test runs! 🚀"