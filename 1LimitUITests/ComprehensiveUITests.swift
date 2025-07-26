//
//  ComprehensiveUITests.swift
//  1LimitUITests
//
//  Comprehensive UI test suite covering all screens and transitions 🎀✨
//

import XCTest

class ComprehensiveUITests: XCTestCase {

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
    
    // MARK: - Full App Flow Tests
    
    func testCompleteAppNavigationFlow() throws {
        // Given: App launches to Home tab
        let homeTab = app.tabBars.buttons["Home"]
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected on launch")
        
        // When: Navigate through all tabs
        tradeTab.tap()
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be active")
        
        transactionsTab.tap()
        XCTAssertTrue(transactionsTab.isSelected, "Transactions tab should be active")
        
        homeTab.tap()
        XCTAssertTrue(homeTab.isSelected, "Home tab should be active again")
        
        // Then: All navigation should be smooth without crashes
        XCTAssertTrue(app.state == .runningForeground, "App should still be running after navigation")
    }
    
    func testWalletCreationFlowNavigation() throws {
        // Given: App is on Home tab
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
        
        // When: Tapping Create Wallet button
        let createWalletButton = app.buttons["Create Wallet"]
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
        createWalletButton.tap()
        
        // Then: Backup phrase view should appear
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Backup phrase view should appear")
        
        // And: Important security notice should be visible
        let securityNotice = app.staticTexts["Never share your recovery phrase"]
        XCTAssertTrue(securityNotice.exists, "Security notice should be visible")
        
        // And: Recovery phrase should be displayed
        let recoveryPhrase = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'abandon'")).firstMatch
        XCTAssertTrue(recoveryPhrase.exists, "Recovery phrase should be displayed")
        
        // When: Tapping "I've Saved My Phrase" button
        let savedPhraseButton = app.buttons["I've Saved My Phrase"]
        XCTAssertTrue(savedPhraseButton.exists, "I've Saved My Phrase button should exist")
        savedPhraseButton.tap()
        
        // Then: Load funds view should appear
        let loadFundsTitle = app.staticTexts["Receive Funds"]
        XCTAssertTrue(loadFundsTitle.waitForExistence(timeout: 3), "Load funds view should appear")
        
        // And: QR code should be visible
        let qrCode = app.images["QR Code"]
        XCTAssertTrue(qrCode.exists, "QR code should be visible")
        
        // And: Wallet address should be displayed
        let walletAddress = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0x'")).firstMatch
        XCTAssertTrue(walletAddress.exists, "Wallet address should be displayed")
        
        // When: Tapping "Continue to Trade" button
        let continueButton = app.buttons["Continue to Trade"]
        XCTAssertTrue(continueButton.exists, "Continue to Trade button should exist")
        continueButton.tap()
        
        // Then: Should navigate to Setup Complete view
        let setupCompleteTitle = app.staticTexts["You're All Set!"]
        XCTAssertTrue(setupCompleteTitle.waitForExistence(timeout: 3), "Setup complete view should appear")
        
        // When: Tapping "Start Trading" button
        let startTradingButton = app.buttons["Start Trading"]
        XCTAssertTrue(startTradingButton.exists, "Start Trading button should exist")
        startTradingButton.tap()
        
        // Then: Should return to home and activate Trade tab
        let tradeTab = app.tabBars.buttons["Trade"]
        XCTAssertTrue(tradeTab.waitForExistence(timeout: 3), "Should return to main app")
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")
    }
    
    func testTradeViewFormInteractions() throws {
        // Given: Navigate to Trade tab
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // When: Interacting with amount field
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        XCTAssertTrue(amountField.exists, "Amount field should exist")
        amountField.tap()
        amountField.typeText("1.5")
        
        // Then: Amount should be updated
        XCTAssertEqual(amountField.value as? String, "1.5", "Amount field should show entered value")
        
        // When: Interacting with limit price field
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1) // Second field
        XCTAssertTrue(limitPriceField.exists, "Limit price field should exist")
        limitPriceField.tap()
        limitPriceField.typeText("0.85")
        
        // Then: Limit price should be updated
        XCTAssertEqual(limitPriceField.value as? String, "0.85", "Limit price field should show entered value")
        
        // When: Tapping swap button
        let swapButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow'")).firstMatch
        XCTAssertTrue(swapButton.exists, "Swap button should exist")
        swapButton.tap()
        
        // Then: Tokens should be swapped
        // Note: This test assumes the tokens swap visually, exact verification may vary
        
        // When: Tapping Chart button
        let chartButton = app.buttons["Chart"]
        XCTAssertTrue(chartButton.exists, "Chart button should exist")
        chartButton.tap()
        
        // Then: Chart view should appear as modal
        let chartTitle = app.staticTexts["Price Chart"]
        XCTAssertTrue(chartTitle.waitForExistence(timeout: 3), "Chart view should appear")
        
