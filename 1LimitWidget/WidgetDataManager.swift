//
//  WidgetDataManager.swift
//  1Limit
//
//  Shared data manager for app and widget communication 🔄✨
//

import Foundation
import WidgetKit
import Charts
import SwiftUI

// MARK: - Shared Models for Widget
// Models are now defined in Models/WidgetModels.swift to avoid duplication

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.1limit.trading")
    private let positionsKey = "widget_positions"
    private let priceDataKey = "widget_price_data"
    private let portfolioValueKey = "widget_portfolio_value"
    private let lastUpdateKey = "widget_last_update"
    private let chartDataKey = "widget_chart_data"
    private let lineChartDataKey = "widget_line_chart_data"
    private let openOrdersKey = "widget_open_orders"
    private let closedOrdersKey = "widget_closed_orders"
    
    private init() {}
    
    // MARK: - Data Loading (Widget Side)
    
    func loadPositions() -> [WidgetPosition] {
        guard let data = userDefaults?.data(forKey: positionsKey),
              let positions = try? JSONDecoder().decode([WidgetPosition].self, from: data) else {
            return samplePositions // Fallback to sample data
        }
        return positions
    }
    
    func loadOpenOrders() -> [WidgetTransaction] {
        guard let data = userDefaults?.data(forKey: openOrdersKey),
              let orders = try? JSONDecoder().decode([WidgetTransaction].self, from: data) else {
            return []
        }
        return orders
    }
    
    func loadClosedOrders() -> [WidgetTransaction] {
        guard let data = userDefaults?.data(forKey: closedOrdersKey),
              let orders = try? JSONDecoder().decode([WidgetTransaction].self, from: data) else {
            return []
        }
        return orders
    }
    
    func loadRecentPriceData() -> [PricePoint] {
        guard let data = userDefaults?.data(forKey: priceDataKey),
              let priceData = try? JSONDecoder().decode([PricePoint].self, from: data) else {
            return samplePriceData // Fallback to sample data
        }
        return priceData
    }
    
    func loadChartData() -> [WidgetCandlestickData] {
        print("🔍 Widget loading chart data...")
        
        guard let data = userDefaults?.data(forKey: chartDataKey) else {
            print("❌ No chart data found in UserDefaults, using sample data")
            return sampleChartData
        }
        
        do {
            let chartData = try JSONDecoder().decode([WidgetCandlestickData].self, from: data)
            print("✅ Successfully loaded \(chartData.count) chart data points")
            return chartData
        } catch {
            print("❌ Failed to decode chart data: \(error), using sample data")
            return sampleChartData
        }
    }
    
    func loadLineChartData() -> [PricePoint] {
        print("🔍 Widget loading line chart data...")
        
        guard let data = userDefaults?.data(forKey: lineChartDataKey) else {
            print("❌ No line chart data found in UserDefaults, using sample data")
            return generateSampleLineChartData()
        }
        
        do {
            let lineData = try JSONDecoder().decode([PricePoint].self, from: data)
            print("✅ Successfully loaded \(lineData.count) line chart data points")
            return lineData
        } catch {
            print("❌ Failed to decode line chart data: \(error), using sample data")
            return generateSampleLineChartData()
        }
    }
    
    func calculateTotalPortfolioValue() -> Double {
        return userDefaults?.double(forKey: portfolioValueKey) ?? 125.50
    }
    
    func getLastUpdateTime() -> Date {
        let timestamp = userDefaults?.double(forKey: lastUpdateKey) ?? Date().timeIntervalSince1970
        return Date(timeIntervalSince1970: timestamp)
    }
    
    // MARK: - Data Saving (App Side)
    
    func updatePositions(_ positions: [WidgetPosition]) {
        guard let encoded = try? JSONEncoder().encode(positions) else { return }
        userDefaults?.set(encoded, forKey: positionsKey)
        updateTimestamp()
        reloadWidgets()
    }
    
    func updatePriceData(_ priceData: [PricePoint]) {
        guard let encoded = try? JSONEncoder().encode(priceData) else { return }
        userDefaults?.set(encoded, forKey: priceDataKey)
        updateTimestamp()
        reloadWidgets()
    }
    
    func updateChartData(_ chartData: [WidgetCandlestickData]) {
        guard let encoded = try? JSONEncoder().encode(chartData) else { return }
        userDefaults?.set(encoded, forKey: chartDataKey)
        updateTimestamp()
        reloadWidgets()
    }
    
    func updatePortfolioValue(_ value: Double) {
        userDefaults?.set(value, forKey: portfolioValueKey)
        updateTimestamp()
        reloadWidgets()
    }
    
    func updateLineChartData(_ lineData: [PricePoint]) {
        guard let encoded = try? JSONEncoder().encode(lineData) else { return }
        userDefaults?.set(encoded, forKey: lineChartDataKey)
        updateTimestamp()
        reloadWidgets()
    }
    
    private func updateTimestamp() {
        userDefaults?.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "1LimitWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "LineChartWidget")
    }
    
    /// Update line chart data from 1inch API
    func updateLineChartData() async {
        // This would be called from the main app to fetch fresh data
        // For now, we'll generate sample data
        let sampleData = generateSampleLineChartData()
        updateLineChartData(sampleData)
    }
    
    // MARK: - Data Conversion (App -> Widget)
    
    func convertTransactionsToWidgetPositions(_ transactions: [WidgetTransaction]) -> [WidgetPosition] {
        return transactions.compactMap { transaction in
            let symbol = "\(transaction.fromToken)/\(transaction.toToken)"
            let amount = Double(transaction.fromAmount) ?? 0
            let value = amount * (getTokenPrice(transaction.fromToken) ?? 0)
            let status = convertTransactionStatus(transaction.status)
            
            return WidgetPosition(
                symbol: symbol,
                amount: amount,
                value: value,
                status: status
            )
        }
    }
    
    private func convertTransactionStatus(_ status: WidgetTransactionStatus) -> PositionStatus {
        switch status {
        case .pending:
            return .pending
        case .confirmed:
            return .filled
        case .cancelled:
            return .cancelled
        case .failed:
            return .failed
        }
    }
    
    private func getTokenPrice(_ token: String) -> Double? {
        // Get price from PriceService or cached data
        switch token.uppercased() {
        case "WMATIC", "MATIC":
            return 0.45 // Example price
        case "USDC":
            return 1.0
        default:
            return nil
        }
    }
}

