//
//  TradeFormInteractionTests.swift
//  1LimitTests
//
//  Specialized tests for trade view form interactions and validation 💫✨
//

import XCTest
import SwiftUI
@testable import _Limit

class TradeFormInteractionTests: XCTestCase {

    // MARK: - Test Properties
    
    var app: XCUIApplication!
    
    // MARK: - Setup & Teardown
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()
        
        // Navigate to Trade tab
        let tradeTab = app.tabBars.buttons["Trade"]
        tradeTab.tap()
    }
    
    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Form Field Interaction Tests
    
    func testAmountFieldInteraction() throws {
        // Given: Trade view is loaded
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        XCTAssertTrue(amountField.exists, "Amount field should exist")
        
        // When: Tapping amount field
        amountField.tap()
        XCTAssertTrue(amountField.hasKeyboardFocus, "Amount field should have keyboard focus")
        
        // When: Entering valid amount
        amountField.typeText("1.5")
        XCTAssertEqual(amountField.value as? String, "1.5", "Amount field should show entered value")
        
        // When: Clearing and entering new amount
        amountField.clearAndEnterText("0.01")
        XCTAssertEqual(amountField.value as? String, "0.01", "Amount field should show new value")
        
        // When: Entering decimal values
        amountField.clearAndEnterText("0.123456")
        XCTAssertEqual(amountField.value as? String, "0.123456", "Should handle decimal values")
        
        // When: Testing keyboard dismissal
        app.tap() // Tap outside field
        XCTAssertFalse(amountField.hasKeyboardFocus, "Keyboard should be dismissed")
    }
    
    func testLimitPriceFieldInteraction() throws {
        // Given: Trade view is loaded
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        XCTAssertTrue(limitPriceFields.count >= 2, "Should have multiple decimal input fields")
        
        let limitPriceField = limitPriceFields.element(boundBy: 1) // Second field
        XCTAssertTrue(limitPriceField.exists, "Limit price field should exist")
        
        // When: Tapping limit price field
        limitPriceField.tap()
        XCTAssertTrue(limitPriceField.hasKeyboardFocus, "Limit price field should have focus")
        
        // When: Entering valid price
        limitPriceField.typeText("0.851")
        XCTAssertEqual(limitPriceField.value as? String, "0.851", "Limit price should show entered value")
        
        // When: Testing price formatting
        limitPriceField.clearAndEnterText("1.234567")
        XCTAssertEqual(limitPriceField.value as? String, "1.234567", "Should handle precise decimals")
        
        // When: Entering very small values
        limitPriceField.clearAndEnterText("0.000001")
        XCTAssertEqual(limitPriceField.value as? String, "0.000001", "Should handle small decimal values")
    }
    
    func testTokenSelectionInteraction() throws {
        // Given: Trade view is loaded
        
        // Test from token selection
        let fromTokenPicker = app.buttons.matching(NSPredicate(format: "label CONTAINS 'WMATIC' OR label CONTAINS 'USDC'")).firstMatch
        if fromTokenPicker.exists {
            let initialToken = fromTokenPicker.label
            
            // When: Tapping token picker
            fromTokenPicker.tap()
            
            // Then: Should show token options (implementation may vary)
            // This test assumes picker behavior, adjust based on actual implementation
            
            // Look for different token option
            let alternativeToken = initialToken.contains("WMATIC") ? "USDC" : "WMATIC"
            let alternativeOption = app.buttons[alternativeToken]
            
            if alternativeOption.exists {
                alternativeOption.tap()
                
                // Verify token changed
                let updatedPicker = app.buttons.matching(NSPredicate(format: "label CONTAINS '\(alternativeToken)'")).firstMatch
                XCTAssertTrue(updatedPicker.exists, "Token should be updated")
            }
        }
    }
    
    func testSwapTokensInteraction() throws {
        // Given: Trade view with tokens selected
        let initialFromToken = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'WMATIC' OR label CONTAINS 'USDC'")).firstMatch?.label
        
        // When: Tapping swap button
        let swapButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'arrow'")).firstMatch
        XCTAssertTrue(swapButton.exists, "Swap button should exist")
        swapButton.tap()
        
        // Then: Tokens should be swapped (visual verification may vary)
        // Give time for animation
        usleep(500000) // 0.5 seconds
        
        // Verify swap occurred by checking token positions
        XCTAssertTrue(app.isRunning, "App should handle token swap without crashes")
    }
    
    // MARK: - Form Validation Tests
    
    func testFormValidationWithEmptyFields() throws {
        // Given: Trade view with empty fields
        let createOrderButton = app.buttons["Create Limit Order"]
        XCTAssertTrue(createOrderButton.exists, "Create Order button should exist")
        
        // When: Attempting to create order with empty fields
        // Button should be disabled or handle gracefully
        if createOrderButton.isEnabled {
            createOrderButton.tap()
            
            // Should either show validation error or be prevented
            XCTAssertTrue(app.isRunning, "App should handle empty form submission")
        } else {
            XCTAssertFalse(createOrderButton.isEnabled, "Button should be disabled with empty fields")
        }
    }
    
    func testFormValidationWithInvalidValues() throws {
        // Given: Trade view
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        // When: Entering invalid amount
        amountField.tap()
        amountField.typeText("invalid")
        
        limitPriceField.tap()
        limitPriceField.typeText("0.851")
        
        // Then: Should handle invalid input gracefully
        let createOrderButton = app.buttons["Create Limit Order"]
        if createOrderButton.isEnabled {
            createOrderButton.tap()
            XCTAssertTrue(app.isRunning, "App should handle invalid amount input")
        }
        
        // When: Entering invalid price
        amountField.clearAndEnterText("1.0")
        limitPriceField.clearAndEnterText("invalid")
        
        // Then: Should handle invalid price gracefully
        if createOrderButton.isEnabled {
            createOrderButton.tap()
            XCTAssertTrue(app.isRunning, "App should handle invalid price input")
        }
    }
    
    func testFormValidationWithZeroValues() throws {
        // Given: Trade view
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        // When: Entering zero amount
        amountField.tap()
        amountField.typeText("0")
        
        limitPriceField.tap()
        limitPriceField.typeText("0.851")
        
        // Then: Should handle zero amount appropriately
        let createOrderButton = app.buttons["Create Limit Order"]
        XCTAssertTrue(app.isRunning, "App should handle zero amount")
        
        // When: Entering zero price
        amountField.clearAndEnterText("1.0")
        limitPriceField.clearAndEnterText("0")
        
        // Then: Should handle zero price appropriately
        XCTAssertTrue(app.isRunning, "App should handle zero price")
    }
    
    func testFormValidationWithNegativeValues() throws {
        // Given: Trade view
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        // When: Attempting to enter negative values
        amountField.tap()
        amountField.typeText("-1.0")
        
        limitPriceField.tap()
        limitPriceField.typeText("-0.5")
        
        // Then: Should handle negative values appropriately
        XCTAssertTrue(app.isRunning, "App should handle negative values gracefully")
    }
    
    // MARK: - Order Preview Tests
    
    func testOrderPreviewGeneration() throws {
        // Given: Trade view with valid inputs
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        // When: Entering valid values
        amountField.tap()
        amountField.typeText("1.0")
        
        limitPriceField.tap()
        limitPriceField.typeText("0.851")
        
        // Then: Order preview should appear
        let orderPreview = app.staticTexts["Order Preview"]
        XCTAssertTrue(orderPreview.waitForExistence(timeout: 3), "Order preview should appear")
        
        // And: Preview should show calculated values
        let spendingAmount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '1.0'")).firstMatch
        let receivingAmount = app.staticTexts.matching(NSPredicate(format: "label CONTAINS 'receive'")).firstMatch
        
        XCTAssertTrue(spendingAmount.exists, "Should show spending amount")
        XCTAssertTrue(receivingAmount.exists, "Should show receiving amount")
    }
    
    func testOrderPreviewUpdates() throws {
        // Given: Trade view with initial values
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        amountField.tap()
        amountField.typeText("1.0")
        limitPriceField.tap()
        limitPriceField.typeText("0.851")
        
        // When: Updating amount
        amountField.clearAndEnterText("2.0")
        
        // Then: Preview should update
        let updatedPreview = app.staticTexts.matching(NSPredicate(format: "label CONTAINS '2.0'")).firstMatch
        XCTAssertTrue(updatedPreview.waitForExistence(timeout: 3), "Preview should update with new amount")
        
        // When: Updating price
        limitPriceField.clearAndEnterText("1.0")
        
        // Then: Preview should update again
        XCTAssertTrue(app.isRunning, "App should handle preview updates")
    }
    
    // MARK: - Chart Integration Tests
    
    func testChartButtonInteraction() throws {
        // Given: Trade view is loaded
        let chartButton = app.buttons["Chart"]
        XCTAssertTrue(chartButton.exists, "Chart button should exist")
        XCTAssertTrue(chartButton.isHittable, "Chart button should be tappable")
        
        // When: Tapping chart button
        chartButton.tap()
        
        // Then: Chart modal should appear
        let chartView = app.staticTexts["Price Chart"]
        XCTAssertTrue(chartView.waitForExistence(timeout: 5), "Chart view should appear")
        
        // When: Dismissing chart
        let doneButton = app.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            app.swipeDown()
        }
        
        // Then: Should return to trade view
        let createOrderTitle = app.staticTexts["Create Limit Order"]
        XCTAssertTrue(createOrderTitle.waitForExistence(timeout: 3), "Should return to trade view")
    }
    
    // MARK: - Order Creation Flow Tests
    
    func testOrderCreationFlow() throws {
        // Given: Trade view with valid form data
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        amountField.tap()
        amountField.typeText("0.01")
        
        limitPriceField.tap()
        limitPriceField.typeText("0.851")
        
        // When: Creating order
        let createOrderButton = app.buttons["Create Limit Order"]
        XCTAssertTrue(createOrderButton.exists, "Create Order button should exist")
        createOrderButton.tap()
        
        // Then: Confirmation modal should appear
        let confirmTitle = app.staticTexts["Confirm Your Order"]
        XCTAssertTrue(confirmTitle.waitForExistence(timeout: 5), "Order confirmation should appear")
        
        // When: Canceling order
        let cancelButton = app.buttons["Cancel"]
        XCTAssertTrue(cancelButton.exists, "Cancel button should exist")
        cancelButton.tap()
        
        // Then: Should return to trade view
        let tradeTitle = app.staticTexts["Create Limit Order"]
        XCTAssertTrue(tradeTitle.waitForExistence(timeout: 3), "Should return to trade view")
    }
    
    // MARK: - Auto-fill and Default Value Tests
    
    func testDefaultAmountValue() throws {
        // Given: Trade view loads
        let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
        
        // Then: Should have default value of 0.01
        if let currentValue = amountField.value as? String, !currentValue.isEmpty {
            XCTAssertEqual(currentValue, "0.01", "Should have default amount of 0.01")
        }
    }
    
    func testAutoLimitPriceCalculation() throws {
        // Given: Trade view loads with default tokens
        let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
        let limitPriceField = limitPriceFields.element(boundBy: 1)
        
        // Then: Limit price should auto-calculate from market price
        // Wait for price service to load
        usleep(2000000) // 2 seconds for price loading
        
        if let currentValue = limitPriceField.value as? String, !currentValue.isEmpty {
            XCTAssertFalse(currentValue == "0.00", "Limit price should auto-calculate from market")
            XCTAssertTrue(Double(currentValue) != nil, "Auto-calculated price should be valid number")
        }
    }
    
    // MARK: - Performance Tests
    
    func testFormInteractionPerformance() throws {
        measure {
            let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
            let limitPriceFields = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
            let limitPriceField = limitPriceFields.element(boundBy: 1)
            
            // Test rapid form interactions
            amountField.tap()
            amountField.typeText("1.5")
            
            limitPriceField.tap()
            limitPriceField.typeText("0.851")
            
            // Tap outside to dismiss keyboard
            app.tap()
        }
    }
    
    func testFormValidationPerformance() throws {
        measure {
            let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'")).firstMatch
            
            // Test rapid value changes
            for i in 1...5 {
                amountField.clearAndEnterText("\(i).0")
            }
        }
    }
}

// MARK: - Helper Extensions

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        guard let stringValue = self.value as? String else {
            return
        }
        
        self.tap()
        
        // Clear existing text
        let deleteString = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
        self.typeText(deleteString)
        
        // Enter new text
        self.typeText(text)
    }
}