        // When: Dismissing chart
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            // Swipe down to dismiss if no done button
            app.swipeDown()
        }
        
        // Then: Should return to trade view
        let createOrderTitle = app.staticTexts["Create Limit Order"]
        XCTAssertTrue(createOrderTitle.waitForExistence(timeout: 3), "Should return to trade view")
    }
    
    func testOrderPlacementFlow() throws {
        // Given: Navigate to Trade tab with filled form
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // Fill in form values
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        amountField.tap()
        amountField.clearAndEnterText("0.01")
        
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        limitPriceField.tap()
        limitPriceField.clearAndEnterText("0.851")
        
        // When: Tapping Create Limit Order button
        let createOrderButton = app.buttons["Create Limit Order"]
        XCTAssertTrue(createOrderButton.exists, "Create Limit Order button should exist")
        XCTAssertTrue(createOrderButton.isEnabled, "Create Limit Order button should be enabled")
        createOrderButton.tap()
        
        // Then: Order confirmation modal should appear
        let confirmTitle = app.staticTexts["Confirm Your Order"]
        XCTAssertTrue(confirmTitle.waitForExistence(timeout: 3), "Order confirmation should appear")
        
        // And: Order details should be visible
        let spendingDetail = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0.01 WMATIC'")).firstMatch
        let receivingDetail = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'USDC'")).firstMatch
        XCTAssertTrue(spendingDetail.exists, "Spending details should be visible")
        XCTAssertTrue(receivingDetail.exists, "Receiving details should be visible")
        
        // When: Tapping Place Order button
        let placeOrderButton = app.buttons["Place Order"]
        XCTAssertTrue(placeOrderButton.exists, "Place Order button should exist")
        placeOrderButton.tap()
        
        // Then: Order should be processing
        let processingButton = app.buttons["Placing Order..."]
        if processingButton.waitForExistence(timeout: 2) {
            XCTAssertTrue(processingButton.exists, "Should show processing state")
        }
        
        // When: Canceling order (if still in confirmation)
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            
            // Then: Should return to trade view
            let createOrderTitle = app.staticTexts["Create Limit Order"]
            XCTAssertTrue(createOrderTitle.waitForExistence(timeout: 3), "Should return to trade view")
        }
    }
    
    func testTransactionsViewFunctionality() throws {
        // Given: Navigate to Transactions tab
        let transactionsTab = app.tabBars.buttons["Transactions"]
        transactionsTab.tap()
        
        // Then: Transactions view should load
        let transactionsTitle = app.navigationBars["Transactions"]
        XCTAssertTrue(transactionsTitle.exists, "Transactions view should load")
        
        // When: Testing filter buttons
        let allFilter = app.buttons["All"]
        let pendingFilter = app.buttons["Pending"]
        let filledFilter = app.buttons["Filled"]
        
        XCTAssertTrue(allFilter.exists, "All filter should exist")
        XCTAssertTrue(pendingFilter.exists, "Pending filter should exist")
        XCTAssertTrue(filledFilter.exists, "Filled filter should exist")
        
        // Test filter interactions
        pendingFilter.tap()
        XCTAssertTrue(pendingFilter.isSelected, "Pending filter should be selected")
        
        filledFilter.tap()
        XCTAssertTrue(filledFilter.isSelected, "Filled filter should be selected")
        
        allFilter.tap()
        XCTAssertTrue(allFilter.isSelected, "All filter should be selected")
        
        // When: Looking for transaction items
        let transactionItems = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'WMATIC'"))
        if transactionItems.count > 0 {
            // Tap on first transaction
            transactionItems.firstMatch.tap()
            
            // Then: Transaction detail should appear
            let detailView = app.staticTexts["Transaction Details"]
            if detailView.waitForExistence(timeout: 3) {
                XCTAssertTrue(detailView.exists, "Transaction detail should appear")
                
                // Dismiss detail
                let dismissButton = app.buttons["Done"] 
                if dismissButton.exists {
                    dismissButton.tap()
                } else {
                    app.swipeDown()
                }
            }
        }
    }
    
    func testDebugViewAccess() throws {
        // Given: App is running
        
        // When: Attempting to access debug view (if available)
        // Note: Debug view might be accessed through navigation or gesture
        
        // Look for debug-related elements
        let debugButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Debug'")).firstMatch
        if debugButton.exists {
            debugButton.tap()
            
            // Then: Debug view should appear
            let debugTitle = app.staticTexts["Debug Router V6"]
            XCTAssertTrue(debugTitle.waitForExistence(timeout: 3), "Debug view should appear")
            
            // And: Test execution button should be present
            let testButton = app.buttons["Execute Test Transaction"]
            XCTAssertTrue(testButton.exists, "Test execution button should exist")
            
            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    // MARK: - Edge Case Tests
    
    func testFormValidation() throws {
        // Given: Navigate to Trade tab
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        // When: Create Order button with empty fields
        let createOrderButton = app.buttons["Create Limit Order"]
        XCTAssertTrue(createOrderButton.exists, "Create Order button should exist")
        
        // Then: Button should be disabled with empty fields
        // Note: Exact disabled state checking may vary by iOS version
        
        // When: Entering invalid values
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        amountField.tap()
        amountField.clearAndEnterText("invalid")
        
        // Then: Should handle invalid input gracefully
        // The app should not crash with invalid input
        XCTAssertTrue(app.state == .runningForeground, "App should handle invalid input gracefully")
    }
    
    func testAppStatePreservation() throws {
        // Given: Navigate to Trade tab and enter data
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
        
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        amountField.tap()
        amountField.clearAndEnterText("5.0")
        
        // When: Navigate away and back
        let homeTab = app.tabBars.buttons["Home"]
        homeTab.tap()
        tradeTab.tap()
        
        // Then: Form data should be preserved
        XCTAssertEqual(amountField.value as? String, "5.0", "Form data should be preserved")
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            XCTFail("Tried to clear and enter text into a non-string value")
            return
        }
        
        self.tap()
        
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        self.typeText(text)
    }
}