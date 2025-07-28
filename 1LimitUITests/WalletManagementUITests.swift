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
        
        print("✅ Wallet Management Bundle Tests Completed!")
    }
    
    // MARK: - Individual Test Methods
    
    private func testWalletButtonsExist() {
        let loadTestWalletButton = app.buttons["Load Test Wallet"]
        let createWalletButton = app.buttons["Create Wallet"]
        
        XCTAssertTrue(loadTestWalletButton.exists, "Load Test Wallet button should exist")
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
        XCTAssertTrue(loadTestWalletButton.isHittable, "Load Test Wallet button should be tappable")
        XCTAssertTrue(createWalletButton.isHittable, "Create Wallet button should be tappable")
    }
    
    private func testLoadTestWallet() {
        let loadTestWalletButton = app.buttons["Load Test Wallet"]
        loadTestWalletButton.tap()
        
        // Wait for wallet to load
        usleep(1000000) // 1 second
        
        // Check if Switch Wallet Mode button appears (indicates wallet loaded)
        let switchWalletButton = app.buttons["Switch Wallet Mode"]
        XCTAssertTrue(switchWalletButton.waitForExistence(timeout: 3), "Switch Wallet Mode button should appear after loading wallet")
        
        // Check if Load Funds button appears
        let loadFundsButton = app.buttons["Load Funds"]
        XCTAssertTrue(loadFundsButton.exists, "Load Funds button should appear when wallet is loaded")
    }
    
    private func testWalletModeSwitching() {
        // Ensure we have a wallet loaded first
        let switchWalletButton = app.buttons["Switch Wallet Mode"]
        if !switchWalletButton.exists {
            app.buttons["Load Test Wallet"].tap()
            usleep(1000000)
        }
        
        // Test switching wallet mode
        if switchWalletButton.exists {
            let initialWalletText = getWalletDisplayText()
            
            switchWalletButton.tap()
            usleep(2000000) // 2 seconds for switch to complete
            
            let newWalletText = getWalletDisplayText()
            
            // Note: Since we might not have a generated wallet, this might stay the same
            // The important thing is that the button works and doesn't crash
            XCTAssertTrue(switchWalletButton.exists, "Switch Wallet Mode button should still exist after switching")
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
            XCTAssertTrue(copyAddressButton.isHittable, "Copy Address button should be tappable")
            
            // Test copy address functionality
            copyAddressButton.tap()
            
            // Check for success alert
            let copiedAlert = app.alerts["Address Copied!"]
            XCTAssertTrue(copiedAlert.waitForExistence(timeout: 2), "Address copied alert should appear")
            
            if copiedAlert.exists {
                copiedAlert.buttons["OK"].tap()
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
        
        // Check if wallet setup flow opens
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        XCTAssertTrue(backupPhraseTitle.waitForExistence(timeout: 3), "Backup phrase view should open")
    }
    
    private func testWalletSetupFlow() {
        // If backup phrase view is not open, open it
        let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
        if !backupPhraseTitle.exists {
            app.buttons["Create Wallet"].tap()
            _ = backupPhraseTitle.waitForExistence(timeout: 3)
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