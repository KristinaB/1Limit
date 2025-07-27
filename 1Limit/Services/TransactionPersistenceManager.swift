//
//  TransactionPersistenceManager.swift
//  1Limit
//
//  File-based transaction persistence for app reload persistence
//

import Foundation

/// Protocol for transaction persistence operations
protocol TransactionPersistenceProtocol {
    func saveTransaction(_ transaction: Transaction) async throws
    func loadTransactions() async throws -> [Transaction]
    func updateTransaction(_ transaction: Transaction) async throws
    func deleteTransaction(id: UUID) async throws
    func deleteAllTransactions() async throws
}

/// File-based transaction persistence manager
class TransactionPersistenceManager: TransactionPersistenceProtocol {
    
    // MARK: - Configuration
    
    private let fileName = "transactions.json"
    private let fileManager = FileManager.default
    
    // MARK: - File URL
    
    private var fileURL: URL {
        let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsPath.appendingPathComponent(fileName)
    }
    
    // MARK: - Persistence Operations
    
    /// Save a new transaction or update existing one
    func saveTransaction(_ transaction: Transaction) async throws {
        var transactions = try await loadTransactions()
        
        // Remove existing transaction with same ID if present
        transactions.removeAll { $0.id == transaction.id }
        
        // Add the transaction
        transactions.append(transaction)
        
        // Sort by creation date (newest first)
        transactions.sort { $0.createdAt > $1.createdAt }
        
        try await saveTransactions(transactions)
    }
    
    /// Load all transactions from file
    func loadTransactions() async throws -> [Transaction] {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PersistenceError.managerDeallocated)
                    return
                }
                
                do {
                    // Return empty array if file doesn't exist
                    guard self.fileManager.fileExists(atPath: self.fileURL.path) else {
                        continuation.resume(returning: [])
                        return
                    }
                    
                    let data = try Data(contentsOf: self.fileURL)
                    let decoder = JSONDecoder()
                    decoder.dateDecodingStrategy = .iso8601
                    let transactions = try decoder.decode([Transaction].self, from: data)
                    continuation.resume(returning: transactions)
                } catch {
                    continuation.resume(throwing: PersistenceError.loadFailed(error))
                }
            }
        }
    }
    
    /// Update an existing transaction
    func updateTransaction(_ transaction: Transaction) async throws {
        var transactions = try await loadTransactions()
        
        // Find and replace the transaction
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else {
            throw PersistenceError.transactionNotFound(transaction.id)
        }
        
        transactions[index] = transaction
        
        // Sort by creation date (newest first)
        transactions.sort { $0.createdAt > $1.createdAt }
        
        try await saveTransactions(transactions)
    }
    
    /// Delete a specific transaction
    func deleteTransaction(id: UUID) async throws {
        var transactions = try await loadTransactions()
        
        // Remove the transaction
        let initialCount = transactions.count
        transactions.removeAll { $0.id == id }
        
        guard transactions.count < initialCount else {
            throw PersistenceError.transactionNotFound(id)
        }
        
        try await saveTransactions(transactions)
    }
    
    /// Delete all transactions (for testing/reset)
    func deleteAllTransactions() async throws {
        try await saveTransactions([])
    }
    
    // MARK: - Private Helpers
    
    private func saveTransactions(_ transactions: [Transaction]) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            Task.detached { [weak self] in
                guard let self = self else {
                    continuation.resume(throwing: PersistenceError.managerDeallocated)
                    return
                }
                
                do {
                    let encoder = JSONEncoder()
                    encoder.dateEncodingStrategy = .iso8601
                    let data = try encoder.encode(transactions)
                    try data.write(to: self.fileURL, options: .atomic)
                    continuation.resume()
                } catch {
                    continuation.resume(throwing: PersistenceError.saveFailed(error))
                }
            }
        }
    }
}

// MARK: - Error Handling

enum PersistenceError: Error, LocalizedError {
    case saveFailed(Error)
    case loadFailed(Error)
    case transactionNotFound(UUID)
    case managerDeallocated
    
    var errorDescription: String? {
        switch self {
        case .saveFailed(let error):
            return "Failed to save transactions: \(error.localizedDescription)"
        case .loadFailed(let error):
            return "Failed to load transactions: \(error.localizedDescription)"
        case .transactionNotFound(let id):
            return "Transaction not found: \(id.uuidString)"
        case .managerDeallocated:
            return "Transaction manager was deallocated"
        }
    }
}

// MARK: - Mock Implementation for Testing

/// Mock persistence manager for unit tests
class MockTransactionPersistenceManager: TransactionPersistenceProtocol {
    private var transactions: [Transaction] = []
    var shouldThrowError = false
    var errorToThrow: Error = PersistenceError.saveFailed(NSError(domain: "test", code: 1))
    
    func saveTransaction(_ transaction: Transaction) async throws {
        if shouldThrowError { throw errorToThrow }
        
        // Remove existing transaction with same ID
        transactions.removeAll { $0.id == transaction.id }
        transactions.append(transaction)
        transactions.sort { $0.createdAt > $1.createdAt }
    }
    
    func loadTransactions() async throws -> [Transaction] {
        if shouldThrowError { throw errorToThrow }
        return transactions
    }
    
    func updateTransaction(_ transaction: Transaction) async throws {
        if shouldThrowError { throw errorToThrow }
        
        guard let index = transactions.firstIndex(where: { $0.id == transaction.id }) else {
            throw PersistenceError.transactionNotFound(transaction.id)
        }
        
        transactions[index] = transaction
        transactions.sort { $0.createdAt > $1.createdAt }
    }
    
    func deleteTransaction(id: UUID) async throws {
        if shouldThrowError { throw errorToThrow }
        
        let initialCount = transactions.count
        transactions.removeAll { $0.id == id }
        
        guard transactions.count < initialCount else {
            throw PersistenceError.transactionNotFound(id)
        }
    }
    
    func deleteAllTransactions() async throws {
        if shouldThrowError { throw errorToThrow }
        transactions.removeAll()
    }
    
    // Test helpers
    func setTransactions(_ newTransactions: [Transaction]) {
        transactions = newTransactions
    }
    
    func getTransactionCount() -> Int {
        return transactions.count
    }
}