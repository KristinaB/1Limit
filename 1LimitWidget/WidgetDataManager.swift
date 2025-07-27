//
//  WidgetDataManager.swift
//  1Limit
//
//  Shared data manager for app and widget communication 🔄✨
//

import Foundation
import WidgetKit

class WidgetDataManager {
    static let shared = WidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.1limit.trading")
    private let positionsKey = "widget_positions"
    private let priceDataKey = "widget_price_data"
    private let portfolioValueKey = "widget_portfolio_value"
    private let lastUpdateKey = "widget_last_update"
    
    private init() {}
    
    // MARK: - Data Loading (Widget Side)
    
    func loadPositions() -> [WidgetPosition] {
        guard let data = userDefaults?.data(forKey: positionsKey),
              let positions = try? JSONDecoder().decode([WidgetPosition].self, from: data) else {
            return samplePositions // Fallback to sample data
        }
        return positions
    }
    
    func loadRecentPriceData() -> [PricePoint] {
        guard let data = userDefaults?.data(forKey: priceDataKey),
              let priceData = try? JSONDecoder().decode([PricePoint].self, from: data) else {
            return samplePriceData // Fallback to sample data
        }
        return priceData
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
    
    func updatePortfolioValue(_ value: Double) {
        userDefaults?.set(value, forKey: portfolioValueKey)
        updateTimestamp()
        reloadWidgets()
    }
    
    private func updateTimestamp() {
        userDefaults?.set(Date().timeIntervalSince1970, forKey: lastUpdateKey)
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadTimelines(ofKind: "1LimitWidget")
    }
    
    // MARK: - Data Conversion (App -> Widget)
    
    func convertTransactionsToWidgetPositions(_ transactions: [Transaction]) -> [WidgetPosition] {
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
    
    private func convertTransactionStatus(_ status: TransactionStatus) -> PositionStatus {
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
    func syncWithMainApp(transactions: [Transaction], priceService: PriceService? = nil) {
        // Convert transactions to widget positions
        let positions = convertTransactionsToWidgetPositions(transactions)
        updatePositions(positions)
        
        // Calculate total portfolio value
        let totalValue = positions.reduce(0) { $0 + $1.value }
        updatePortfolioValue(totalValue)
        
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
        reloadWidgets()
    }
    
    func populateWithSampleData() {
        updatePositions(samplePositions)
        updatePriceData(samplePriceData)
        updatePortfolioValue(125.50)
    }
}