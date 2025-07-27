//
//  TransactionPollingService.swift
//  1Limit
//
//  Polygon API transaction status polling service with 2min timeout and 5sec intervals
//

import Foundation

/// Protocol for transaction polling operations
protocol TransactionPollingProtocol {
    func startPolling(for transaction: Transaction) async
    func stopPolling(for transactionId: UUID)
    func stopAllPolling()
    var onTransactionUpdate: ((Transaction) -> Void)? { get set }
}

/// Polygon API transaction polling service
@MainActor
class TransactionPollingService: TransactionPollingProtocol {
    
    // MARK: - Configuration
    
    private let polygonApiKey: String
    private let maxPollingDuration: TimeInterval = 120 // 2 minutes
    private let pollInterval: TimeInterval = 5 // 5 seconds
    private let baseURL = "https://api.polygonscan.io/api"
    
    // MARK: - Dependencies
    
    private let persistenceManager: TransactionPersistenceProtocol
    private let urlSession: URLSession
    
    // MARK: - State
    
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]
    var onTransactionUpdate: ((Transaction) -> Void)?
    
    // MARK: - Initialization
    
    init(
        polygonApiKey: String = "YourPolygonAPIKey", // Replace with actual API key
        persistenceManager: TransactionPersistenceProtocol,
        urlSession: URLSession = .shared
    ) {
        self.polygonApiKey = polygonApiKey
        self.persistenceManager = persistenceManager
        self.urlSession = urlSession
    }
    
    // MARK: - Polling Operations
    
    /// Start polling for a specific transaction
    func startPolling(for transaction: Transaction) async {
        // Don't poll if no tx hash or already confirmed/failed
        guard let txHash = transaction.txHash,
              transaction.status == .pending else { return }
        
        // Cancel existing polling for this transaction
        stopPolling(for: transaction.id)
        
        // Create new polling task
        let task = Task<Void, Never> { [weak self] in
            await self?.pollTransaction(transaction, txHash: txHash)
        }
        
        pollingTasks[transaction.id] = task
    }
    
    /// Stop polling for a specific transaction
    func stopPolling(for transactionId: UUID) {
        pollingTasks[transactionId]?.cancel()
        pollingTasks.removeValue(forKey: transactionId)
    }
    
    /// Stop all active polling tasks
    func stopAllPolling() {
        for task in pollingTasks.values {
            task.cancel()
        }
        pollingTasks.removeAll()
    }
    
    // MARK: - Private Polling Logic
    
    private func pollTransaction(_ transaction: Transaction, txHash: String) async {
        let startTime = Date()
        var currentTransaction = transaction
        
        while !Task.isCancelled {
            // Check timeout (2 minutes)
            let elapsed = Date().timeIntervalSince(startTime)
            if elapsed >= maxPollingDuration {
                print("⏰ Polling timeout reached for transaction: \(txHash)")
                break
            }
            
            // Check if enough time has passed since last poll
            if let lastPolled = currentTransaction.lastPolledAt {
                let timeSinceLastPoll = Date().timeIntervalSince(lastPolled)
                if timeSinceLastPoll < pollInterval {
                    let remainingWait = pollInterval - timeSinceLastPoll
                    try? await Task.sleep(nanoseconds: UInt64(remainingWait * 1_000_000_000))
                }
            }
            
            // Poll Polygon API
            do {
                let receipt = try await fetchTransactionReceipt(txHash: txHash)
                
                // Update transaction based on receipt
                let updatedTransaction = await updateTransactionFromReceipt(
                    currentTransaction, 
                    receipt: receipt
                )
                
                // Save updated transaction
                try await persistenceManager.updateTransaction(updatedTransaction)
                
                // Notify observers
                onTransactionUpdate?(updatedTransaction)
                
                // Stop polling if confirmed or failed
                if updatedTransaction.status == .confirmed || updatedTransaction.status == .failed {
                    print("✅ Transaction \(txHash) status: \(updatedTransaction.status.rawValue)")
                    break
                }
                
                currentTransaction = updatedTransaction
                
            } catch {
                print("⚠️ Error polling transaction \(txHash): \(error)")
                
                // Update last polled time even on error to avoid rapid retries
                currentTransaction = currentTransaction.withUpdatedStatus(
                    status: currentTransaction.status,
                    lastPolledAt: Date()
                )
                
                try? await persistenceManager.updateTransaction(currentTransaction)
            }
            
            // Wait before next poll
            try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
        }
        
        // Clean up
        await MainActor.run {
            pollingTasks.removeValue(forKey: transaction.id)
        }
    }
    
    // MARK: - Polygon API Integration
    
    private func fetchTransactionReceipt(txHash: String) async throws -> PolygonTransactionReceipt {
        // Build URL
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "module", value: "transaction"),
            URLQueryItem(name: "action", value: "gettxreceiptstatus"),
            URLQueryItem(name: "txhash", value: txHash),
            URLQueryItem(name: "apikey", value: polygonApiKey)
        ]
        
        guard let url = components.url else {
            throw PollingError.invalidURL
        }
        
        // Make request
        let (data, response) = try await urlSession.data(from: url)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PollingError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PollingError.httpError(httpResponse.statusCode)
        }
        
        // Parse JSON
        let decoder = JSONDecoder()
        let receipt = try decoder.decode(PolygonTransactionReceipt.self, from: data)
        
        return receipt
    }
    
    private func updateTransactionFromReceipt(
        _ transaction: Transaction, 
        receipt: PolygonTransactionReceipt
    ) async -> Transaction {
        let status: TransactionStatus
        
        // Parse Polygon API status
        if receipt.status == "1", let result = receipt.result {
            // API success, check transaction status
            if result.status == "1" {
                status = .confirmed
            } else {
                status = .failed
            }
        } else if receipt.status == "0" {
            // API returned error (transaction not found or pending)
            status = .pending
        } else {
            // Unknown status, keep as pending
            status = .pending
        }
        
        return transaction.withUpdatedStatus(
            status: status,
            blockNumber: receipt.result?.blockNumber,
            gasUsed: receipt.result?.gasUsed,
            gasPrice: receipt.result?.gasPrice,
            lastPolledAt: Date()
        )
    }
}

