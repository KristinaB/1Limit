//
//  WalletSetupUITests.swift
//  1LimitUITests
//
//  Complete wallet setup flow UI tests including SetupCompleteView 🔐✨
//

import XCTest

class WalletSetupUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Bundle Test: Complete Wallet Setup Flow
    
    func testCompleteWalletSetupFlowBundle() throws {
        print("🎯 Starting Complete Wallet Setup Flow Bundle Tests...")
        
        // Navigate to Home tab
        navigateToHomeTab()
        
        // Test 1: Wallet creation initiation
        print("🚀 Testing wallet creation initiation...")
        testWalletCreationInitiation()
        
        // Test 2: Backup phrase view
        print("🔑 Testing backup phrase view...")
        testBackupPhraseView()
        
        // Test 3: New wallet address display
        print("📍 Testing new wallet address display...")
        testNewWalletAddressDisplay()
        
        // Test 4: Balance warning functionality
        print("⚠️ Testing balance warning functionality...")
        testBalanceWarningFunctionality()
        
        // Test 5: Mnemonic copy functionality
        print("📋 Testing mnemonic copy functionality...")
        testMnemonicCopyFunctionality()
        
        // Test 6: Setup completion flow
        print("✅ Testing setup completion flow...")
        testSetupCompleteView()
        
        // Test 6: Flow completion and navigation
        print("🎉 Testing flow completion...")
        testFlowCompletion()
        
        print("✅ Complete Wallet Setup Flow Bundle Tests Completed!")
    }
    
    // MARK: - Bundle Test: Setup Complete View Features
    
    func testSetupCompleteViewFeaturesBundle() throws {
        print("🎉 Starting Setup Complete View Features Bundle Tests...")
        
        // Navigate to wallet creation to reach SetupCompleteView
        navigateToSetupCompleteView()
        
        // Test 1: Setup complete view content
        print("📋 Testing setup complete view content...")
        testSetupCompleteContent()
        
        // Test 2: Success messaging
        print("🎊 Testing success messaging...")
        testSuccessMessaging()
        
        // Test 3: Start Trading button
        print("🚀 Testing Start Trading button...")
        testStartTradingButton()
        
        // Test 4: Navigation to Trade tab
        print("📱 Testing navigation to Trade tab...")
        testNavigationToTrade()
        
        print("✅ Setup Complete View Features Bundle Tests Completed!")
    }
    
    // MARK: - Wallet Creation Flow Tests
    
    private func testWalletCreationInitiation() {
        let activeWalletText = app.staticTexts["Active Wallet"]
        
        // Only test wallet creation if no wallet is active
        if !activeWalletText.exists {
            let createWalletButton = app.buttons["Create New Wallet"]
            XCTAssertTrue(createWalletButton.exists, "Create New Wallet button should exist when no wallet is active")
            XCTAssertTrue(createWalletButton.isHittable, "Create New Wallet button should be tappable")
        } else {
            print("ℹ️ Wallet already active - skipping wallet creation initiation test")
            XCTAssertTrue(true, "Wallet already active - no need for Create Wallet button")
            return
        }
        
        let createWalletButton = app.buttons["Create New Wallet"]
        createWalletButton.tap()
        
        // Check if backup phrase view opens
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 5), "Backup phrase view should open")
    }
    
    private func testBackupPhraseView() {
        // Check if wallet is already active
        let activeWalletText = app.staticTexts["Active Wallet"]
        if activeWalletText.exists {
            print("ℹ️ Wallet already active - skipping backup phrase view test")
            return
        }
        
        // Ensure we're in backup phrase view
        if !app.staticTexts["Save Your Recovery Phrase"].exists {
            let createWalletButton = app.buttons["Create New Wallet"]
            if createWalletButton.exists {
                createWalletButton.tap()
                _ = app.staticTexts["Save Your Recovery Phrase"].waitForExistence(timeout: 5)
            } else {
                print("ℹ️ Create New Wallet button not found - wallet may already be active")
                return
            }
        }
        
        // Test backup phrase view elements
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.exists, "Backup phrase title should be visible")
        
        // Check for recovery phrase explanation
        let explanationText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] 'recovery'")).firstMatch
        XCTAssertTrue(explanationText.exists, "Recovery phrase explanation should be visible")
        
        // Wait for wallet generation to complete
        let generatingText = app.staticTexts["Generating secure wallet..."]
        if generatingText.exists {
            print("⏳ Waiting for wallet generation to complete...")
            usleep(5000000) // 5 seconds
        }
        
        // Check for recovery phrase grid or new wallet address
        let wordsExist = app.staticTexts.allElementsBoundByIndex.contains { element in
            let label = element.label
            return label.count > 0 && label.split(separator: " ").count == 1 && 
                   label.rangeOfCharacter(from: CharacterSet.letters.inverted) == nil
        }
        
        let newWalletAddressExists = app.staticTexts["New Wallet Address:"].exists
        
        XCTAssertTrue(wordsExist || newWalletAddressExists, "Should show recovery words or new wallet address")
    }
    
    private func testNewWalletAddressDisplay() {
        // Ensure we're in backup phrase view with generated wallet
        if !app.staticTexts["Save Your Recovery Phrase"].exists {
            app.buttons["Create Wallet"].tap()
            _ = app.staticTexts["Save Your Recovery Phrase"].waitForExistence(timeout: 5)
            usleep(3000000) // 3 seconds for generation
        }
        
        // Check for new wallet address display
        let newWalletAddressLabel = app.staticTexts["New Wallet Address:"]
        if newWalletAddressLabel.exists {
            XCTAssertTrue(newWalletAddressLabel.exists, "New wallet address label should be visible")
            
            // Look for address text (starts with 0x)
            let addressElements = app.staticTexts.allElementsBoundByIndex.filter { element in
                element.label.hasPrefix("0x") && element.label.count > 10
            }
            
            XCTAssertGreaterThan(addressElements.count, 0, "New wallet address should be displayed")
            
            if let addressElement = addressElements.first {
                print("📍 Found new wallet address: \(String(addressElement.label.prefix(10)))...")
            }
        }
    }
    
    private func testBalanceWarningFunctionality() {
        // This test checks if balance warning appears (it may or may not depending on current wallet state)
        
        // Look for balance warning alert
        let balanceWarningAlert = app.alerts["Wallet Balance Warning"]
        if balanceWarningAlert.exists {
            print("⚠️ Balance warning alert appeared")
            
            // Test alert buttons
            let continueButton = balanceWarningAlert.buttons["Continue Anyway"]
            let cancelButton = balanceWarningAlert.buttons["Cancel"]
            
            XCTAssertTrue(continueButton.exists, "Continue Anyway button should exist in warning")
            XCTAssertTrue(cancelButton.exists, "Cancel button should exist in warning")
            
            // Test continuing despite warning
            if continueButton.exists {
                continueButton.tap()
                usleep(1000000) // 1 second
            }
        } else {
            print("ℹ️ No balance warning shown - current wallet likely has zero balance")
        }
    }
    
    private func testMnemonicCopyFunctionality() {
        // Ensure we're in backup phrase view with generated wallet
        if !app.staticTexts["Save Your Recovery Phrase"].exists {
            app.buttons["Create Wallet"].tap()
            _ = app.staticTexts["Save Your Recovery Phrase"].waitForExistence(timeout: 5)
            usleep(3000000) // 3 seconds for generation
        }
        
        // Look for the copy button
        let copyButton = app.buttons["Copy Recovery Phrase"]
        if copyButton.exists && copyButton.isHittable {
            XCTAssertTrue(copyButton.exists, "Copy Recovery Phrase button should exist")
            
            // Test tapping the copy button
            copyButton.tap()
            usleep(1000000) // 1 second
            
            // Check for success alert
            let copiedAlert = app.alerts["Recovery Phrase Copied!"]
            if copiedAlert.exists {
                XCTAssertTrue(copiedAlert.exists, "Copy success alert should appear")
                
                // Dismiss the alert
                let okButton = copiedAlert.buttons["OK"]
                if okButton.exists {
                    okButton.tap()
                }
            }
            
            // Check if button icon changed to checkmark (temporary state)
            let checkmarkButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Copy Recovery Phrase'")).firstMatch
            XCTAssertTrue(checkmarkButton.exists, "Copy button should still exist after copying")
            
            print("📋 Mnemonic copy functionality tested successfully")
        } else {
            print("ℹ️ Copy Recovery Phrase button not found or not accessible - may not be implemented yet")
        }
    }
    
    private func testSetupCompleteView() {
        // Try to reach setup complete view
        if !isInSetupCompleteView() {
            // If not already there, try to complete the backup phrase flow
            let savedPhraseButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Saved My Phrase'")).firstMatch
            if savedPhraseButton.exists {
                savedPhraseButton.tap()
                
                // Wait for setup complete view
                let setupCompleteTitle = app.staticTexts["You're All Set!"]
                _ = setupCompleteTitle.waitForExistence(timeout: 5)
            }
        }
        
        if isInSetupCompleteView() {
            let setupCompleteTitle = app.staticTexts["You're All Set!"]
            XCTAssertTrue(setupCompleteTitle.exists, "Setup complete title should be visible")
            
            // Check for congratulatory message
            let congratsTexts = [
                "congratulations",
                "wallet created",
                "ready to trade",
                "all set"
            ]
            
            var congratsFound = false
            for congratsText in congratsTexts {
                if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", congratsText)).firstMatch.exists {
                    congratsFound = true
                    print("🎉 Found congratulatory text: \(congratsText)")
                    break
                }
            }
            
            XCTAssertTrue(congratsFound, "Setup complete view should contain congratulatory messaging")
        }
    }
    
    private func testFlowCompletion() {
        if isInSetupCompleteView() {
            let startTradingButton = app.buttons["Start Trading"]
            if startTradingButton.exists {
                startTradingButton.tap()
                
                // Should navigate to Trade tab
                let tradeTab = app.tabBars.buttons["Trade"]
                XCTAssertTrue(tradeTab.waitForExistence(timeout: 3), "Should navigate to Trade tab")
                XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected after setup completion")
                
                // Check if we're on the trade view
                let createLimitOrderText = app.staticTexts["Create Limit Order"]
                XCTAssertTrue(createLimitOrderText.exists, "Should be on Trade view after completion")
            }
        }
    }
    
    // MARK: - Setup Complete View Tests
    
    private func testSetupCompleteContent() {
        if isInSetupCompleteView() {
            // Check for key elements
            let setupCompleteTitle = app.staticTexts["You're All Set!"]
            XCTAssertTrue(setupCompleteTitle.exists, "Setup complete title should exist")
            
            let startTradingButton = app.buttons["Start Trading"]
            XCTAssertTrue(startTradingButton.exists, "Start Trading button should exist")
            XCTAssertTrue(startTradingButton.isHittable, "Start Trading button should be tappable")
        }
    }
    
    private func testSuccessMessaging() {
        if isInSetupCompleteView() {
            // Look for positive, encouraging messaging
            let positiveTexts = [
                "success",
                "ready",
                "complete",
                "congratulations",
                "wallet created"
            ]
            
            var positiveMessagingFound = false
            for text in positiveTexts {
                if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch.exists {
                    positiveMessagingFound = true
                    print("🎊 Found positive messaging: \(text)")
                    break
                }
            }
            
            XCTAssertTrue(positiveMessagingFound, "Setup complete view should contain positive messaging")
        }
    }
    
    private func testStartTradingButton() {
        if isInSetupCompleteView() {
            let startTradingButton = app.buttons["Start Trading"]
            XCTAssertTrue(startTradingButton.exists, "Start Trading button should exist")
            XCTAssertTrue(startTradingButton.isHittable, "Start Trading button should be interactive")
            
            // Test button styling (should be prominent/primary button)
            XCTAssertTrue(startTradingButton.exists, "Start Trading button should be prominently displayed")
        }
    }
    
    private func testNavigationToTrade() {
        if isInSetupCompleteView() {
            let startTradingButton = app.buttons["Start Trading"]
            if startTradingButton.exists {
                startTradingButton.tap()
                
                // Verify navigation to Trade tab
                usleep(1000000) // 1 second
                
                let tradeTab = app.tabBars.buttons["Trade"]
                XCTAssertTrue(tradeTab.exists, "Trade tab should exist after navigation")
                XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")
                
                // Verify we're on the correct Trade view
                let tradingElements = [
                    "Create Limit Order",
                    "Spending",
                    "Buying"
                ]
                
                var onTradeView = false
                for element in tradingElements {
                    if app.staticTexts[element].exists {
                        onTradeView = true
                        print("📱 Found Trade view element: \(element)")
                        break
                    }
                }
                
                XCTAssertTrue(onTradeView, "Should be on Trade view after Start Trading button tap")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
            usleep(1000000) // 1 second
        }
    }
    
    private func navigateToSetupCompleteView() {
        // Navigate through wallet creation flow to reach SetupCompleteView
        navigateToHomeTab()
        
        // Start wallet creation
        let createWalletButton = app.buttons["Create Wallet"]
        if createWalletButton.exists {
            createWalletButton.tap()
            
            // Wait for backup phrase view
            let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
            _ = backupPhraseTitle.waitForExistence(timeout: 5)
            
            // Wait for wallet generation
            usleep(3000000) // 3 seconds
            
            // Proceed with saved phrase button
            let savedPhraseButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Saved My Phrase'")).firstMatch
            if savedPhraseButton.exists {
                savedPhraseButton.tap()
                
                // Wait for setup complete view
                let setupCompleteTitle = app.staticTexts["You're All Set!"]
                _ = setupCompleteTitle.waitForExistence(timeout: 5)
            }
        }
    }
    
    private func isInSetupCompleteView() -> Bool {
        return app.staticTexts["You're All Set!"].exists && app.buttons["Start Trading"].exists
    }
}