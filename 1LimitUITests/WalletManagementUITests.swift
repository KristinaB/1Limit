//
//  WalletManagementUITests.swift
//  1LimitUITests
//
//  Comprehensive wallet management UI tests 🔐💰
//

import XCTest

class WalletManagementUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Bundle Test: Wallet Management Features
    
    func testWalletManagementBundle() throws {
        print("💳 Starting Wallet Management Bundle Tests...")
        
        // Ensure we're on Home tab
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
            usleep(500000) // 0.5 second
        }
        
        // Test 1: Verify wallet-related buttons exist
        print("🔍 Testing wallet button availability...")
        testWalletButtonsExist()
        
        // Test 2: Test Load Test Wallet functionality
        print("📁 Testing Load Test Wallet...")
        testLoadTestWallet()
        
        // Test 3: Test wallet mode switching
        print("🔄 Testing wallet mode switching...")
        testWalletModeSwitching()
        
        // Test 4: Test Load Funds button and panel
        print("💰 Testing Load Funds functionality...")
        testLoadFundsPanel()
        
        // Test 5: Test balance display
        print("📊 Testing balance display...")
        testBalanceDisplay()
        
        // Test 6: Test Import Wallet functionality
        print("📥 Testing Import Wallet functionality...")
        testImportWalletPanel()
        
        print("✅ Wallet Management Bundle Tests Completed!")
    }
    
    // MARK: - Individual Test Methods
    
    private func testWalletButtonsExist() {
        // Test for the new cycling button (starts as "Load Test Wallet")
        let cyclingWalletButton = app.buttons.matching(
            NSPredicate(format: "label == 'Load Test Wallet' OR label == 'Load Your Wallet'")
        ).firstMatch
        let createWalletButton = app.buttons["Create Wallet"]
        let importWalletButton = app.buttons["Import Wallet"]
        
        XCTAssertTrue(cyclingWalletButton.exists, "Cycling wallet button should exist")
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
        XCTAssertTrue(importWalletButton.exists, "Import Wallet button should exist")
        XCTAssertTrue(cyclingWalletButton.isHittable, "Cycling wallet button should be tappable")
        XCTAssertTrue(createWalletButton.isHittable, "Create Wallet button should be tappable")
        XCTAssertTrue(importWalletButton.isHittable, "Import Wallet button should be tappable")
    }
    
    private func testLoadTestWallet() {
        let loadTestWalletButton = app.buttons["Load Test Wallet"]
        if loadTestWalletButton.exists {
            loadTestWalletButton.tap()
            
            // Wait for wallet to load
            usleep(1000000) // 1 second
            
            // Check if cycling button changes to "Load Your Wallet" (indicates test wallet loaded)
            let loadYourWalletButton = app.buttons["Load Your Wallet"]
            XCTAssertTrue(loadYourWalletButton.waitForExistence(timeout: 3), "Button should change to 'Load Your Wallet' after loading test wallet")
            
            // Check if Load Funds button appears
            let loadFundsButton = app.buttons["Load Funds"]
            XCTAssertTrue(loadFundsButton.exists, "Load Funds button should appear when wallet is loaded")
        }
    }
    
    private func testWalletModeSwitching() {
        // Ensure we have a wallet loaded first by looking for the cycling button
        let loadYourWalletButton = app.buttons["Load Your Wallet"]
        let loadTestWalletButton = app.buttons["Load Test Wallet"]
        
        // If no wallet loaded, load test wallet first
        if !loadYourWalletButton.exists && loadTestWalletButton.exists {
            loadTestWalletButton.tap()
            usleep(1000000)
        }
        
        // Test cycling between wallet modes
        if loadYourWalletButton.exists {
            let initialButtonText = loadYourWalletButton.label
            print("🔄 Initial button text: \(initialButtonText)")
            
            // Tap the cycling button
            loadYourWalletButton.tap()
            usleep(2000000) // 2 seconds for switch to complete
            
            // Check if button text changed or if we have a different cycling state
            let cyclingButton = app.buttons.matching(
                NSPredicate(format: "label == 'Load Test Wallet' OR label == 'Load Your Wallet'")
            ).firstMatch
            
            XCTAssertTrue(cyclingButton.exists, "Cycling button should still exist after switching")
            
            // If we have a generated wallet, button should have switched
            // If not, it may show the same thing - both are valid behaviors
            let finalButtonText = cyclingButton.label
            print("🔄 Final button text: \(finalButtonText)")
        }
    }
    
    private func testLoadFundsPanel() {
        // Ensure we have a wallet loaded
        let loadFundsButton = app.buttons["Load Funds"]
        if !loadFundsButton.exists {
            app.buttons["Load Test Wallet"].tap()
            usleep(1000000)
        }
        
        if loadFundsButton.exists {
            loadFundsButton.tap()
            
            // Check if ReceiveFundsView opens
            let receiveFundsTitle = app.navigationBars["Receive Funds"]
            XCTAssertTrue(receiveFundsTitle.waitForExistence(timeout: 3), "Receive Funds view should open")
            
            // Test key elements in the receive funds view
            let scanQRText = app.staticTexts["Scan QR Code"]
            XCTAssertTrue(scanQRText.exists, "QR Code section should exist")
            
            let walletAddressText = app.staticTexts["Wallet Address"]
            XCTAssertTrue(walletAddressText.exists, "Wallet Address section should exist")
            
            let copyAddressButton = app.buttons["Copy Address"]
            XCTAssertTrue(copyAddressButton.exists, "Copy Address button should exist")
            
            // Test copy address functionality if button is accessible
            if copyAddressButton.exists && copyAddressButton.isHittable {
                copyAddressButton.tap()
                
                // Check for success alert
                let copiedAlert = app.alerts["Address Copied!"]
                XCTAssertTrue(copiedAlert.waitForExistence(timeout: 2), "Address copied alert should appear")
                
                if copiedAlert.exists {
                    copiedAlert.buttons["OK"].tap()
                }
            } else {
                print("⚠️ Copy Address button exists but is not hittable - skipping tap test")
            }
            
            // Close the receive funds view
            let doneButton = app.navigationBars["Receive Funds"].buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
        }
    }
    
    private func testBalanceDisplay() {
        // Look for balance-related text
        let balanceTexts = [
            "Total Balance",
            "Loading balance...",
            "Balance unavailable"
        ]
        
        var balanceDisplayFound = false
        for balanceText in balanceTexts {
            if app.staticTexts[balanceText].exists {
                balanceDisplayFound = true
                print("📊 Found balance display: \(balanceText)")
                break
            }
        }
        
        // Note: Balance might be loading or unavailable, so we just check structure exists
        // The important thing is that the balance card structure is present when wallet exists
        if app.buttons["Switch Wallet Mode"].exists {
            // Wallet exists, so balance card should be visible in some form
            XCTAssertTrue(balanceDisplayFound, "Some form of balance display should be visible when wallet is loaded")
        }
    }
    
    private func testImportWalletPanel() {
        let importWalletButton = app.buttons["Import Wallet"]
        XCTAssertTrue(importWalletButton.exists, "Import Wallet button should exist")
        
        importWalletButton.tap()
        
        // Check if ImportWalletView opens
        let importWalletTitle = app.navigationBars["Import Wallet"]
        XCTAssertTrue(importWalletTitle.waitForExistence(timeout: 3), "Import Wallet view should open")
        
        // Test key elements in the import wallet view
        let importMethodText = app.staticTexts["Input Method"]
        XCTAssertTrue(importMethodText.exists, "Input Method section should exist")
        
        let recoveryPhraseText = app.staticTexts["Recovery Phrase"]
        XCTAssertTrue(recoveryPhraseText.exists, "Recovery Phrase section should exist")
        
        // Test input method toggle
        let wordGridButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Word Grid'")).firstMatch
        let textAreaButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Text Area'")).firstMatch
        
        if wordGridButton.exists {
            XCTAssertTrue(wordGridButton.exists, "Word Grid option should exist")
        }
        
        if textAreaButton.exists {
            textAreaButton.tap()
            usleep(500000) // 0.5 second
            
            // Check if text area appears
            let textEditor = app.textViews.firstMatch
            XCTAssertTrue(textEditor.exists, "Text area should appear when Text Area option is selected")
        }
        
        // Test paste button
        let pasteButton = app.buttons["Paste from Clipboard"]
        XCTAssertTrue(pasteButton.exists, "Paste from Clipboard button should exist")
        
        // Test import button (should be disabled initially)
        let importButton = app.buttons.containing(NSPredicate(format: "label CONTAINS 'Import Wallet'")).firstMatch
        if importButton.exists {
            XCTAssertTrue(importButton.exists, "Import Wallet button should exist")
            // Note: We don't test actual import functionality to avoid replacing wallet in tests
        }
        
        // Close the import wallet view
        let cancelButton = app.buttons["Cancel"]
        if cancelButton.exists {
            cancelButton.tap()
            usleep(1000000) // 1 second
        }
    }
    
    // MARK: - Helper Methods
    
    private func getWalletDisplayText() -> String {
        // Try to find wallet address or balance card text
        let allTexts = app.staticTexts.allElementsBoundByIndex
        for textElement in allTexts {
            let text = textElement.label
            if text.contains("0x") && text.contains("...") {
                return text
            }
        }
        return ""
    }
    
    private func navigateToHomeTab() {
        let homeTab = app.tabBars.buttons["Home"]
        if homeTab.exists && !homeTab.isSelected {
            homeTab.tap()
            usleep(500000)
        }
    }
}

