#!/bin/bash

# Run XCTest tests for 1Limit 🎀✨

echo "🦄💜 Running 1Limit XCTests ✨🌸"
echo "================================"
echo ""

# Check if documentation mode is requested
if [ "$1" = "--docs" ] || [ "$1" = "-d" ]; then
    echo "📚 Documentation Mode: Generating detailed test report..."
    echo ""
    
    # Clean previous results
    rm -rf test_results.xcresult test_output.log 2>/dev/null || true
    
    # Run tests with detailed output and capture results
    xcodebuild test \
        -scheme 1Limit \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -resultBundlePath test_results.xcresult \
        2>&1 | tee test_output.log | xcpretty --test --color || true
    
    # Generate documentation-style report
    echo ""
    echo "======================================"
    echo "📋 1LIMIT TEST SUITE DOCUMENTATION"
    echo "======================================"
    echo ""
    echo "Generated on: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Test Framework: XCTest"
    echo "Platform: iOS Simulator (iPhone 16)"
    echo ""
    
    # Parse test results from xcpretty output
    echo "## 🧪 TEST RESULTS SUMMARY"
    echo "------------------------"
    
    # Extract test counts from log
    TOTAL_TESTS=$(grep -E "Executed [0-9]+ test" test_output.log | grep -oE "[0-9]+" | head -1 2>/dev/null || echo "0")
    PASSED_TESTS=$(grep -c "✓" test_output.log 2>/dev/null || echo "0")
    FAILED_TESTS=$(grep -c "✗" test_output.log 2>/dev/null || echo "0")
    
    echo "Total Tests: $TOTAL_TESTS"
    echo "✅ Passed: $PASSED_TESTS"
    echo "❌ Failed: $FAILED_TESTS"
    echo ""
    
    echo "## 📊 DETAILED TEST RESULTS"
    echo "-------------------------"
    echo ""
    
    # Parse and format test results
    echo "### ComprehensiveUITests"
    grep -E "(ComprehensiveUITests\.).*((passed)|(failed))" test_output.log | \
        sed 's/.*ComprehensiveUITests\./  - /' | \
        sed 's/ passed.*/ ✅/' | \
        sed 's/ failed.*/ ❌/' || echo "  No tests found"
    echo ""
    
    echo "### NavigationFlowTests"
    grep -E "(NavigationFlowTests\.).*((passed)|(failed))" test_output.log | \
        sed 's/.*NavigationFlowTests\./  - /' | \
        sed 's/ passed.*/ ✅/' | \
        sed 's/ failed.*/ ❌/' || echo "  No tests found"
    echo ""
    
    echo "### TabBarIntegrationTests"
    grep -E "(TabBarIntegrationTests\.).*((passed)|(failed))" test_output.log | \
        sed 's/.*TabBarIntegrationTests\./  - /' | \
        sed 's/ passed.*/ ✅/' | \
        sed 's/ failed.*/ ❌/' || echo "  No tests found"
    echo ""
    
    echo "### TradeFormInteractionTests"
    grep -E "(TradeFormInteractionTests\.).*((passed)|(failed))" test_output.log | \
        sed 's/.*TradeFormInteractionTests\./  - /' | \
        sed 's/ passed.*/ ✅/' | \
        sed 's/ failed.*/ ❌/' || echo "  No tests found"
    echo ""
    
    echo "### TradeViewUnitTests"
    grep -E "(TradeViewUnitTests\.).*((passed)|(failed))" test_output.log | \
        sed 's/.*TradeViewUnitTests\./  - /' | \
        sed 's/ passed.*/ ✅/' | \
        sed 's/ failed.*/ ❌/' || echo "  No tests found"
    echo ""
    
    # Show any failures in detail
    if [ "$FAILED_TESTS" -gt 0 ] 2>/dev/null; then
        echo "## ❌ FAILED TEST DETAILS"
        echo "------------------------"
        grep -A 5 "✗" test_output.log || echo "No failure details available"
        echo ""
    fi
    
    # Performance metrics if available
    echo "## ⚡ PERFORMANCE METRICS"
    echo "----------------------"
    grep -E "measured.*average" test_output.log | sed 's/^/  /' || echo "  No performance tests found"
    echo ""
    
    # Test duration
    echo "## ⏱️  EXECUTION TIME"
    echo "------------------"
    grep -E "Test Suite.*seconds" test_output.log | tail -1 || echo "  Duration not available"
    echo ""
    
    echo "======================================"
    echo "📄 Full log saved to: test_output.log"
    echo "📦 Result bundle: test_results.xcresult/"
    echo "======================================"
    
else
    # Normal mode - run both unit and UI tests
    echo "🔬 Running Unit Tests..."
    xcodebuild test \
        -scheme 1Limit \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -only-testing:1LimitTests \
        2>&1 | xcpretty --test --color || true
    
    echo ""
    echo "📱 Running UI Tests..."
    xcodebuild test \
        -scheme 1Limit \
        -destination 'platform=iOS Simulator,name=iPhone 16' \
        -only-testing:1LimitUITests \
        2>&1 | xcpretty --test --color || true
    
    echo ""
    echo "🎯 Test run complete!"
    echo ""
    echo "💡 To run specific test suites:"
    echo "   Unit Tests: -only-testing:1LimitTests"
    echo "   UI Tests: -only-testing:1LimitUITests"
    echo "   Specific: -only-testing:1LimitUITests/ComprehensiveUITests"
    echo ""
    echo "📚 For detailed documentation-style output:"
    echo "   ./run_tests.sh --docs"
fi