//
//  WalletResetAndTabVisibilityUITests.swift
//  1LimitUITests
//
//  Comprehensive tests for wallet reset flow and tab visibility behavior 🔄🎯
//

import XCTest

class WalletResetAndTabVisibilityUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Bundle Test: Wallet Reset and Tab Visibility Flow
    
    func testWalletResetAndTabVisibilityBundle() throws {
        print("🔄 Starting Wallet Reset & Tab Visibility Bundle Tests...")
        
        // Test 1: Initial no-wallet state with Home tab only
        print("🏠 Testing initial no-wallet state...")
        testInitialNoWalletState()
        
        // Test 2: Load test wallet and verify tabs appear
        print("👛 Testing wallet load and tab appearance...")
        testWalletLoadAndTabAppearance()
        
        // Test 3: Test debug reset functionality
        print("🛠️ Testing debug reset flow...")
        testDebugResetFlow()
        
        // Test 4: Verify tabs disappear after reset
        print("🚫 Testing tab disappearance after reset...")
        testTabDisappearanceAfterReset()
        
        // Test 5: Test wallet reload cycle
        print("🔄 Testing wallet reload cycle...")
        testWalletReloadCycle()
        
        print("✅ Wallet Reset & Tab Visibility Bundle Tests Completed!")
    }
    
    // MARK: - Individual Test Methods
    
    private func testInitialNoWalletState() {
        // Ensure we're on Home tab initially
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist")
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected by default")
        
        // Verify Trade and Transactions tabs don't exist initially
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertFalse(tradeTab.exists, "Trade tab should not exist without wallet")
        XCTAssertFalse(transactionsTab.exists, "Transactions tab should not exist without wallet")
        
        // Verify no-wallet content is displayed
        let noWalletText = app.staticTexts["NO WALLET"]
        let createNewWalletButton = app.buttons["Create New Wallet"]
        let useTestWalletButton = app.buttons["Use Test Wallet"]
        
        XCTAssertTrue(noWalletText.exists, "NO WALLET text should be visible")
        XCTAssertTrue(createNewWalletButton.exists, "Create New Wallet button should exist")
        XCTAssertTrue(useTestWalletButton.exists, "Use Test Wallet button should exist")
    }
    
    private func testWalletLoadAndTabAppearance() {
        // Load test wallet
        let useTestWalletButton = app.buttons["Use Test Wallet"]
        XCTAssertTrue(useTestWalletButton.exists, "Use Test Wallet button should exist")
        
        useTestWalletButton.tap()
        usleep(1500000) // 1.5 seconds for wallet to load
        
        // Verify Trade and Transactions tabs now exist
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertTrue(tradeTab.exists, "Trade tab should appear after wallet load")
        XCTAssertTrue(transactionsTab.exists, "Transactions tab should appear after wallet load")
        
        // Verify wallet content is displayed
        let activeWalletText = app.staticTexts["Active Wallet"]
        let addButton = app.buttons["Add"]
        let sendButton = app.buttons["Send"]
        
        XCTAssertTrue(activeWalletText.exists, "Active Wallet text should be visible")
        XCTAssertTrue(addButton.exists, "Add button should exist with wallet loaded")
        XCTAssertTrue(sendButton.exists, "Send button should exist with wallet loaded")
        
        // Test tab navigation works
        tradeTab.tap()
        usleep(500000)
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selectable")
        
        transactionsTab.tap()
        usleep(500000)
        XCTAssertTrue(transactionsTab.isSelected, "Transactions tab should be selectable")
        
        // Return to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        usleep(500000)
    }
    
    private func testDebugResetFlow() {
        // Open debug view
        let debugButton = app.buttons["Debug"]
        XCTAssertTrue(debugButton.exists, "Debug button should exist")
        
        debugButton.tap()
        usleep(1000000) // 1 second for debug view to open
        
        // Find and tap reset button
        let resetButton = app.buttons["Reset Application"]
        XCTAssertTrue(resetButton.exists, "Reset Application button should exist in debug view")
        
        resetButton.tap()
        usleep(500000)
        
        // Handle reset confirmation alert
        let resetAlert = app.alerts["Reset Application"]
        if resetAlert.exists {
            let resetConfirmButton = resetAlert.buttons["Reset"]
            XCTAssertTrue(resetConfirmButton.exists, "Reset confirmation button should exist")
            
            resetConfirmButton.tap()
            usleep(2000000) // 2 seconds for reset to complete and view to dismiss
        }
        
        // Verify we're back on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should exist after reset")
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected after reset")
    }
    
    private func testTabDisappearanceAfterReset() {
        // Verify Trade and Transactions tabs are gone after reset
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertFalse(tradeTab.exists, "Trade tab should not exist after wallet reset")
        XCTAssertFalse(transactionsTab.exists, "Transactions tab should not exist after wallet reset")
        
        // Verify no-wallet state is restored
        let noWalletText = app.staticTexts["NO WALLET"]
        let createNewWalletButton = app.buttons["Create New Wallet"]
        let useTestWalletButton = app.buttons["Use Test Wallet"]
        
        XCTAssertTrue(noWalletText.exists, "NO WALLET text should be visible after reset")
        XCTAssertTrue(createNewWalletButton.exists, "Create New Wallet button should exist after reset")
        XCTAssertTrue(useTestWalletButton.exists, "Use Test Wallet button should exist after reset")
        
        // Verify wallet-specific content is gone
        let activeWalletText = app.staticTexts["Active Wallet"]
        let addButton = app.buttons["Add"]
        let sendButton = app.buttons["Send"]
        
        XCTAssertFalse(activeWalletText.exists, "Active Wallet text should not exist after reset")
        XCTAssertFalse(addButton.exists, "Add button should not exist after reset")
        XCTAssertFalse(sendButton.exists, "Send button should not exist after reset")
    }
    
    private func testWalletReloadCycle() {
        // Test loading wallet again after reset
        let useTestWalletButton = app.buttons["Use Test Wallet"]
        XCTAssertTrue(useTestWalletButton.exists, "Use Test Wallet button should be available for reload")
        
        useTestWalletButton.tap()
        usleep(1500000) // 1.5 seconds for wallet to load
        
        // Verify tabs reappear
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertTrue(tradeTab.exists, "Trade tab should reappear after wallet reload")
        XCTAssertTrue(transactionsTab.exists, "Transactions tab should reappear after wallet reload")
        
        // Verify wallet content is restored
        let activeWalletText = app.staticTexts["Active Wallet"]
        XCTAssertTrue(activeWalletText.exists, "Active Wallet text should reappear after reload")
        
        // Test quick tab switching to ensure stability
        tradeTab.tap()
        usleep(300000)
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selectable after reload")
        
        transactionsTab.tap()
        usleep(300000)
        XCTAssertTrue(transactionsTab.isSelected, "Transactions tab should be selectable after reload")
        
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        usleep(300000)
        XCTAssertTrue(homeTab.isSelected, "Home tab should remain functional after reload")
    }
    
    // MARK: - Helper Methods
    
    private func navigateToHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
            usleep(500000)
        }
    }
    
    private func waitForWalletLoad() {
        // Wait for wallet loading to complete
        usleep(1500000) // 1.5 seconds
    }
    
    private func dismissAnyAlerts() {
        // Dismiss any system alerts that might interfere
        if app.alerts.count > 0 {
            let alert = app.alerts.firstMatch
            if alert.buttons["OK"].exists {
                alert.buttons["OK"].tap()
            } else if alert.buttons["Allow"].exists {
                alert.buttons["Allow"].tap()
            } else if alert.buttons["Dismiss"].exists {
                alert.buttons["Dismiss"].tap()
            }
            usleep(500000)
        }
    }
}

