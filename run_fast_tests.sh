#!/bin/bash

# Fast test runner that groups tests by functionality to minimize app restarts ⚡️
# Usage: ./run_fast_tests.sh [bundle_name]
# Available bundles: navigation, trade, wallet, content, order, all

if [ $# -eq 0 ]; then
    echo "🚀⚡️ Fast Test Runner - Bundled Tests! 🦄✨"
    echo "Usage: $0 [bundle_name]"
    echo ""
    echo "Available test bundles:"
    echo "  navigation  - Tab navigation and content persistence"
    echo "  trade       - Trade form interactions and validation"
    echo "  wallet      - Wallet creation and setup flows"  
    echo "  content     - Content verification across all views"
    echo "  order       - Order creation and confirmation flows"
    echo "  walletmgmt  - Wallet management, switching, and Load Funds"
    echo "  transactions- Transaction list features and detail views"
    echo "  all         - Run all bundled tests (recommended)"
    echo ""
    echo "💡 Each bundle runs multiple related tests in a single app session"
    echo "⚡️ Much faster than running individual tests!"
    exit 1
fi

BUNDLE_NAME=$1

echo "🚀⚡️ Running Fast Test Bundle: $BUNDLE_NAME 🦄✨"
echo "============================================="

case $BUNDLE_NAME in
    "navigation")
        echo "🧭 Running Navigation & TabBar Bundle..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/BundledUITests/testNavigationAndTabBarBundle \
            2>&1 | xcpretty --test --color
        ;;
    "trade")
        echo "📝 Running Trade Form Interactions Bundle..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/BundledUITests/testTradeFormInteractionsBundle \
            2>&1 | xcpretty --test --color
        ;;
    "wallet")
        echo "👛 Running Wallet Flow Bundle..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/BundledUITests/testWalletFlowBundle \
            2>&1 | xcpretty --test --color
        ;;
    "content")
        echo "🔍 Running Content Verification Bundle..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/BundledUITests/testContentVerificationBundle \
            2>&1 | xcpretty --test --color
        ;;
    "order")
        echo "🎯 Running Order Creation Bundle..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/BundledUITests/testOrderCreationBundle \
            2>&1 | xcpretty --test --color
        ;;
    "walletmgmt")
        echo "💳 Running Wallet Management Tests..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/WalletManagementUITests/testWalletManagementBundle \
            2>&1 | xcpretty --test --color
        ;;
    "transactions")
        echo "📊 Running Transaction Features Tests..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/TransactionFeaturesUITests \
            2>&1 | xcpretty --test --color
        ;;
    "all")
        echo "🌟 Running ALL Bundled Tests..."
        xcodebuild test \
            -scheme 1Limit \
            -destination 'platform=iOS Simulator,name=iPhone 16' \
            -only-testing:1LimitUITests/BundledUITests \
            -only-testing:1LimitUITests/WalletManagementUITests \
            -only-testing:1LimitUITests/TransactionFeaturesUITests \
            2>&1 | xcpretty --test --color
        ;;
    *)
        echo "❌ Unknown bundle: $BUNDLE_NAME"
        echo "Available bundles: navigation, trade, wallet, content, order, walletmgmt, transactions, all"
        exit 1
        ;;
esac

echo ""
echo "✨ Bundle test completed! 🌸🎯"
echo "💡 This approach runs multiple test scenarios in one app session"
echo "⚡️ Much faster than individual test runs! 🚀"