//
//  NavigationFlowTests.swift
//  1LimitUITests
//
//  Specialized tests for navigation flows and transitions 🌈✨
//

import XCTest

class NavigationFlowTests: XCTestCase {

    // MARK: - Test Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Tab Navigation Flow Tests
    
    func testTabNavigationSequence() throws {
        // Given: App launches on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertTrue(homeTab.isSelected, "Should start on Home tab")
        
        // Test 1: Home → Trade → Transactions → Home cycle
        tradeTab.tap()
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be active")
        XCTAssertFalse(homeTab.isSelected, "Home tab should be inactive")
        
        transactionsTab.tap()
        XCTAssertTrue(transactionsTab.isSelected, "Transactions tab should be active")
        XCTAssertFalse(tradeTab.isSelected, "Trade tab should be inactive")
        
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected, "Home tab should be active again")
        XCTAssertFalse(transactionsTab.isSelected, "Transactions tab should be inactive")
        
        // Test 2: Random navigation pattern
        let navigationPattern = [tradeTab, homeTab, transactionsTab, tradeTab, homeTab]
        for tab in navigationPattern {
            tab.tap()
            XCTAssertTrue(tab.isSelected, "Tab should be selected after tap")
        }
    }
    
    func testTabContentPersistence() throws {
        // Given: Navigate to Trade tab and enter data
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // Enter amount in trade form
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        if amountField.exists {
            amountField.tap()
            amountField.clearAndEnterText("2.5")
        }
        
        // Navigate away and back multiple times using coordinate taps to avoid accessibility issues
        let tabBarBounds = app.tabBars.firstMatch
        if tabBarBounds.exists {
            // Tap on the left side of tab bar (Home tab area)
            let homeCoordinate = tabBarBounds.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
            homeCoordinate.tap()
            
            // Wait a moment for navigation
            usleep(500000) // 0.5 seconds
            
            // Tap on the right side of tab bar (Transactions tab area)
            let transactionsCoordinate = tabBarBounds.coordinate(withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
            transactionsCoordinate.tap()
            
            // Wait a moment for navigation
            usleep(500000) // 0.5 seconds
            
            // Tap on the middle of tab bar (Trade tab area)
            let tradeCoordinate = tabBarBounds.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
            tradeCoordinate.tap()
            
            // Wait for view to load
            usleep(500000) // 0.5 seconds
        }
        
        // Then: Content should be preserved
        if amountField.exists {
            XCTAssertEqual(amountField.value as? String, "2.5", "Trade form data should persist")
        }
    }
    
    // MARK: - Modal Navigation Tests
    
    func testWalletCreationModalFlow() throws {
        // Given: App is on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.isSelected, "Should start on Home tab")
        
        // Test Create Wallet flow
        let createWalletButton = app.buttons["Create Wallet"]
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
        createWalletButton.tap()
        
        // Should navigate to backup phrase view
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 5), "Backup phrase view should appear")
        
        // Continue through flow
        let savedPhraseButton = app.buttons["I've Saved My Phrase"]
        if savedPhraseButton.waitForExistence(timeout: 3) {
            savedPhraseButton.tap()
            
            // Should show setup complete view first
            let setupCompleteTitle = app.staticTexts["You're All Set!"]
            XCTAssertTrue(setupCompleteTitle.waitForExistence(timeout: 5), "Setup complete view should appear")
            
            // Tap Load Funds to go to load funds view
            let loadFundsButton = app.buttons["Load Funds"]
            if loadFundsButton.waitForExistence(timeout: 3) {
                loadFundsButton.tap()
                
                // Should show load funds view
                let loadFundsTitle = app.staticTexts["Receive Funds"]
                XCTAssertTrue(loadFundsTitle.waitForExistence(timeout: 5), "Load funds view should appear")
                
                // Navigate back to setup complete
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
            
            // Continue to trade
            let startTradingButton = app.buttons["Start Trading"]
            if startTradingButton.waitForExistence(timeout: 3) {
                startTradingButton.tap()
                
                // Should return to main app with Trade tab selected
                let tradeTab = app.tabBars.buttons["Trade"]
                XCTAssertTrue(tradeTab.waitForExistence(timeout: 5), "Should return to main app")
                XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")
            }
        }
    }
    
    func testImportWalletFlow() throws {
        // Given: App is on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.isSelected, "Should start on Home tab")
        
        // Test Import Wallet flow
        let importWalletButton = app.buttons["Import Wallet"]
        XCTAssertTrue(importWalletButton.exists, "Import Wallet button should exist")
        importWalletButton.tap()
        
        // Should navigate to import view (if implemented)
        // Note: This test assumes import flow exists, adjust based on actual implementation
    }
    
    func testChartModalNavigation() throws {
        // Given: Navigate to Trade tab
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // When: Looking for Chart button (may not exist in current UI)
        let chartButton = app.buttons["Chart"]
        if chartButton.waitForExistence(timeout: 3) {
            chartButton.tap()
            
            // Then: Chart modal should appear
            let chartView = app.staticTexts["Chart"]
            if chartView.waitForExistence(timeout: 5) {
                // Chart view appeared successfully
                
                // Test dismissal methods
                // Method 1: Done button (if exists)
                let doneButton = app.buttons["Done"]
                if doneButton.exists {
                    doneButton.tap()
                } else {
                    // Method 2: Swipe down gesture
                    app.swipeDown()
                }
                
                // Should return to Trade view
                let createOrderTitle = app.staticTexts["Create Limit Order"]
                XCTAssertTrue(createOrderTitle.waitForExistence(timeout: 5), "Should return to Trade view")
            } else {
                // Chart view didn't appear, test failed
                XCTFail("Chart view should appear after tapping Chart button")
            }
        } else {
            // Chart button doesn't exist, skip chart test
            print("Chart button not found - skipping chart functionality test")
        }
    }
    
    func testOrderConfirmationModalFlow() throws {
        // Given: Navigate to Trade tab with valid form data
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // Fill form with valid data
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        if amountField.exists {
            amountField.tap()
            amountField.clearAndEnterText("0.01")
        }
        
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        if limitPriceFields.count > 1 {
            let limitPriceField = limitPriceFields.element(boundBy: 1)
            limitPriceField.tap()
            limitPriceField.clearAndEnterText("0.851")
        }
        
        // When: Creating order
        let createOrderButton = app.buttons["Create Limit Order"]
        XCTAssertTrue(createOrderButton.exists, "Create Order button should exist")
        createOrderButton.tap()
        
        // Then: Confirmation modal should appear
        let confirmTitle = app.staticTexts["Confirm Your Order"]
        XCTAssertTrue(confirmTitle.waitForExistence(timeout: 5), "Order confirmation should appear")
        
        // Test cancellation - use first matching cancel button
        let cancelButtons = app.buttons.matching(identifier: "Cancel")
        XCTAssertTrue(cancelButtons.count > 0, "Cancel button should exist")
        cancelButtons.firstMatch.tap()
        
        // Should return to Trade view
        let createOrderTitle = app.staticTexts["Create Limit Order"]
        XCTAssertTrue(createOrderTitle.waitForExistence(timeout: 5), "Should return to Trade view")
    }
    
    // MARK: - Deep Navigation Tests
    
    func testNavigationStackBehavior() throws {
        // Test that navigation maintains proper stack behavior
        
        // Given: Start wallet creation flow
        let createWalletButton = app.buttons["Create Wallet"]
        createWalletButton.tap()
        
        // Navigate deep into flow
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        if backupPhraseTitle.waitForExistence(timeout: 3) {
            
            let savedPhraseButton = app.buttons["I've Saved My Phrase"]
            if savedPhraseButton.waitForExistence(timeout: 3) {
                savedPhraseButton.tap()
                
                // Test back navigation (if available)
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists && backButton.label.contains("Back") {
                    backButton.tap()
                    
                    // Should return to previous view
                    XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Should return to backup phrase")
                }
            }
        }
    }
    
    func testNavigationInterruption() throws {
        // Test navigation behavior when interrupted by tab switching
        
        // Given: Start wallet creation
        let createWalletButton = app.buttons["Create Wallet"]
        createWalletButton.tap()
        
        // When: Switch tabs during modal navigation
        let tradeTab = app.tabBars.buttons["Trade"]
        if tradeTab.exists && tradeTab.isHittable {
            tradeTab.tap()
            
            // Then: Should handle interruption gracefully
            XCTAssertTrue(app.state == .runningForeground, "App should handle navigation interruption")
            
            // And: Tab should switch successfully
            XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")
        }
    }
    
    // MARK: - Transition Animation Tests
    
    
    // MARK: - Error Handling Tests
    
    func testNavigationErrorRecovery() throws {
        // Test app recovery from navigation errors
        
        // Simulate rapid navigation that might cause issues
        let tabs = [
            app.tabBars.buttons["Home"],
            app.tabBars.buttons["Trade"],
            app.tabBars.buttons["Transactions"]
        ]
        
        // Rapid tab switching
        for _ in 0..<10 {
            for tab in tabs {
                tab.tap()
            }
        }
        
        // App should still be responsive
        XCTAssertTrue(app.state == .runningForeground, "App should recover from rapid navigation")
        
        // Final state should be valid
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected, "App should return to valid state")
    }
    
    func testMemoryPressureDuringNavigation() throws {
        // Test navigation under memory pressure (simulate by opening many modals)
        
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // Open and close chart multiple times using safe tapping
        for _ in 0..<5 {
            let chartButton = app.buttons["Chart"]
            if chartButton.waitForExistence(timeout: 2) {
                // Use coordinate-based tap to avoid accessibility scroll issues
                let buttonCenter = chartButton.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                buttonCenter.tap()
                
                // Wait briefly for modal to appear
                usleep(300000) // 0.3 seconds
                
                // Dismiss with swipe down
                app.swipeDown()
                
                // Wait briefly for modal to dismiss
                usleep(300000) // 0.3 seconds
            } else {
                // Chart button not found, skip this iteration
                print("Chart button not found in iteration, skipping")
                break
            }
        }
        
        // App should still be responsive
        XCTAssertTrue(app.state == .runningForeground, "App should handle memory pressure during navigation")
    }
}


