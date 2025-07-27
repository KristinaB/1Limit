#!/bin/bash

# Script to run a single test by name with optional test suite parameter
# Usage: ./run_single_test.sh testName [testSuite]
# Example: ./run_single_test.sh testWalletCreationFlowNavigation
# Example: ./run_single_test.sh testAmountFieldInteraction TradeFormInteractionTests

if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide a test name as argument"
    echo "Usage: $0 testName [testSuite]"
    echo "Example: $0 testWalletCreationFlowNavigation"
    echo "Example: $0 testAmountFieldInteraction TradeFormInteractionTests"
    echo ""
    echo "Available test suites:"
    echo "  - BundledUITests (FAST - recommended)"
    echo "  - TradeViewUnitTests"
    echo "  - TransactionIntegrationTests"
    exit 1
fi

TEST_NAME=$1
TEST_SUITE=$2

echo "🦄💜 Running single test: $TEST_NAME ✨"
if [ -n "$TEST_SUITE" ]; then
    echo "🎯 Target test suite: $TEST_SUITE"
fi
echo "================================"

# Function to run test in specific suite
run_test_in_suite() {
    local suite=$1
    local target_path=""
    local suite_name=""

    case $suite in
        "BundledUITests")
            target_path="1LimitUITests/BundledUITests"
            suite_name="Bundled UI Tests (Fast)"
            ;;
        "TradeViewUnitTests")
            target_path="1LimitTests/TradeViewUnitTests"
            suite_name="Trade View Unit Tests"
            ;;
        "TransactionIntegrationTests")
            target_path="1LimitTests/TransactionIntegrationTests"
            suite_name="Transaction Integration Tests"
            ;;
        *)
            echo "❌ Unknown test suite: $suite"
            return 1
            ;;
    esac

    echo "🔍 Running test in $suite_name..."
    RESULT=$(xcodebuild test \
        -scheme 1Limit \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -only-testing:$target_path/$TEST_NAME \
        2>&1 | xcpretty --test --color || true)

    if echo "$RESULT" | grep -q "Executed 1 test"; then
        echo "$RESULT"
        echo "✅ Test completed in $suite_name"
        return 0
    else
        echo "❌ Test '$TEST_NAME' not found in $suite_name"
        return 1
    fi
}

# run
if [ -n "$TEST_SUITE" ]; then
    if run_test_in_suite "$TEST_SUITE"; then
        exit 0
    else
        exit 1
    fi
fi
