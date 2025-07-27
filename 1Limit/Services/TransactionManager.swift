//
//  TransactionManager.swift
//  1Limit
//
//  Coordinates transaction persistence and polling for the UI
//

import Foundation
import SwiftUI

/// Main transaction coordinator for the app
@MainActor
class TransactionManager: ObservableObject, TransactionManagerProtocol {
    
    // MARK: - Published Properties
    
    @Published var transactions: [Transaction] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // MARK: - Dependencies
    
    private let persistenceManager: TransactionPersistenceProtocol
    private var pollingService: TransactionPollingProtocol
    
    // MARK: - Initialization
    
    init(
        persistenceManager: TransactionPersistenceProtocol = TransactionPersistenceManager(),
        pollingService: TransactionPollingProtocol? = nil
    ) {
        self.persistenceManager = persistenceManager
        
        // Create polling service with persistence manager if not provided
        if let pollingService = pollingService {
            self.pollingService = pollingService
        } else {
            self.pollingService = TransactionPollingService(
                persistenceManager: persistenceManager
            )
        }
        
        // Set up polling callback
        self.pollingService.onTransactionUpdate = { [weak self] updatedTransaction in
            Task { @MainActor in
                self?.handleTransactionUpdate(updatedTransaction)
            }
        }
        
        // Load transactions on init
        Task {
            await loadTransactions()
            await startPollingForPendingTransactions()
        }
    }
    
    // MARK: - Public Methods
    
    /// Load all transactions from persistence
    func loadTransactions() async {
        isLoading = true
        errorMessage = nil
        
        do {
            // Check for mock data from environment (for UI tests)
            if let mockJSON = ProcessInfo.processInfo.environment["MOCK_TRANSACTIONS_JSON"] {
                print("🧪 Loading mock transactions from environment for UI tests")
                let mockTransactions = try loadMockTransactions(from: mockJSON)
                transactions = mockTransactions
            } else {
                let loadedTransactions = try await persistenceManager.loadTransactions()
                transactions = loadedTransactions
            }
        } catch {
            errorMessage = "Failed to load transactions: \(error.localizedDescription)"
            print("Error loading transactions: \(error)")
        }
        
        isLoading = false
    }
    
    /// Load mock transactions from JSON string (for UI tests)
    private func loadMockTransactions(from jsonString: String) throws -> [Transaction] {
        guard let jsonData = jsonString.data(using: .utf8) else {
            throw NSError(domain: "TransactionManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid mock JSON string"])
        }
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        return try decoder.decode([Transaction].self, from: jsonData)
    }
    
    /// Refresh transactions and restart polling
    func refreshTransactions() async {
        await loadTransactions()
        await startPollingForPendingTransactions()
    }
    
    /// Get filtered transactions by status
    func getFilteredTransactions(by filter: String) -> [Transaction] {
        if filter == "All" {
            return transactions
        }
        
        let targetStatus: TransactionStatus
        switch filter {
        case "Pending":
            targetStatus = .pending
        case "Filled", "Confirmed":
            targetStatus = .confirmed
        case "Failed":
            targetStatus = .failed
        case "Cancelled":
            targetStatus = .cancelled
        default:
            return transactions
        }
        
        return transactions.filter { $0.status == targetStatus }
    }
    
    /// Delete a specific transaction
    func deleteTransaction(_ transaction: Transaction) async {
        do {
            // Stop polling for this transaction
            pollingService.stopPolling(for: transaction.id)
            
            // Remove from persistence
            try await persistenceManager.deleteTransaction(id: transaction.id)
            
            // Update UI
            transactions.removeAll { $0.id == transaction.id }
        } catch {
            errorMessage = "Failed to delete transaction: \(error.localizedDescription)"
        }
    }
    
    // MARK: - TransactionManagerProtocol Methods
    
    /// Get all transactions (for widget sync)
    func getAllTransactions() -> [Transaction] {
        return transactions
    }
    
    /// Add a new transaction (for widget integration)
    func addTransaction(_ transaction: Transaction) {
        // Add to local array
        transactions.append(transaction)
        
        // Persist asynchronously
        Task {
            do {
                try await persistenceManager.saveTransaction(transaction)
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to save transaction: \(error.localizedDescription)"
                }
            }
        }
    }
    
    /// Clear all transactions (for testing/reset)
    func clearAllTransactions() async {
        do {
            // Stop all polling
            pollingService.stopAllPolling()
            
            // Clear persistence
            try await persistenceManager.deleteAllTransactions()
            
            // Update UI
            transactions.removeAll()
        } catch {
            errorMessage = "Failed to clear transactions: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Private Methods
    
    /// Handle transaction updates from polling service
    private func handleTransactionUpdate(_ updatedTransaction: Transaction) {
        // Find and update the transaction in our array
        if let index = transactions.firstIndex(where: { $0.id == updatedTransaction.id }) {
            transactions[index] = updatedTransaction
            
            // Sort by creation date (newest first)
            transactions.sort { $0.createdAt > $1.createdAt }
        }
    }
    
    /// Start polling for all pending transactions that need it
    private func startPollingForPendingTransactions() async {
        for transaction in transactions {
            if transaction.needsPolling {
                await pollingService.startPolling(for: transaction)
            }
        }
    }
}

// MARK: - Factory

/// Factory for creating TransactionManager instances
class TransactionManagerFactory {
    
    @MainActor static func createProduction() -> TransactionManager {
        let persistenceManager = TransactionPersistenceManager()
        let pollingService = TransactionPollingService(
            persistenceManager: persistenceManager
        )
        
        return TransactionManager(
            persistenceManager: persistenceManager,
            pollingService: pollingService
        )
    }
    
    @MainActor static func createTest() -> TransactionManager {
        let mockPersistence = MockTransactionPersistenceManager()
        let mockPolling = MockTransactionPollingService()
        
        return TransactionManager(
            persistenceManager: mockPersistence,
            pollingService: mockPolling
        )
    }
}