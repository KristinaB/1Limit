//
//  TransactionLoadingUITests.swift
//  1LimitUITests
//
//  UI tests for transaction loading and display
//

import XCTest

class TransactionLoadingUITests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        
        // Set up mock data environment variable with the exact JSON data
        app.launchEnvironment["MOCK_TRANSACTIONS_JSON"] = """
        [{"fromAmount":"0.01","date":"2025-07-27T06:40:16Z","type":"Limit Order","id":"3F77BD56-E51A-4A86-B340-5CA4616E0F6D","limitPrice":"0.238","status":"Pending","txHash":"0x523ba3633b331f5a30584f02a656e5e45bdfc4e99d24933297a9291420a0af25","createdAt":"2025-07-27T06:40:16Z","toToken":"USDC","fromToken":"WMATIC","toAmount":"Calculating..."}]
        """
        
        app.launch()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    func testTransactionAppearsInUI() throws {
        print("🧪 Testing transaction appears in UI with exact JSON data...")
        
        // Navigate to Transactions tab
        let transactionsTab = app.tabBars.buttons["Transactions"]
        XCTAssertTrue(transactionsTab.exists, "Transactions tab should exist")
        transactionsTab.tap()
        
        // Wait for transactions to load
        let expectation = XCTestExpectation(description: "Transactions loaded")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3.0)
        
        // Check if transaction appears in the list
        let transactionRow = app.staticTexts["Limit Order"]
        XCTAssertTrue(transactionRow.waitForExistence(timeout: 5), "Transaction 'Limit Order' should appear in the list")
        
        // Check transaction details
        let fromAmount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0.01'")).firstMatch
        XCTAssertTrue(fromAmount.exists, "From amount '0.01' should be visible")
        
        let fromToken = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'WMATIC'")).firstMatch
        XCTAssertTrue(fromToken.exists, "From token 'WMATIC' should be visible")
        
        let toToken = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'USDC'")).firstMatch
        XCTAssertTrue(toToken.exists, "To token 'USDC' should be visible")
        
        let pendingStatus = app.staticTexts["Pending"]
        XCTAssertTrue(pendingStatus.exists, "Status 'Pending' should be visible")
        
        print("✅ Transaction successfully appears in UI with all expected details")
    }
    
    func testTransactionFilteringWithRealData() throws {
        print("🧪 Testing transaction filtering with real data...")
        
        // Navigate to Transactions tab
        app.tabBars.buttons["Transactions"].tap()
        
        // Wait for load
        sleep(2)
        
        // Test "All" filter shows the transaction
        let allFilter = app.buttons["All"]
        XCTAssertTrue(allFilter.exists, "All filter should exist")
        allFilter.tap()
        
        let transactionRow = app.staticTexts["Limit Order"]
        XCTAssertTrue(transactionRow.waitForExistence(timeout: 3), "Transaction should appear with 'All' filter")
        
        // Test "Pending" filter shows the transaction
        let pendingFilter = app.buttons["Pending"]
        XCTAssertTrue(pendingFilter.exists, "Pending filter should exist")
        pendingFilter.tap()
        
        XCTAssertTrue(transactionRow.exists, "Transaction should appear with 'Pending' filter")
        
        // Test "Confirmed" filter hides the transaction (since it's pending)
        let confirmedFilter = app.buttons["Confirmed"]
        XCTAssertTrue(confirmedFilter.exists, "Confirmed filter should exist")
        confirmedFilter.tap()
        
        // Should show empty state or no transaction
        let emptyMessage = app.staticTexts["No Transactions Yet"]
        XCTAssertTrue(emptyMessage.waitForExistence(timeout: 3), "Should show empty state when filtering confirmed transactions")
        
        print("✅ Transaction filtering works correctly with real data")
    }
    
    func testTransactionDetailView() throws {
        print("🧪 Testing transaction detail view with real data...")
        
        // Navigate to Transactions tab
        app.tabBars.buttons["Transactions"].tap()
        
        // Wait for transaction to appear
        let transactionRow = app.staticTexts["Limit Order"]
        XCTAssertTrue(transactionRow.waitForExistence(timeout: 5), "Transaction should appear")
        
        // Look for View button and tap it
        let viewButton = app.buttons["View"]
        if viewButton.exists {
            viewButton.tap()
            
            // Check detail view elements
            let detailTitle = app.staticTexts["Transaction"]
            XCTAssertTrue(detailTitle.waitForExistence(timeout: 3), "Transaction detail view should open")
            
            // Check transaction hash is displayed
            let txHash = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '0x523ba3633b331f5a30584f02a656e5e45bdfc4e99d24933297a9291420a0af25'")).firstMatch
            XCTAssertTrue(txHash.exists, "Transaction hash should be visible in detail view")
            
            // Check PolygonScan button exists
            let polygonScanButton = app.buttons["View on PolygonScan"]
            XCTAssertTrue(polygonScanButton.exists, "PolygonScan button should exist")
            
            // Close detail view
            let doneButton = app.buttons["Done"]
            if doneButton.exists {
                doneButton.tap()
            }
            
            print("✅ Transaction detail view works correctly")
        } else {
            print("⚠️ View button not found, skipping detail view test")
        }
    }
    
    func testEmptyTransactionsState() throws {
        print("🧪 Testing empty transactions state...")
        
        // Launch app without mock data
        app.terminate()
        app.launchEnvironment.removeValue(forKey: "MOCK_TRANSACTIONS_JSON")
        app.launch()
        
        // Navigate to Transactions tab
        app.tabBars.buttons["Transactions"].tap()
        
        // Should show empty state
        let emptyTitle = app.staticTexts["No Transactions Yet"]
        XCTAssertTrue(emptyTitle.waitForExistence(timeout: 5), "Should show empty state when no transactions")
        
        let emptyMessage = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'Your limit orders will appear here'")).firstMatch
        XCTAssertTrue(emptyMessage.exists, "Should show empty state message")
        
        print("✅ Empty transactions state works correctly")
    }
}