#!/bin/bash

# Script to run a single test by name
# Usage: ./run_single_test.sh testName
# Example: ./run_single_test.sh testWalletCreationFlowNavigation

if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide a test name as argument"
    echo "Usage: $0 testName"
    echo "Example: $0 testWalletCreationFlowNavigation"
    exit 1
fi

TEST_NAME=$1

echo "🦄💜 Running single test: $TEST_NAME ✨"
echo "================================"

# Try to find the test in both unit and UI test targets
echo "🔍 Attempting to run test..."

# First try UI tests
echo "📱 Trying UI Tests..."
UI_RESULT=$(xcodebuild test \
    -scheme 1Limit \
    -destination 'platform=iOS Simulator,name=iPhone 16' \
    -only-testing:1LimitUITests/ComprehensiveUITests/$TEST_NAME \
    2>&1 | xcpretty --test --color || true)

if echo "$UI_RESULT" | grep -q "Executed 1 test"; then
    echo "$UI_RESULT"
    echo "✅ UI Test completed"
else
    # Try unit tests
    echo "🔬 Trying Unit Tests..."
    UNIT_RESULT=$(xcodebuild test \
        -scheme 1Limit \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -only-testing:1LimitTests/TradeViewUnitTests/$TEST_NAME \
        2>&1 | xcpretty --test --color || true)
    
    if echo "$UNIT_RESULT" | grep -q "Executed 1 test"; then
        echo "$UNIT_RESULT"
        echo "✅ Unit Test completed"
    else
        echo "❌ Test '$TEST_NAME' not found in any test target"
    echo ""
    echo "Available UI tests:"
    echo "  - testCompleteAppNavigationFlow"
    echo "  - testWalletCreationFlowNavigation"
    echo "  - testTradeViewFormInteractions"
    echo "  - testOrderPlacementFlow"
    echo "  - testTransactionsViewFunctionality"
    echo "  - testDebugViewAccess"
    echo "  - testFormValidation"
    echo "  - testAppStatePreservation"
    echo ""
    echo "Available Unit tests:"
    echo "  - testOrderCreationWithValidInputs"
    echo "  - testOrderPlacementValidInput"
    echo "  - testMockTransactionSubmitter"
    echo "  - testOrderEncoding"
    echo "  - testEIP712Signing"
        exit 1
    fi
fi

echo ""
echo "✨ Test run completed! 🌸"