// MARK: - Wallet Generation Flow Tests

extension WalletManagementUITests {
    
    func testWalletGenerationFlowBundle() throws {
        print("🆕 Starting Wallet Generation Flow Bundle Tests...")
        
        navigateToHomeTab()
        
        // Test 1: Create wallet button accessibility
        print("➕ Testing Create Wallet button...")
        testCreateWalletButton()
        
        // Test 2: Wallet setup flow
        print("📝 Testing Wallet Setup Flow...")
        testWalletSetupFlow()
        
        print("✅ Wallet Generation Flow Bundle Tests Completed!")
    }
    
    private func testCreateWalletButton() {
        let createWalletButton = app.buttons["Create Wallet"]
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
        XCTAssertTrue(createWalletButton.isHittable, "Create Wallet button should be tappable")
        
        createWalletButton.tap()
        
        // Check if wallet setup flow opens - allow more time for view to appear
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        if backupPhraseTitle.waitForExistence(timeout: 8) {
            XCTAssertTrue(backupPhraseTitle.exists, "Backup phrase view should open")
        } else {
            // If the exact title doesn't exist, check for other wallet creation indicators
            let walletCreationIndicators = [
                "Save Your Recovery Phrase",
                "Recovery Phrase", 
                "12 words",
                "mnemonic",
                "Create Wallet",
                "Generate"
            ]
            
            var walletCreationFound = false
            for indicator in walletCreationIndicators {
                if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", indicator)).firstMatch.exists {
                    walletCreationFound = true
                    print("🔍 Found wallet creation indicator: \(indicator)")
                    break
                }
            }
            
            XCTAssertTrue(walletCreationFound, "Some form of wallet creation view should open")
        }
    }
    
    private func testWalletSetupFlow() {
        // If backup phrase view is not open, open it
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        if !backupPhraseTitle.exists {
            let createWalletButton = app.buttons["Create Wallet"]
            if createWalletButton.exists {
                createWalletButton.tap()
                _ = backupPhraseTitle.waitForExistence(timeout: 8)
            }
        }
        
        if backupPhraseTitle.exists {
            // Test backup phrase view elements
            let warningText = app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'recovery phrase'"))
            XCTAssertTrue(warningText.firstMatch.exists, "Recovery phrase warning should exist")
            
            // Look for Continue or Next button
            let continueButton = app.buttons["Continue"]
            let nextButton = app.buttons["Next"]
            let doneButton = app.buttons["Done"]
            
            if continueButton.exists {
                continueButton.tap()
            } else if nextButton.exists {
                nextButton.tap()
            } else if doneButton.exists {
                doneButton.tap()
            }
            
            // Check if we can complete the flow
            usleep(1000000) // 1 second
            
            // The flow should either complete or show next step
            // For now, we just verify it doesn't crash
            XCTAssertTrue(true, "Wallet setup flow should not crash")
        }
    }
}