//
//  WidgetSyncService.swift
//  1Limit
//
//  Service to sync app data with iOS widget 🔄📱
//

import Foundation
import WidgetKit
import UIKit

// MARK: - Widget Transaction Types (Mirrored from Widget)

/// Widget-specific transaction status (mirrors WidgetDataManager's definition)
enum WidgetTransactionStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case failed = "failed"
    case cancelled = "cancelled"
}

/// Simplified transaction model for widget use (mirrors WidgetDataManager's definition)
struct WidgetTransaction: Codable {
    let id: UUID
    let type: String
    let fromAmount: String
    let fromToken: String
    let toAmount: String
    let toToken: String
    let limitPrice: String
    let status: WidgetTransactionStatus
    let date: Date
    let txHash: String?
}

/// Simplified OHLC data for widget use (mirrors WidgetDataManager's definition)
struct WidgetCandlestickData: Codable, Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    var isBullish: Bool {
        return close >= open
    }
}

// MARK: - Simple Widget Data Manager for Main App

class SimpleWidgetDataManager {
    static let shared = SimpleWidgetDataManager()
    
    private let userDefaults = UserDefaults(suiteName: "group.com.1limit.trading")
    private let positionsKey = "widget_positions"
    private let openOrdersKey = "widget_open_orders"
    private let closedOrdersKey = "widget_closed_orders"
    
    private init() {}
    
    func syncWithMainApp(transactions: [WidgetTransaction], priceService: Any? = nil, chartData: [WidgetCandlestickData]? = nil) {
        guard let encoded = try? JSONEncoder().encode(transactions) else { return }
        userDefaults?.set(encoded, forKey: positionsKey)
        
        // Also sync chart data if provided
        if let chartData = chartData,
           let chartEncoded = try? JSONEncoder().encode(chartData) {
            userDefaults?.set(chartEncoded, forKey: "widget_chart_data")
        }
        
        WidgetCenter.shared.reloadTimelines(ofKind: "1LimitWidget")
    }
    
    func syncOrdersWithMainApp(openOrders: [WidgetTransaction], closedOrders: [WidgetTransaction], chartData: [WidgetCandlestickData]? = nil) {
        // Sync open orders
        if let openEncoded = try? JSONEncoder().encode(openOrders) {
            userDefaults?.set(openEncoded, forKey: openOrdersKey)
        }
        
        // Sync closed orders
        if let closedEncoded = try? JSONEncoder().encode(closedOrders) {
            userDefaults?.set(closedEncoded, forKey: closedOrdersKey)
        }
        
        // Sync chart data if provided
        if let chartData = chartData,
           let chartEncoded = try? JSONEncoder().encode(chartData) {
            userDefaults?.set(chartEncoded, forKey: "widget_chart_data")
        }
        
        // Reload both widgets
        WidgetCenter.shared.reloadTimelines(ofKind: "1LimitWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "LineChartWidget")
    }
}

@MainActor
class WidgetSyncService: ObservableObject {
    private let widgetDataManager = SimpleWidgetDataManager.shared
    private let transactionManager: TransactionManagerProtocol
    private let priceService: PriceService
    private let chartService: ChartDataService
    
    init(transactionManager: TransactionManagerProtocol, priceService: PriceService? = nil, chartService: ChartDataService? = nil) {
        self.transactionManager = transactionManager
        self.priceService = priceService ?? PriceService.shared
        self.chartService = chartService ?? ChartDataService.shared
        
        // Set up automatic syncing
        setupPeriodicSync()
    }
    
    // MARK: - Public Methods
    
    /// Manually sync current app state to widget
    func syncToWidget() {
        // Get open and closed orders
        let openOrders = transactionManager.getLatestOpenOrders(limit: 3)
        let closedOrders = transactionManager.getLatestClosedOrders(limit: 3)
        
        // Convert to widget format
        let widgetOpenOrders = convertToWidgetTransactions(openOrders)
        let widgetClosedOrders = convertToWidgetTransactions(closedOrders)
        
        // Convert chart data for widget
        let widgetChartData = convertToWidgetChartData(chartService.candlestickData)
        
        // Sync with new method
        widgetDataManager.syncOrdersWithMainApp(
            openOrders: widgetOpenOrders,
            closedOrders: widgetClosedOrders,
            chartData: widgetChartData
        )
        
        print("📱 Widget synced: \(openOrders.count) open orders, \(closedOrders.count) closed orders, \(widgetChartData.count) chart points")
    }
    
