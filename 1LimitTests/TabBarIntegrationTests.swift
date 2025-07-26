//
//  TabBarIntegrationTests.swift
//  1LimitTests
//
//  Integration tests for tab bar navigation and rendering 🎀✨
//

import XCTest
import SwiftUI
@testable import _Limit

class TabBarIntegrationTests: XCTestCase {

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
    
    // MARK: - Tab Bar Rendering Tests
    
    func testTabBarRendersCorrectly() throws {
        // Given: App is launched
        
        // When: Main interface loads
        let tabBar = app.tabBars.firstMatch
        
        // Then: Tab bar should be visible
        XCTAssertTrue(tabBar.exists, "Tab bar should be visible on main screen")
        XCTAssertTrue(tabBar.isHittable, "Tab bar should be interactive")
        
        // And: All three tabs should be present
        let homeTab = app.tabBars.buttons["Home"]
        let tradeTab = app.tabBars.buttons["Trade"] 
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertTrue(homeTab.exists, "Home tab should be present")
        XCTAssertTrue(tradeTab.exists, "Trade tab should be present")
        XCTAssertTrue(transactionsTab.exists, "Transactions tab should be present")
        
        // And: Home tab should be selected by default
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected by default")
    }
    
    func testTabBarNavigationFlow() throws {
        // Given: App is launched with Home tab active
        let homeTab = app.tabBars.buttons["Home"]
        let tradeTab = app.tabBars.buttons["Trade"]
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        XCTAssertTrue(homeTab.isSelected, "Home should be initially selected")
        
        // When: Tapping Trade tab
        tradeTab.tap()
        
        // Then: Trade tab becomes active
        XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected after tap")
        XCTAssertFalse(homeTab.isSelected, "Home tab should be deselected")
        
        // When: Tapping Transactions tab
        transactionsTab.tap()
        
        // Then: Transactions tab becomes active
        XCTAssertTrue(transactionsTab.isSelected, "Transactions tab should be selected after tap")
        XCTAssertFalse(tradeTab.isSelected, "Trade tab should be deselected")
        
        // When: Returning to Home tab
        homeTab.tap()
        
        // Then: Home tab becomes active again
        XCTAssertTrue(homeTab.isSelected, "Home tab should be selected again")
        XCTAssertFalse(transactionsTab.isSelected, "Transactions tab should be deselected")
    }
    
    func testTradeViewContentRendering() throws {
        // Given: App is launched
        let tradeTab = app.tabBars.buttons["Trade"]
        
        // When: Navigating to Trade tab
        tradeTab.tap()
        
        // Then: Trade view content should be visible
        let createLimitOrderText = app.staticTexts["Create Limit Order"]
        XCTAssertTrue(createLimitOrderText.exists, "Create Limit Order title should be visible")
        
        // And: Essential form elements should be present
        let spendingSection = app.staticTexts["Spending"]
        let buyingSection = app.staticTexts["Buying"]
        let amountSection = app.staticTexts["Amount"]
        let limitPriceSection = app.staticTexts["Limit Price"]
        
        XCTAssertTrue(spendingSection.exists, "Spending section should be visible")
        XCTAssertTrue(buyingSection.exists, "Buying section should be visible")
        XCTAssertTrue(amountSection.exists, "Amount section should be visible")
        XCTAssertTrue(limitPriceSection.exists, "Limit Price section should be visible")
        
        // And: Chart button should be present
        let chartButton = app.buttons["Chart"]
        XCTAssertTrue(chartButton.exists, "Chart button should be visible")
        XCTAssertTrue(chartButton.isHittable, "Chart button should be tappable")
    }
    
    func testHomeViewContentRendering() throws {
        // Given: App is launched (Home tab is default)
        
        // Then: Home view content should be visible
        let appTitle = app.staticTexts["1Limit"]
        XCTAssertTrue(appTitle.exists, "App title should be visible on Home tab")
        
        let subtitle = app.staticTexts["Place Decentralized 1Inch Limit Orders with ease!"]
        XCTAssertTrue(subtitle.exists, "App subtitle should be visible")
        
        // And: Action buttons should be present
        let createWalletButton = app.buttons["Create Wallet"]
        let importWalletButton = app.buttons["Import Wallet"]
        
        XCTAssertTrue(createWalletButton.exists, "Create Wallet button should be visible")
        XCTAssertTrue(importWalletButton.exists, "Import Wallet button should be visible")
        XCTAssertTrue(createWalletButton.isHittable, "Create Wallet button should be tappable")
        XCTAssertTrue(importWalletButton.isHittable, "Import Wallet button should be tappable")
    }
    
    func testTransactionsViewContentRendering() throws {
        // Given: App is launched
        let transactionsTab = app.tabBars.buttons["Transactions"]
        
        // When: Navigating to Transactions tab
        transactionsTab.tap()
        
        // Then: Transactions view content should be visible
        let transactionsTitle = app.navigationBars["Transactions"]
        XCTAssertTrue(transactionsTitle.exists, "Transactions navigation title should be visible")
        
        // And: Filter section should be present
        let filterTitle = app.staticTexts["Filter Transactions"]
        XCTAssertTrue(filterTitle.exists, "Filter Transactions title should be visible")
        
        // And: Filter buttons should be present (no Cancelled filter)
        let allFilter = app.buttons["All"]
        let pendingFilter = app.buttons["Pending"] 
        let filledFilter = app.buttons["Filled"]
        
        XCTAssertTrue(allFilter.exists, "All filter button should be present")
        XCTAssertTrue(pendingFilter.exists, "Pending filter button should be present")
        XCTAssertTrue(filledFilter.exists, "Filled filter button should be present")
        
        // And: Cancelled filter should NOT be present
        let cancelledFilter = app.buttons["Cancelled"]
        XCTAssertFalse(cancelledFilter.exists, "Cancelled filter should not be present")
    }
    
    // MARK: - Performance Tests
    
    func testTabBarNavigationPerformance() throws {
        measure {
            // Test performance of tab switching
            let tradeTab = app.tabBars.buttons["Trade"]
            let homeTab = app.tabBars.buttons["Home"]
            
            tradeTab.tap()
            homeTab.tap()
        }
    }
}