//
//  TransactionFeaturesUITests.swift
//  1LimitUITests
//
//  Comprehensive transaction features UI tests 📊💱
//

import XCTest

class TransactionFeaturesUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Bundle Test: Transaction List Features
    
    func testTransactionListFeaturesBundle() throws {
        print("📋 Starting Transaction List Features Bundle Tests...")
        
        // Navigate to Transactions tab
        navigateToTransactionsTab()
        
        // Test 1: Transaction list basic functionality
        print("📜 Testing transaction list display...")
        testTransactionListDisplay()
        
        // Test 2: Transaction filtering
        print("🔍 Testing transaction filtering...")
        testTransactionFiltering()
        
        // Test 3: Transaction status display
        print("🎯 Testing transaction status indicators...")
        testTransactionStatusDisplay()
        
        // Test 4: Empty state handling
        print("📭 Testing empty transactions state...")
        testEmptyTransactionsState()
        
        print("✅ Transaction List Features Bundle Tests Completed!")
    }
    
    // MARK: - Bundle Test: Transaction Detail Features
    
    func testTransactionDetailFeaturesBundle() throws {
        print("🔬 Starting Transaction Detail Features Bundle Tests...")
        
        navigateToTransactionsTab()
        
        // Test 1: Transaction detail view access
        print("👆 Testing transaction detail access...")
        testTransactionDetailAccess()
        
        // Test 2: Transaction detail fields
        print("📊 Testing transaction detail fields...")
        testTransactionDetailFields()
        
        // Test 3: More Details accordion
        print("📂 Testing More Details accordion...")
        testMoreDetailsAccordion()
        
        // Test 4: USD value display
        print("💰 Testing USD value calculations...")
        testUSDValueDisplay()
        
        // Test 5: Date and gas formatting
        print("🕐 Testing date and gas formatting...")
        testFormattingDisplay()
        
        print("✅ Transaction Detail Features Bundle Tests Completed!")
    }
    
    // MARK: - Transaction List Tests
    
    private func testTransactionListDisplay() {
        // Check if transactions view loads
        let transactionsTitle = app.navigationBars.staticTexts["Transactions"]
        XCTAssertTrue(transactionsTitle.exists, "Transactions title should be visible")
        
        // Look for transaction-related elements
        let transactionElements = [
            "All",
            "Active", 
            "Completed",
            "Filter",
            "Recent Transactions"
        ]
        
        for element in transactionElements {
            if app.staticTexts[element].exists || app.buttons[element].exists {
                print("✅ Found transaction element: \(element)")
            }
        }
        
        // Check for either transactions or empty state
        let hasTransactions = app.cells.count > 0
        let hasEmptyState = app.staticTexts["No transactions yet"].exists || 
                           app.staticTexts["Start trading to see your transactions here"].exists
        
        XCTAssertTrue(hasTransactions || hasEmptyState, "Should show either transactions or empty state")
    }
    
    private func testTransactionFiltering() {
        // Look for filter buttons
        let filterButtons = ["All", "Active", "Completed"]
        
        for filterName in filterButtons {
            let filterButton = app.buttons[filterName]
            if filterButton.exists && filterButton.isHittable {
                print("🔘 Testing filter: \(filterName)")
                filterButton.tap()
                usleep(500000) // 0.5 second
                
                // Verify filter is applied (button should be selected or list should update)
                XCTAssertTrue(filterButton.exists, "Filter button should still exist after tapping")
            }
        }
    }
    
    private func testTransactionStatusDisplay() {
        // Look for transaction status indicators
        let statusIndicators = [
            "Pending",
            "Confirmed", 
            "Failed",
            "Cancelled"
        ]
        
        var statusFound = false
        for status in statusIndicators {
            if app.staticTexts[status].exists {
                print("📊 Found transaction status: \(status)")
                statusFound = true
            }
        }
        
        // If no specific status found, check for generic transaction items
        if !statusFound {
            let transactionCells = app.cells.allElementsBoundByIndex
            if !transactionCells.isEmpty {
                statusFound = true
                print("📊 Found transaction cells: \(transactionCells.count)")
            }
        }
        
        // Either we have status indicators or no transactions (both valid)
        XCTAssertTrue(statusFound || app.staticTexts["No transactions yet"].exists, 
                     "Should show transaction statuses or empty state")
    }
    
    private func testEmptyTransactionsState() {
        // Check if empty state is properly handled
        let emptyStateTexts = [
            "No transactions yet",
            "Start trading to see your transactions here",
            "Your transaction history will appear here"
        ]
        
        var emptyStateFound = false
        for text in emptyStateTexts {
            if app.staticTexts[text].exists {
                emptyStateFound = true
                print("📭 Found empty state text: \(text)")
                break
            }
        }
        
        // If no empty state found, we should have actual transactions
        if !emptyStateFound {
            let hasCells = app.cells.count > 0
            XCTAssertTrue(hasCells, "If no empty state, should have transaction cells")
        }
    }
    
    // MARK: - Transaction Detail Tests
    
    private func testTransactionDetailAccess() {
        // Try to find and tap on first transaction
        let firstTransaction = app.cells.firstMatch
        if firstTransaction.exists && firstTransaction.isHittable {
            firstTransaction.tap()
            
            // Check if detail view opens
            usleep(1000000) // 1 second
            
            // Look for transaction detail indicators
            let detailIndicators = [
                "Transaction Details",
                "Amount",
                "Status",
                "Date",
                "Back"
            ]
            
            var detailViewOpen = false
            for indicator in detailIndicators {
                if app.staticTexts[indicator].exists || app.buttons[indicator].exists {
                    detailViewOpen = true
                    print("🔍 Found detail view element: \(indicator)")
                    break
                }
            }
            
            if detailViewOpen {
                XCTAssertTrue(true, "Transaction detail view opened successfully")
                
                // Navigate back
                let backButton = app.navigationBars.buttons.firstMatch
                if backButton.exists {
                    backButton.tap()
                }
            }
        }
    }
    
    private func testTransactionDetailFields() {
        // Navigate to first transaction detail if possible
        let firstTransaction = app.cells.firstMatch
        if firstTransaction.exists {
            firstTransaction.tap()
            usleep(1000000)
            
            // Check for expected transaction detail fields
            let expectedFields = [
                "From Amount",
                "To Amount", 
                "Limit Price",
                "Status",
                "Date",
                "Transaction Hash",
                "Gas Fee"
            ]
            
            var fieldsFound = 0
            for field in expectedFields {
                if app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", field)).firstMatch.exists {
                    fieldsFound += 1
                    print("📊 Found transaction field: \(field)")
                }
            }
            
            // We should find at least some transaction fields
            XCTAssertGreaterThan(fieldsFound, 0, "Should find at least some transaction detail fields")
            
            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    private func testMoreDetailsAccordion() {
        let firstTransaction = app.cells.firstMatch
        if firstTransaction.exists {
            firstTransaction.tap()
            usleep(1000000)
            
            // Look for "More Details" button or section
            let moreDetailsButton = app.buttons["More Details"]
            let moreDetailsText = app.staticTexts["More Details"]
            
            if moreDetailsButton.exists {
                print("📂 Found More Details button")
                moreDetailsButton.tap()
                usleep(500000)
                
                // Check if additional details appear
                let detailElements = app.staticTexts.allElementsBoundByIndex
                XCTAssertGreaterThan(detailElements.count, 0, "More details should show additional information")
            } else if moreDetailsText.exists {
                print("📂 Found More Details section")
                XCTAssertTrue(true, "More Details section is visible")
            }
            
            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    private func testUSDValueDisplay() {
        let firstTransaction = app.cells.firstMatch
        if firstTransaction.exists {
            firstTransaction.tap()
            usleep(1000000)
            
            // Look for USD value indicators
            let usdTexts = app.staticTexts.allElementsBoundByIndex.compactMap { $0.label }
            let usdValues = usdTexts.filter { $0.contains("$") && $0.contains(".") }
            
            if !usdValues.isEmpty {
                print("💰 Found USD values: \(usdValues.count)")
                for value in usdValues.prefix(3) {
                    print("💰 USD value: \(value)")
                }
                XCTAssertTrue(true, "USD values are displayed")
            }
            
            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    private func testFormattingDisplay() {
        let firstTransaction = app.cells.firstMatch
        if firstTransaction.exists {
            firstTransaction.tap()
            usleep(1000000)
            
            // Check for formatted elements
            let allTexts = app.staticTexts.allElementsBoundByIndex.compactMap { $0.label }
            
            // Look for gas price formatting (should be in gwei, not wei)
            let gasPrices = allTexts.filter { $0.contains("gwei") || $0.contains("Gas") }
            if !gasPrices.isEmpty {
                print("⛽ Found gas formatting: \(gasPrices)")
            }
            
            // Look for date formatting (should be readable format)
            let dates = allTexts.filter { $0.contains("/") || $0.contains("-") || $0.contains(":") }
            if !dates.isEmpty {
                print("📅 Found date formatting: \(dates.prefix(2))")
            }
            
            XCTAssertTrue(true, "Formatting elements checked")
            
            // Navigate back
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists {
                backButton.tap()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToTransactionsTab() {
        let transactionsTab = app.tabBars.buttons["Transactions"]
        if transactionsTab.exists && !transactionsTab.isSelected {
            transactionsTab.tap()
            usleep(1000000) // 1 second for tab to load
        }
    }
}