    /// Convert main app transactions to widget-compatible format
    private func convertToWidgetTransactions(_ transactions: [Transaction]) -> [WidgetTransaction] {
        return transactions.map { transaction in
            WidgetTransaction(
                id: transaction.id,
                type: transaction.type,
                fromAmount: transaction.fromAmount,
                fromToken: transaction.fromToken,
                toAmount: transaction.toAmount,
                toToken: transaction.toToken,
                limitPrice: transaction.limitPrice,
                status: convertToWidgetStatus(transaction.status),
                date: transaction.date,
                txHash: transaction.txHash
            )
        }
    }
    
    /// Convert main app transaction status to widget status
    private func convertToWidgetStatus(_ status: TransactionStatus) -> WidgetTransactionStatus {
        switch status {
        case .pending:
            return .pending
        case .confirmed:
            return .confirmed
        case .failed:
            return .failed
        case .cancelled:
            return .cancelled
        }
    }
    
    /// Convert chart data for widget use
    private func convertToWidgetChartData(_ chartData: [CandlestickData]) -> [WidgetCandlestickData] {
        return chartData.map { candle in
            WidgetCandlestickData(
                timestamp: candle.timestamp,
                open: candle.open,
                high: candle.high,
                low: candle.low,
                close: candle.close,
                volume: candle.volume
            )
        }
    }
    
    /// Sync after new transaction is created
    func syncAfterTransactionUpdate() {
        Task {
            // Wait a moment for transaction to be persisted
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            
            // Fetch fresh chart data for 5-minute timeframe
            await chartService.fetchChartData(fromToken: "WMATIC", toToken: "USDC", timeframe: .fiveMinutes)
            
            syncToWidget()
        }
    }
    
    /// Sync when app enters background
    func syncOnBackground() {
        syncToWidget()
    }
    
    /// Sync when app becomes active
    func syncOnForeground() {
        syncToWidget()
    }
    
    // MARK: - Private Methods
    
    private func setupPeriodicSync() {
        // Sync every 5 minutes when app is active
        Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            Task { @MainActor in
                // Fetch fresh chart data
                await self?.chartService.fetchChartData(fromToken: "WMATIC", toToken: "USDC", timeframe: .fiveMinutes)
                self?.syncToWidget()
            }
        }
    }
}

// MARK: - Integration with Transaction Manager

extension WidgetSyncService {
    
    /// Called when a new transaction is added
    func handleNewTransaction(_ transaction: Transaction) {
        syncAfterTransactionUpdate()
    }
    
    /// Called when transaction status changes
    func handleTransactionStatusChange(_ transaction: Transaction) {
        syncAfterTransactionUpdate()
    }
    
    /// Called when transactions are loaded from persistence
    func handleTransactionsLoaded(_ transactions: [Transaction]) {
        syncToWidget()
    }
}

// MARK: - App Lifecycle Integration

extension WidgetSyncService {
    
    /// Set up app lifecycle observers
    func setupAppLifecycleObservers() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncOnBackground()
        }
        
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.syncOnForeground()
        }
    }
}

// MARK: - Factory

class WidgetSyncServiceFactory {
    
    @MainActor static func createForProduction() -> WidgetSyncService {
        let transactionManager = TransactionManager()
        let priceService = PriceService.shared
        return WidgetSyncService(transactionManager: transactionManager, priceService: priceService)
    }
    
    @MainActor static func createForTesting() -> WidgetSyncService {
        let transactionManager = MockTransactionManager()
        let priceService = PriceService.shared
        return WidgetSyncService(transactionManager: transactionManager, priceService: priceService)
    }
}

// MARK: - Mock Transaction Manager for Testing

class MockTransactionManager: TransactionManagerProtocol {
    private var transactions: [Transaction] = []
    
    func getAllTransactions() -> [Transaction] {
        return transactions
    }
    
    func getFilteredTransactions(by filter: String) -> [Transaction] {
        return transactions
    }
    
    func addTransaction(_ transaction: Transaction) {
        transactions.append(transaction)
    }
    
    func getLatestOpenOrders(limit: Int) -> [Transaction] {
        return transactions.filter { $0.status == .pending }.prefix(limit).map { $0 }
    }
    
    func getLatestClosedOrders(limit: Int) -> [Transaction] {
        return transactions.filter { $0.status != .pending }.prefix(limit).map { $0 }
    }
    
    var isLoading: Bool = false
    var errorMessage: String?
    
    func refreshTransactions() async {
        // Mock implementation
    }
}

// TransactionManager already conforms to TransactionManagerProtocol - no extension needed