//
//  WidgetSyncService.swift
//  1Limit
//
//  Service to sync app data with iOS widget 🔄📱
//

import Foundation
import WidgetKit

@MainActor
class WidgetSyncService: ObservableObject {
    private let widgetDataManager = WidgetDataManager.shared
    private let transactionManager: TransactionManagerProtocol
    private let priceService: PriceService
    
    init(transactionManager: TransactionManagerProtocol, priceService: PriceService = .shared) {
        self.transactionManager = transactionManager
        self.priceService = priceService
        
        // Set up automatic syncing
        setupPeriodicSync()
    }
    
    // MARK: - Public Methods
    
    /// Manually sync current app state to widget
    func syncToWidget() {
        let transactions = transactionManager.getAllTransactions()
        widgetDataManager.syncWithMainApp(transactions: transactions, priceService: priceService)
        
        print("📱 Widget synced with \(transactions.count) transactions")
    }
    
    /// Sync after new transaction is created
    func syncAfterTransactionUpdate() {
        Task {
            // Wait a moment for transaction to be persisted
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
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
    
    static func createForProduction() -> WidgetSyncService {
        let transactionManager = TransactionManagerFactory.createProduction()
        let priceService = PriceService.shared
        return WidgetSyncService(transactionManager: transactionManager, priceService: priceService)
    }
    
    static func createForTesting() -> WidgetSyncService {
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
    
    var isLoading: Bool = false
    var errorMessage: String?
    
    func refreshTransactions() async {
        // Mock implementation
    }
}

extension TransactionManager: TransactionManagerProtocol {
    func getAllTransactions() -> [Transaction] {
        return transactions
    }
}