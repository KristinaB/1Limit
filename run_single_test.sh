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
    echo "  - ComprehensiveUITests"
    echo "  - NavigationFlowTests"
    echo "  - TabBarIntegrationTests"
    echo "  - TradeFormInteractionTests"
    echo "  - TradeViewUnitTests"
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
        "ComprehensiveUITests")
            target_path="1LimitUITests/ComprehensiveUITests"
            suite_name="Comprehensive UI Tests"
            ;;
        "NavigationFlowTests")
            target_path="1LimitUITests/NavigationFlowTests"
            suite_name="Navigation Flow Tests"
            ;;
        "TabBarIntegrationTests")
            target_path="1LimitUITests/TabBarIntegrationTests"
            suite_name="TabBar Integration Tests"
            ;;
        "TradeFormInteractionTests")
            target_path="1LimitUITests/TradeFormInteractionTests"
            suite_name="Trade Form Interaction Tests"
            ;;
        "TradeViewUnitTests")
            target_path="1LimitTests/TradeViewUnitTests"
            suite_name="Trade View Unit Tests"
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

# If test suite is specified, run directly in that suite
if [ -n "$TEST_SUITE" ]; then
    if run_test_in_suite "$TEST_SUITE"; then
        exit 0
    else
        exit 1
    fi
fi

# Otherwise, try all suites in order
echo "🔍 Searching for test in all suites..."

SUITES=("ComprehensiveUITests" "NavigationFlowTests" "TabBarIntegrationTests" "TradeFormInteractionTests" "TradeViewUnitTests")

for suite in "${SUITES[@]}"; do
    if run_test_in_suite "$suite"; then
        exit 0
    fi
done

# Test not found in any suite
echo ""
echo "❌ Test '$TEST_NAME' not found in any test suite"
echo ""
echo "Available tests by suite:"
echo ""
echo "ComprehensiveUITests:"
echo "  - testCompleteAppNavigationFlow"
echo "  - testWalletCreationFlowNavigation"
echo "  - testTradeViewFormInteractions"
echo "  - testOrderPlacementFlow"
echo "  - testTransactionsViewFunctionality"
echo "  - testDebugViewAccess"
echo "  - testFormValidation"
echo "  - testAppStatePreservation"
echo ""
echo "NavigationFlowTests:"
echo "  - testTabNavigationSequence"
echo "  - testTabContentPersistence"
echo "  - testWalletCreationModalFlow"
echo "  - testChartModalNavigation"
echo "  - testOrderConfirmationModalFlow"
echo "  - testNavigationStackBehavior"
echo "  - testNavigationInterruption"
echo "  - testNavigationErrorRecovery"
echo "  - testMemoryPressureDuringNavigation"
echo ""
echo "TabBarIntegrationTests:"
echo "  - testTabBarRendersCorrectly"
echo "  - testTabBarNavigationFlow"
echo "  - testTradeViewContentRendering"
echo "  - testHomeViewContentRendering"
echo "  - testTransactionsViewContentRendering"
echo ""
echo "TradeFormInteractionTests:"
echo "  - testAmountFieldInteraction"
echo "  - testLimitPriceFieldInteraction"
echo "  - testTokenSelectionInteraction"
echo "  - testSwapTokensInteraction"
echo "  - testFormValidationWithEmptyFields"
echo "  - testFormValidationWithInvalidValues"
echo "  - testFormValidationWithZeroValues"
echo "  - testFormValidationWithNegativeValues"
echo "  - testOrderPreviewGeneration"
echo "  - testOrderPreviewUpdates"
echo "  - testChartButtonInteraction"
echo "  - testOrderCreationFlow"
echo "  - testDefaultAmountValue"
echo "  - testAutoLimitPriceCalculation"
echo ""
echo "TradeViewUnitTests:"
echo "  - testOrderCreationWithValidInputs"
echo "  - testOrderPlacementValidInput"
echo "  - testMockTransactionSubmitter"
echo "  - testOrderEncoding"
echo "  - testEIP712Signing"

exit 1