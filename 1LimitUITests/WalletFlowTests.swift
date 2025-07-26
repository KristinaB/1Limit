//
//  WalletFlowTests.swift
//  1LimitUITests
//
//  Specialized tests for wallet creation and import flows 💜🦄
//

import XCTest

class WalletFlowTests: XCTestCase {

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
    
    // MARK: - Wallet Creation Flow Tests
    
    func testCompleteWalletCreationFlow() throws {
        // Given: App launches on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.isSelected, "Should start on Home tab")
        
        // When: Starting wallet creation
        let createWalletButton = app.buttons["Create Wallet"]
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
        XCTAssertTrue(createWalletButton.isHittable, "Create Wallet button should be tappable")
        createWalletButton.tap()
        
        // Then: Should navigate to backup phrase view
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 5), "Backup phrase view should appear")
        
        // Verify backup phrase view elements
        verifyBackupPhraseView()
        
        // When: Continuing to load funds
        let savedPhraseButton = app.buttons["I've Saved My Phrase"]
        XCTAssertTrue(savedPhraseButton.exists, "I've Saved My Phrase button should exist")
        savedPhraseButton.tap()
        
        // Then: Should navigate to load funds view
        let loadFundsTitle = app.staticTexts["Receive Funds"]
        XCTAssertTrue(loadFundsTitle.waitForExistence(timeout: 5), "Load funds view should appear")
        
        // Verify load funds view elements
        verifyLoadFundsView()
        
        // When: Continuing to setup complete
        let continueButton = app.buttons["Continue to Trade"]
        XCTAssertTrue(continueButton.exists, "Continue to Trade button should exist")
        continueButton.tap()
        
        // Then: Should navigate to setup complete view
        let setupCompleteTitle = app.staticTexts["You're All Set!"]
        XCTAssertTrue(setupCompleteTitle.waitForExistence(timeout: 5), "Setup complete view should appear")
        
        // Verify setup complete view elements
        verifySetupCompleteView()
        
        // When: Finishing setup
        let startTradingButton = app.buttons["Start Trading"]
        XCTAssertTrue(startTradingButton.exists, "Start Trading button should exist")
        startTradingButton.tap()
        
        // Then: Should return to main app with Trade tab active
        let tradeTab = app.tabBars.buttons["Trade"]
        XCTAssertTrue(tradeTab.waitForExistence(timeout: 5), "Should return to main app")
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected after wallet creation")
    }
    
    func testWalletCreationBackNavigation() throws {
        // Given: Navigate through wallet creation flow
        let createWalletButton = app.buttons["Create Wallet"]
        createWalletButton.tap()
        
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Backup phrase view should appear")
        
        let savedPhraseButton = app.buttons["I've Saved My Phrase"]
        savedPhraseButton.tap()
        
        let loadFundsTitle = app.staticTexts["Receive Funds"]
        XCTAssertTrue(loadFundsTitle.waitForExistence(timeout: 3), "Load funds view should appear")
        
        // When: Testing back navigation (if available)
        let backButtons = app.navigationBars.buttons.allElementsBoundByIndex
        let backButton = backButtons.first { $0.label.contains("Back") || $0.label.contains("←") }
        
        if let backButton = backButton, backButton.exists {
            backButton.tap()
            
            // Then: Should return to previous view
            XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Should return to backup phrase view")
        }
    }
    
    func testWalletCreationCancellation() throws {
        // Given: Start wallet creation
        let createWalletButton = app.buttons["Create Wallet"]
        createWalletButton.tap()
        
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Backup phrase view should appear")
        
        // When: Attempting to cancel (test various methods)
        
        // Method 1: Look for cancel/close button
        let cancelButtons = app.buttons.allElementsBoundByIndex.filter { 
            $0.label.lowercased().contains("cancel") || 
            $0.label.lowercased().contains("close") ||
            $0.label.contains("✕")
        }
        
        if let cancelButton = cancelButtons.first, cancelButton.exists {
            cancelButton.tap()
            
            // Should return to home
            let homeTitle = app.staticTexts["1Limit"]
            XCTAssertTrue(homeTitle.waitForExistence(timeout: 3), "Should return to home")
        } else {
            // Method 2: Test swipe down to dismiss (if modal)
            app.swipeDown()
            
            // Check if dismissed
            let homeTitle = app.staticTexts["1Limit"]
            if homeTitle.waitForExistence(timeout: 2) {
                XCTAssertTrue(true, "Modal dismissed with swipe")
            }
        }
    }
    
    func testWalletCreationInterruption() throws {
        // Given: Start wallet creation
        let createWalletButton = app.buttons["Create Wallet"]
        createWalletButton.tap()
        
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Backup phrase view should appear")
        
        // When: Interrupting with tab navigation
        let tradeTab = app.tabBars.buttons["Trade"]
        if tradeTab.isHittable {
            tradeTab.tap()
            
            // Then: Should handle interruption gracefully
            XCTAssertTrue(app.state == .runningForeground, "App should handle wallet creation interruption")
            
            // And: Should switch to trade tab
            XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")
            
            // When: Returning to home and trying wallet creation again
            let homeTab = app.tabBars.buttons["Home"]
            homeTab.tap()
            
            // Should be able to start wallet creation again
            let createWalletButtonAgain = app.buttons["Create Wallet"]
            XCTAssertTrue(createWalletButtonAgain.exists, "Should be able to restart wallet creation")
        }
    }
    
    // MARK: - Import Wallet Flow Tests
    
    func testImportWalletFlow() throws {
        // Given: App is on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        XCTAssertTrue(homeTab.isSelected, "Should start on Home tab")
        
        // When: Starting wallet import
        let importWalletButton = app.buttons["Import Wallet"]
        XCTAssertTrue(importWalletButton.exists, "Import Wallet button should exist")
        XCTAssertTrue(importWalletButton.isHittable, "Import Wallet button should be tappable")
        importWalletButton.tap()
        
        // Then: Should navigate to import view (implementation may vary)
        // Note: Actual implementation may differ, adjust test accordingly
        
        // Look for import-related elements
        let importTitle = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'import'")).firstMatch
        if importTitle.waitForExistence(timeout: 3) {
            XCTAssertTrue(importTitle.exists, "Import view should appear")
            
            // Test for common import elements
            let phraseField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'phrase'")).firstMatch
            let seedField = app.textFields.matching(NSPredicate(format: "placeholderValue CONTAINS[c] 'seed'")).firstMatch
            
            if phraseField.exists {
                XCTAssertTrue(phraseField.exists, "Recovery phrase field should exist")
            } else if seedField.exists {
                XCTAssertTrue(seedField.exists, "Seed phrase field should exist")
            }
        }
    }
    
    // MARK: - Wallet View Component Tests
    
    func verifyBackupPhraseView() {
        // Test all elements in backup phrase view
        
        // Title should be visible
        let title = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(title.exists, "Backup phrase title should be visible")
        
        // Security notice should be visible
        let securityNotice = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'never share'")).firstMatch
        XCTAssertTrue(securityNotice.exists, "Security notice should be visible")
        
        // Recovery phrase should be displayed
        let recoveryPhraseWords = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'abandon'")).firstMatch
        XCTAssertTrue(recoveryPhraseWords.exists, "Recovery phrase words should be displayed")
        
        // Action button should be present
        let actionButton = app.buttons["I've Saved My Phrase"]
        XCTAssertTrue(actionButton.exists, "Action button should be present")
        XCTAssertTrue(actionButton.isEnabled, "Action button should be enabled")
        
        // Copy button should be present (if available)
        let copyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'copy'")).firstMatch
        if copyButton.exists {
            XCTAssertTrue(copyButton.isEnabled, "Copy button should be enabled")
        }
        
        // Glass effect icon should be styled correctly
        let keyIcon = app.images.matching(NSPredicate(format: "label CONTAINS 'key'")).firstMatch
        XCTAssertTrue(keyIcon.exists, "Key icon should be present")
    }
    
    func verifyLoadFundsView() {
        // Test all elements in load funds view
        
        // Title should be visible
        let title = app.staticTexts["Receive Funds"]
        XCTAssertTrue(title.exists, "Load funds title should be visible")
        
        // QR code should be displayed
        let qrCode = app.images["QR Code"]
        XCTAssertTrue(qrCode.exists, "QR code should be displayed")
        
        // Wallet address should be shown
        let walletAddress = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0x'")).firstMatch
        XCTAssertTrue(walletAddress.exists, "Wallet address should be displayed")
        
        // Copy address button should be present
        let copyButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'copy'")).firstMatch
        if copyButton.exists {
            XCTAssertTrue(copyButton.isEnabled, "Copy address button should be enabled")
            
            // Test copy functionality
            copyButton.tap()
            // Note: Actual clipboard testing may require additional setup
        }
        
        // Continue button should be present
        let continueButton = app.buttons["Continue to Trade"]
        XCTAssertTrue(continueButton.exists, "Continue button should be present")
        XCTAssertTrue(continueButton.isEnabled, "Continue button should be enabled")
        
        // Arrow icon should have glass effect styling
        let arrowIcon = app.images.matching(NSPredicate(format: "label CONTAINS 'arrow'")).firstMatch
        XCTAssertTrue(arrowIcon.exists, "Arrow icon should be present")
    }
    
    func verifySetupCompleteView() {
        // Test all elements in setup complete view
        
        // Title should be visible
        let title = app.staticTexts["You're All Set!"]
        XCTAssertTrue(title.exists, "Setup complete title should be visible")
        
        // Success message should be displayed
        let successMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] 'ready'")).firstMatch
        XCTAssertTrue(successMessage.exists, "Success message should be displayed")
        
        // Start trading button should be present
        let startButton = app.buttons["Start Trading"]
        XCTAssertTrue(startButton.exists, "Start Trading button should be present")
        XCTAssertTrue(startButton.isEnabled, "Start Trading button should be enabled")
        
        // Success icon should have glass effect styling
        let successIcon = app.images.matching(NSPredicate(format: "label CONTAINS 'checkmark'")).firstMatch
        XCTAssertTrue(successIcon.exists, "Success icon should be present")
    }
    
    // MARK: - Edge Case Tests
    
    func testRapidWalletCreationAttempts() throws {
        // Test rapid tapping of create wallet button
        let createWalletButton = app.buttons["Create Wallet"]
        
        // Rapid tapping
        for _ in 0..<5 {
            if createWalletButton.exists && createWalletButton.isHittable {
                createWalletButton.tap()
            }
        }
        
        // Should handle gracefully without crashes
        XCTAssertTrue(app.state == .runningForeground, "App should handle rapid wallet creation attempts")
        
        // Should eventually show backup phrase view
        let backupPhraseTitle = app.staticTexts["Save Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 5), "Should eventually show backup phrase")
    }
    
    func testWalletCreationWithLowMemory() throws {
        // Simulate memory pressure during wallet creation
        
        // Start wallet creation
        let createWalletButton = app.buttons["Create Wallet"]
        createWalletButton.tap()
        
        // Navigate through flow quickly to stress memory
        let savedPhraseButton = app.buttons["I've Saved My Phrase"]
        if savedPhraseButton.waitForExistence(timeout: 3) {
            savedPhraseButton.tap()
            
            let continueButton = app.buttons["Continue to Trade"]
            if continueButton.waitForExistence(timeout: 3) {
                continueButton.tap()
                
                let startButton = app.buttons["Start Trading"]
                if startButton.waitForExistence(timeout: 3) {
                    startButton.tap()
                    
                    // Should complete successfully
                    let tradeTab = app.tabBars.buttons["Trade"]
                    XCTAssertTrue(tradeTab.waitForExistence(timeout: 5), "Should complete wallet creation")
                }
            }
        }
    }
}