// MARK: - App Integration Extensions

extension WidgetDataManager {
    
    /// Update widget data from main app transactions
    func syncWithMainApp(transactions: [WidgetTransaction], priceService: Any? = nil, chartData: [WidgetCandlestickData]? = nil) {
        // Convert transactions to widget positions
        let positions = convertTransactionsToWidgetPositions(transactions)
        updatePositions(positions)
        
        // Calculate total portfolio value
        let totalValue = positions.reduce(0) { $0 + $1.value }
        updatePortfolioValue(totalValue)
        
        // Update chart data (use provided data or generate sample)
        if let chartData = chartData {
            updateChartData(chartData)
        } else {
            let sampleChart = generateSampleChartData()
            updateChartData(sampleChart)
        }
        
        // Generate sample price data (in real app, use actual price history)
        let priceData = generateRecentPriceData()
        updatePriceData(priceData)
    }
    
    private func generateRecentPriceData() -> [PricePoint] {
        let now = Date()
        let basePrice = 0.45 // WMATIC price
        
        return (0..<24).map { hour in
            let timestamp = now.addingTimeInterval(-Double(hour) * 3600)
            let variation = Double.random(in: -0.05...0.05)
            let price = basePrice + variation
            
            return PricePoint(
                timestamp: timestamp,
                price: max(0.1, price) // Ensure positive price
            )
        }.reversed()
    }
    
    private func generateSampleChartData() -> [WidgetCandlestickData] {
        return sampleChartData
    }
    
    private func generateSampleLineChartData() -> [PricePoint] {
        let now = Date()
        let basePrice = 0.45 // WMATIC price
        
        // Generate 24 hourly data points (24H period)
        return (0..<24).map { hour in
            let timestamp = now.addingTimeInterval(-Double(hour) * 3600) // 1-hour intervals
            let variation = Double.random(in: -0.05...0.05)
            let price = basePrice + variation
            
            return PricePoint(
                timestamp: timestamp,
                price: max(0.1, price) // Ensure positive price
            )
        }.reversed()
    }
}

// MARK: - Live Activity Support (Future Enhancement)

extension WidgetDataManager {
    
    /// Prepare data for Live Activities (iOS 16.1+)
    func prepareLiveActivityData() -> [String: Any] {
        let positions = loadPositions()
        let totalValue = calculateTotalPortfolioValue()
        
        return [
            "totalValue": totalValue,
            "activePositions": positions.count,
            "pendingOrders": positions.filter { $0.status == .pending }.count,
            "lastUpdate": getLastUpdateTime().timeIntervalSince1970
        ]
    }
}

// MARK: - Debug Helpers

extension WidgetDataManager {
    
    func clearAllData() {
        userDefaults?.removeObject(forKey: positionsKey)
        userDefaults?.removeObject(forKey: priceDataKey)
        userDefaults?.removeObject(forKey: portfolioValueKey)
        userDefaults?.removeObject(forKey: lastUpdateKey)
        userDefaults?.removeObject(forKey: chartDataKey)
        userDefaults?.removeObject(forKey: lineChartDataKey)
        reloadWidgets()
    }
    
    func populateWithSampleData() {
        updatePositions(samplePositions)
        updatePriceData(samplePriceData)
        updateChartData(sampleChartData)
        updateLineChartData(generateSampleLineChartData())
        updatePortfolioValue(125.50)
    }
}

