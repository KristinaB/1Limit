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
    
    private let maxPollingDuration: TimeInterval = 120 // 2 minutes
    private let pollInterval: TimeInterval = 5 // 5 seconds
    private let rpcURL = "https://polygon-bor-rpc.publicnode.com"
    
    // MARK: - Dependencies
    
    private let persistenceManager: TransactionPersistenceProtocol
    private let urlSession: URLSession
    private let priceService: PriceService
    
    // MARK: - State
    
    private var pollingTasks: [UUID: Task<Void, Never>] = [:]
    var onTransactionUpdate: ((Transaction) -> Void)?
    
    // MARK: - Initialization
    
    init(
        persistenceManager: TransactionPersistenceProtocol,
        urlSession: URLSession = .shared,
        priceService: PriceService = .shared
    ) {
        self.persistenceManager = persistenceManager
        self.urlSession = urlSession
        self.priceService = priceService
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
            
            // Poll RPC node
            do {
                let receipt = try await fetchTransactionReceipt(txHash: txHash)
                
                // Update transaction based on receipt (nil means still pending)
                let updatedTransaction: Transaction
                if let receipt = receipt {
                    updatedTransaction = updateTransactionFromReceipt(currentTransaction, receipt: receipt)
                } else {
                    // Still pending, just update last polled time
                    updatedTransaction = currentTransaction.withUpdatedStatus(
                        status: .pending,
                        lastPolledAt: Date()
                    )
                }
                
                // Calculate USD values with current prices
                await priceService.fetchPrices()
                let transactionWithUSD = await updatedTransaction.calculateUSDValues(using: priceService)
                
                // Save updated transaction
                try await persistenceManager.updateTransaction(transactionWithUSD)
                
                // Notify observers
                onTransactionUpdate?(transactionWithUSD)
                
                // Stop polling if confirmed or failed
                if transactionWithUSD.status == .confirmed || transactionWithUSD.status == .failed {
                    print("✅ Transaction \(txHash) status: \(transactionWithUSD.status.rawValue)")
                    break
                }
                
                currentTransaction = transactionWithUSD
                
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
    
    // MARK: - RPC Integration
    
    private func fetchTransactionReceipt(txHash: String) async throws -> RPCTransactionReceipt? {
        guard let url = URL(string: rpcURL) else {
            throw PollingError.invalidURL
        }
        
        // Create RPC request
        let rpcRequest = RPCRequest(
            method: "eth_getTransactionReceipt",
            params: [txHash],
            id: 1
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(rpcRequest)
        
        // Make request
        let (data, response) = try await urlSession.data(for: request)
        
        // Check HTTP response
        guard let httpResponse = response as? HTTPURLResponse else {
            throw PollingError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw PollingError.httpError(httpResponse.statusCode)
        }
        
        // Parse JSON
        let decoder = JSONDecoder()
        
        // Parse RPC response - result can be null for pending transactions
        let rpcResponse = try decoder.decode(RPCResponseOptional.self, from: data)
        
        if let error = rpcResponse.error {
            throw PollingError.apiError(error.message)
        }
        
        return rpcResponse.result
    }
    
    private func updateTransactionFromReceipt(
        _ transaction: Transaction, 
        receipt: RPCTransactionReceipt
    ) -> Transaction {
        let status: TransactionStatus
        
        // Parse RPC receipt status (0x0 = failed, 0x1 = success)
        if let statusHex = receipt.status {
            if statusHex == "0x1" {
                status = .confirmed
            } else {
                status = .failed
            }
        } else {
            // No status means transaction is still pending
            status = .pending
        }
        
        // Convert hex values to decimal strings
        let blockNumber = receipt.blockNumber.flatMap { hexToDecimal($0) }
        let gasUsed = receipt.gasUsed.flatMap { hexToDecimal($0) }
        let gasPrice = receipt.effectiveGasPrice.flatMap { hexToDecimal($0) }
        
        return transaction.withUpdatedStatus(
            status: status,
            blockNumber: blockNumber,
            gasUsed: gasUsed,
            gasPrice: gasPrice,
            lastPolledAt: Date()
        )
    }
    
    /// Convert hex string to decimal string
    private func hexToDecimal(_ hex: String) -> String? {
        let cleanHex = hex.hasPrefix("0x") ? String(hex.dropFirst(2)) : hex
        guard let decimal = UInt64(cleanHex, radix: 16) else { return nil }
        return String(decimal)
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

// MARK: - RPC Data Structures

struct RPCRequest: Codable {
    let jsonrpc: String = "2.0"
    let method: String
    let params: [String]
    let id: Int
}

struct RPCResponse<T: Codable>: Codable {
    let jsonrpc: String
    let id: Int
    let result: T?
    let error: RPCError?
}

struct RPCResponseOptional: Codable {
    let jsonrpc: String
    let id: Int
    let result: RPCTransactionReceipt?
    let error: RPCError?
}

struct RPCError: Codable {
    let code: Int
    let message: String
}

struct RPCTransactionReceipt: Codable {
    let transactionHash: String
    let blockNumber: String?
    let gasUsed: String?
    let effectiveGasPrice: String?
    let status: String?
    let blockHash: String?
    let transactionIndex: String?
    let from: String?
    let to: String?
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