// MARK: - Error Handling

enum PollingError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int)
    case apiError(String)
    case decodingError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid Polygon API URL"
        case .invalidResponse:
            return "Invalid response from Polygon API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .apiError(let message):
            return "Polygon API error: \(message)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        }
    }
}

// MARK: - Mock Implementation for Testing

/// Mock polling service for unit tests
class MockTransactionPollingService: TransactionPollingProtocol {
    var onTransactionUpdate: ((Transaction) -> Void)?
    private var pollingTransactions: Set<UUID> = []
    var shouldSimulateSuccess = true
    var shouldSimulateError = false
    var mockDelay: TimeInterval = 0.1
    
    func startPolling(for transaction: Transaction) async {
        pollingTransactions.insert(transaction.id)
        
        // Simulate polling delay
        try? await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        guard pollingTransactions.contains(transaction.id) else { return }
        
        if shouldSimulateError {
            // Keep as pending
            let updatedTransaction = transaction.withUpdatedStatus(status: .pending, lastPolledAt: Date())
            onTransactionUpdate?(updatedTransaction)
        } else if shouldSimulateSuccess {
            // Simulate confirmation
            let updatedTransaction = transaction.withUpdatedStatus(
                status: .confirmed,
                blockNumber: "12345678",
                gasUsed: "21000",
                gasPrice: "30000000000"
            )
            onTransactionUpdate?(updatedTransaction)
        }
        
        pollingTransactions.remove(transaction.id)
    }
    
    func stopPolling(for transactionId: UUID) {
        pollingTransactions.remove(transactionId)
    }
    
    func stopAllPolling() {
        pollingTransactions.removeAll()
    }
    
    // Test helpers
    func isPolling(for transactionId: UUID) -> Bool {
        return pollingTransactions.contains(transactionId)
    }
    
    func getPollingCount() -> Int {
        return pollingTransactions.count
    }
}