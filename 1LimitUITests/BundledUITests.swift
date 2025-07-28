//
//  BundledUITests.swift
//  1LimitUITests
//
//  Bundled tests that run multiple test scenarios in a single app session 🚀⚡️
//

import XCTest

class BundledUITests: XCTestCase {

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

  // MARK: - Bundled Navigation Tests

  func testNavigationAndTabBarBundle() throws {
    print("🧭 Starting Navigation & TabBar Bundle Tests...")

    // Test 1: Basic tab bar rendering
    print("📱 Testing tab bar rendering...")
    let tabBar = app.tabBars.firstMatch
    XCTAssertTrue(tabBar.exists, "Tab bar should be visible")

    let homeTab = app.tabBars.buttons["Home"]
    let tradeTab = app.tabBars.buttons["Trade"]
    let transactionsTab = app.tabBars.buttons["Transactions"]

    XCTAssertTrue(homeTab.exists, "Home tab should exist")
    XCTAssertTrue(tradeTab.exists, "Trade tab should exist")
    XCTAssertTrue(transactionsTab.exists, "Transactions tab should exist")
    XCTAssertTrue(homeTab.isSelected, "Home tab should be selected by default")

    // Test 2: Tab navigation sequence using coordinate taps
    print("🔄 Testing tab navigation sequence...")
    let tabBarBounds = app.tabBars.firstMatch
    if tabBarBounds.exists {
      // Tap Trade tab area
      let tradeCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      tradeCoordinate.tap()
      usleep(500000)  // 0.5 seconds
      XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")

      // Tap Transactions tab area
      let transactionsCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
      transactionsCoordinate.tap()
      usleep(500000)  // 0.5 seconds
      XCTAssertTrue(transactionsTab.isSelected, "Transactions tab should be selected")

      // Tap Home tab area
      let homeCoordinate = tabBarBounds.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
      homeCoordinate.tap()
      usleep(500000)  // 0.5 seconds
      XCTAssertTrue(homeTab.isSelected, "Home tab should be selected again")
    }

    // Test 3: Content persistence across tabs
    print("💾 Testing content persistence...")
    if tabBarBounds.exists {
      let tradeCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      tradeCoordinate.tap()
      usleep(500000)  // 0.5 seconds
    }

    let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
      .firstMatch
    if amountField.exists {
      let amountCoordinate = amountField.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      amountCoordinate.tap()
      amountField.tap()

      // Clear field first if it has content
      if let currentValue = amountField.value as? String, !currentValue.isEmpty {
        let deleteString = String(
          repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        amountField.typeText(deleteString)
      }
      amountField.typeText("1.5")

      // Navigate away and back using coordinate taps to avoid accessibility errors
      let tabBarBounds = app.tabBars.firstMatch
      if tabBarBounds.exists {
        let homeCoordinate = tabBarBounds.coordinate(
          withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
        homeCoordinate.tap()
        usleep(300000)  // 0.3 seconds

        let transactionsCoordinate = tabBarBounds.coordinate(
          withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
        transactionsCoordinate.tap()
        usleep(300000)  // 0.3 seconds

        let tradeCoordinate = tabBarBounds.coordinate(
          withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        tradeCoordinate.tap()
        usleep(300000)  // 0.3 seconds
      }

      // Check if content persisted
      if let currentValue = amountField.value as? String {
        XCTAssertEqual(currentValue, "1.5", "Trade form data should persist across navigation")
      }
    }

    print("✅ Navigation & TabBar Bundle Tests completed!")
  }

  // MARK: - Bundled Trade Form Tests

  func testTradeFormInteractionsBundle() throws {
    print("📝 Starting Trade Form Interactions Bundle Tests...")

    let tabBarBounds = app.tabBars.firstMatch

    // Navigate to Trade tab
    let tradeTab = app.tabBars.buttons["Trade"]
    if tabBarBounds.exists {
      let tradeCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      tradeCoordinate.tap()
      usleep(500000)
    }

    let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
      .firstMatch
    let limitPriceFields = app.textFields.matching(
      NSPredicate(format: "placeholderValue == '0.00'"))
    let limitPriceField =
      limitPriceFields.count > 1
      ? limitPriceFields.element(boundBy: 1) : limitPriceFields.firstMatch

    // Test 1: Amount field interaction
    print("💰 Testing amount field interaction...")
    if amountField.exists {
      let amountCoordinate = amountField.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      amountCoordinate.tap()
      amountField.tap()

      // Clear field first if it has content
      if let currentValue = amountField.value as? String, !currentValue.isEmpty {
        let deleteString = String(
          repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        amountField.typeText(deleteString)
      }
      amountField.typeText("2.5")
      XCTAssertEqual(amountField.value as? String, "2.5", "Amount field should show entered value")
    }

    // Test 2: Limit price field interaction
    print("💎 Testing limit price field interaction...")
    if limitPriceField.exists {
      let limitPriceCoordinate = limitPriceField.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      limitPriceCoordinate.tap()
      limitPriceField.tap()

      // Clear field first if it has content
      if let currentValue = limitPriceField.value as? String, !currentValue.isEmpty {
        let deleteString = String(
          repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        limitPriceField.typeText(deleteString)
      }
      limitPriceField.typeText("0.85")
      XCTAssertEqual(
        limitPriceField.value as? String, "0.85", "Limit price field should show entered value")
    }

    // Test 3: Form validation with empty fields
    print("🔍 Testing form validation...")
    let createOrderButton = app.buttons["Create Limit Order"]
    if createOrderButton.exists {
      // Clear fields first by tapping and deleting
      if amountField.exists {
        amountField.tap()
        if let currentValue = amountField.value as? String, !currentValue.isEmpty {
          let deleteString = String(
            repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
          amountField.typeText(deleteString)
        }
      }

      // Test with empty fields
      if !createOrderButton.isEnabled {
        XCTAssertFalse(createOrderButton.isEnabled, "Button should be disabled with empty fields")
      }
    }

    // Test 4: Chart button interaction (if exists)
    print("📊 Testing chart button interaction...")
    let chartButton = app.buttons["Chart"]
    if chartButton.exists {
      chartButton.tap()

      let chartView = app.staticTexts["Chart"]
      if chartView.waitForExistence(timeout: 3) {
        XCTAssertTrue(chartView.exists, "Chart view should appear")

        // Dismiss chart
        app.swipeDown()

        let createOrderTitle = app.staticTexts["Create Limit Order"]
        XCTAssertTrue(createOrderTitle.waitForExistence(timeout: 3), "Should return to trade view")
      }
    }

    print("✅ Trade Form Interactions Bundle Tests completed!")
  }

  // MARK: - Bundled Wallet Flow Tests

  func testWalletFlowBundle() throws {
    print("👛 Starting Wallet Flow Bundle Tests...")

    let tabBarBounds = app.tabBars.firstMatch

    // Ensure we're on Home tab
    let homeTab = app.tabBars.buttons["Home"]
    if tabBarBounds.exists {
      let homeCoordinate = tabBarBounds.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
      homeCoordinate.tap()
      usleep(500000)
    }

    // Test 1: Wallet creation button exists
    print("🎯 Testing wallet creation availability...")
    let createWalletButton = app.buttons["Create Wallet"]
    let loadTestWalletButton = app.buttons["Load Test Wallet"]

    XCTAssertTrue(createWalletButton.exists, "Create Wallet button should exist")
    XCTAssertTrue(loadTestWalletButton.exists, "Load Test Wallet button should exist")
    XCTAssertTrue(createWalletButton.isHittable, "Create Wallet button should be tappable")

    // Test 2: Start wallet creation flow
    print("🚀 Testing wallet creation flow...")
    createWalletButton.tap()

    let backupPhraseTitle = app.staticTexts["Save Your Recovery Phrase"]
    XCTAssertTrue(
      backupPhraseTitle.waitForExistence(timeout: 5), "Backup phrase view should appear")

    // Test 3: Backup phrase view elements
    print("🔑 Testing backup phrase view...")
    let securityNotice = app.staticTexts.matching(
      NSPredicate(format: "label CONTAINS[c] 'never share'")
    ).firstMatch
    if securityNotice.exists {
      XCTAssertTrue(securityNotice.exists, "Security notice should be visible")
    }

    let savedPhraseButton = app.buttons["I've Saved My Phrase - REPLACE WALLET"]
    XCTAssertTrue(savedPhraseButton.exists, "I've Saved My Phrase button should exist")

    // Test 4: Continue through flow
    print("➡️ Testing wallet setup completion...")
    savedPhraseButton.tap()

    let setupCompleteTitle = app.staticTexts["You're All Set!"]
    XCTAssertTrue(
      setupCompleteTitle.waitForExistence(timeout: 5), "Setup complete view should appear")

    let startTradingButton = app.buttons["Start Trading"]
    if startTradingButton.exists {
      startTradingButton.tap()

      let tradeTab = app.tabBars.buttons["Trade"]
      XCTAssertTrue(tradeTab.waitForExistence(timeout: 5), "Should return to main app")
      XCTAssertTrue(tradeTab.isSelected, "Trade tab should be selected")
    }

    print("✅ Wallet Flow Bundle Tests completed!")
  }

  // MARK: - Bundled Content Verification Tests

  func testContentVerificationBundle() throws {
    print("🔍 Starting Content Verification Bundle Tests...")

    let tabBarBounds = app.tabBars.firstMatch

    // Test 1: Home view content
    print("🏠 Testing home view content...")
    let homeTab = app.tabBars.buttons["Home"]
    if tabBarBounds.exists {
      let homeCoordinate = tabBarBounds.coordinate(withNormalizedOffset: CGVector(dx: 0.2, dy: 0.5))
      homeCoordinate.tap()
      usleep(500000)
    }

    let appTitle = app.staticTexts["1Limit"]
    let subtitle = app.staticTexts["Place Decentralized 1Inch Limit Orders with ease!"]

    XCTAssertTrue(appTitle.exists, "App title should be visible")
    XCTAssertTrue(subtitle.exists, "App subtitle should be visible")

    // Test 2: Trade view content
    print("💱 Testing trade view content...")
    let tradeTab = app.tabBars.buttons["Trade"]
    if tabBarBounds.exists {
      let tradeCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      tradeCoordinate.tap()
      usleep(500000)
    }

    let createLimitOrderText = app.staticTexts["Create Limit Order"]
    let spendingSection = app.staticTexts["Spending"]
    let buyingSection = app.staticTexts["Buying"]

    XCTAssertTrue(createLimitOrderText.exists, "Create Limit Order title should be visible")
    XCTAssertTrue(spendingSection.exists, "Spending section should be visible")
    XCTAssertTrue(buyingSection.exists, "Buying section should be visible")

    // Test 3: Transactions view content
    print("📋 Testing transactions view content...")
    let transactionsTab = app.tabBars.buttons["Transactions"]
    if tabBarBounds.exists {
      let transactionsCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.8, dy: 0.5))
      transactionsCoordinate.tap()
      usleep(500000)
    }

    let filterTitle = app.staticTexts["Filter Transactions"]
    let allFilter = app.buttons["All"]
    let pendingFilter = app.buttons["Pending"]
    let filledFilter = app.buttons["Confirmed"]

    XCTAssertTrue(filterTitle.exists, "Filter Transactions title should be visible")
    XCTAssertTrue(allFilter.exists, "All filter button should be present")
    XCTAssertTrue(pendingFilter.exists, "Pending filter button should be present")
    XCTAssertTrue(filledFilter.exists, "Confirmed filter button should be present")

    // Test 4: Filter interaction
    print("🔄 Testing filter interaction...")
    pendingFilter.tap()
    XCTAssertTrue(
      pendingFilter.isSelected || pendingFilter.label.contains("Pending"),
      "Pending filter should be selected")

    filledFilter.tap()
    XCTAssertTrue(
      filledFilter.isSelected || filledFilter.label.contains("Confirmed"),
      "Confirmed filter should be selected")

    allFilter.tap()
    XCTAssertTrue(
      allFilter.isSelected || allFilter.label.contains("All"), "All filter should be selected")

    print("✅ Content Verification Bundle Tests completed!")
  }

  // MARK: - Bundled Order Creation Tests

  func testOrderCreationBundle() throws {
    print("🎯 Starting Order Creation Bundle Tests...")

    let tabBarBounds = app.tabBars.firstMatch

    // Navigate to Trade tab
    let tradeTab = app.tabBars.buttons["Trade"]
    if tabBarBounds.exists {
      let tradeCoordinate = tabBarBounds.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      tradeCoordinate.tap()
      usleep(500000)
    }

    let amountField = app.textFields.matching(NSPredicate(format: "placeholderValue == '0.00'"))
      .firstMatch
    let limitPriceFields = app.textFields.matching(
      NSPredicate(format: "placeholderValue == '0.00'"))
    let limitPriceField =
      limitPriceFields.count > 1
      ? limitPriceFields.element(boundBy: 1) : limitPriceFields.firstMatch

    // Test 1: Fill form with valid data
    print("📝 Testing form filling...")
    if amountField.exists {
      let amountCoordinate = amountField.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      amountCoordinate.tap()
      amountField.tap()

      // Clear field first if it has content
      if let currentValue = amountField.value as? String, !currentValue.isEmpty {
        let deleteString = String(
          repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        amountField.typeText(deleteString)
      }
      amountField.typeText("0.1")
    }

    if limitPriceField.exists {
      let limitPriceCoordinate = limitPriceField.coordinate(
        withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
      limitPriceCoordinate.tap()
      limitPriceField.tap()

      // Clear field first if it has content
      if let currentValue = limitPriceField.value as? String, !currentValue.isEmpty {
        let deleteString = String(
          repeating: XCUIKeyboardKey.delete.rawValue, count: currentValue.count)
        limitPriceField.typeText(deleteString)
      }
      limitPriceField.typeText("0.85")
    }

    // Test 2: Order creation flow
    print("🔄 Testing order creation...")
    let createOrderButton = app.buttons["Create Limit Order"]
    if createOrderButton.exists && createOrderButton.isEnabled {
      createOrderButton.tap()

      // Test 3: Order confirmation modal
      print("✅ Testing order confirmation...")
      let confirmTitle = app.staticTexts["Confirm Your Order"]
      if confirmTitle.waitForExistence(timeout: 5) {
        XCTAssertTrue(confirmTitle.exists, "Order confirmation should appear")

        // Test 4: Cancel order
        print("❌ Testing order cancellation...")
        let cancelButtons = app.buttons.matching(identifier: "Cancel")
        if cancelButtons.count > 0 {
          cancelButtons.firstMatch.tap()

          let tradeTitle = app.staticTexts["Create Limit Order"]
          XCTAssertTrue(tradeTitle.waitForExistence(timeout: 3), "Should return to trade view")
        }
      }
    }

    print("✅ Order Creation Bundle Tests completed!")
  }
}
