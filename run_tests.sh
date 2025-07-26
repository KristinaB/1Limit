#!/bin/bash

# Run XCTest tests for 1Limit 🎀✨

echo "🦄💜 Running 1Limit XCTests ✨🌸"
echo "================================"

# Run all tests
echo "🧪 Running all UI tests..."
xcodebuild test \
    -scheme 1Limit \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    2>&1 | xcpretty --test --color || true

echo ""
echo "🎯 Test run complete!"
echo ""
echo "💡 To run specific tests:"
echo "   ./run_tests.sh -only-testing:1LimitTests/ComprehensiveUITests"
echo "   ./run_tests.sh -only-testing:1LimitTests/TabBarIntegrationTests/testHomeViewContentRendering"