// MARK: - Extended Tab Visibility Tests

extension WalletResetAndTabVisibilityUITests {
    
    func testTabVisibilityStatesBundle() throws {
        print("👁️ Starting Tab Visibility States Bundle Tests...")
        
        // Test 1: No wallet state tab count
        print("🔢 Testing no-wallet tab count...")
        testNoWalletTabCount()
        
        // Test 2: With wallet tab count
        print("➕ Testing with-wallet tab count...")
        testWithWalletTabCount()
        
        // Test 3: Tab accessibility during wallet transitions
        print("♿ Testing tab accessibility during transitions...")
        testTabAccessibilityDuringTransitions()
        
        print("✅ Tab Visibility States Bundle Tests Completed!")
    }
    
    private func testNoWalletTabCount() {
        navigateToHomeTab()
        
        // Count visible tabs in no-wallet state
        let allTabs = app.tabBars.buttons.allElementsBoundByIndex
        var visibleTabCount = 0
        
        for tab in allTabs {
            if tab.exists && tab.isHittable {
                visibleTabCount += 1
                print("📋 Visible tab: \(tab.label)")
            }
        }
        
        XCTAssertEqual(visibleTabCount, 1, "Should have exactly 1 visible tab (Home) in no-wallet state")
        
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.exists, "Home tab should be the only visible tab")
    }
    
    private func testWithWalletTabCount() {
        // Load test wallet
        let useTestWalletButton = app.buttons["Use Test Wallet"]
        if useTestWalletButton.exists {
            useTestWalletButton.tap()
            waitForWalletLoad()
        }
        
        // Count visible tabs with wallet loaded
        let allTabs = app.tabBars.buttons.allElementsBoundByIndex
        var visibleTabCount = 0
        var tabLabels: [String] = []
        
        for tab in allTabs {
            if tab.exists && tab.isHittable {
                visibleTabCount += 1
                tabLabels.append(tab.label)
                print("📋 Visible tab: \(tab.label)")
            }
        }
        
        XCTAssertEqual(visibleTabCount, 3, "Should have exactly 3 visible tabs with wallet loaded")
        
        let expectedTabs = ["Home", "Trade", "Transactions"]
        for expectedTab in expectedTabs {
            XCTAssertTrue(tabLabels.contains(expectedTab), "Should contain \(expectedTab) tab with wallet loaded")
        }
    }
    
    private func testTabAccessibilityDuringTransitions() {
        // Start with no wallet
        navigateToHomeTab()
        
        // Load wallet and immediately test tab accessibility
        let useTestWalletButton = app.buttons["Use Test Wallet"]
        if useTestWalletButton.exists {
            useTestWalletButton.tap()
            
            // Test tabs during loading period
            usleep(500000) // 0.5 seconds - during loading
            
            let homeTab = app.tabBars.buttons["Home"]
            XCTAssertTrue(homeTab.exists, "Home tab should remain accessible during wallet loading")
            
            // Wait for full load
            waitForWalletLoad()
            
            // Test all tabs are now accessible
            let tradeTab = app.tabBars.buttons["Trade"]
            let transactionsTab = app.tabBars.buttons["Transactions"]
            
            XCTAssertTrue(tradeTab.exists && tradeTab.isHittable, "Trade tab should be accessible after load")
            XCTAssertTrue(transactionsTab.exists && transactionsTab.isHittable, "Transactions tab should be accessible after load")
            
            // Test rapid tab switching works
            tradeTab.tap()
            usleep(200000)
            homeTab.tap()
            usleep(200000)
            transactionsTab.tap()
            usleep(200000)
            homeTab.tap()
            
            XCTAssertTrue(homeTab.isSelected, "Should successfully return to Home after rapid switching")
        }
    }
}