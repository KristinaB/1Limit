//
//  Transaction.swift
//  1Limit
//
//  Transaction model for real blockchain transactions with polling support
//

import Foundation

/// Real transaction model replacing MockTransaction
struct Transaction: Identifiable, Codable {
    let id: UUID
    let type: String
    let fromAmount: String
    let fromToken: String
    let toAmount: String
    let toToken: String
    let limitPrice: String
    let status: TransactionStatus
    let date: Date
    let txHash: String?
    let blockNumber: String?
    let gasUsed: String?
    let gasPrice: String?
    let lastPolledAt: Date?
    let createdAt: Date
    
    init(
        id: UUID = UUID(),
        type: String,
        fromAmount: String,
        fromToken: String,
        toAmount: String,
        toToken: String,
        limitPrice: String,
        status: TransactionStatus = .pending,
        date: Date = Date(),
        txHash: String? = nil,
        blockNumber: String? = nil,
        gasUsed: String? = nil,
        gasPrice: String? = nil,
        lastPolledAt: Date? = nil,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.type = type
        self.fromAmount = fromAmount
        self.fromToken = fromToken
        self.toAmount = toAmount
        self.toToken = toToken
        self.limitPrice = limitPrice
        self.status = status
        self.date = date
        self.txHash = txHash
        self.blockNumber = blockNumber
        self.gasUsed = gasUsed
        self.gasPrice = gasPrice
        self.lastPolledAt = lastPolledAt
        self.createdAt = createdAt
    }
    
    /// Create a new transaction with updated status and blockchain data
    func withUpdatedStatus(
        status: TransactionStatus,
        blockNumber: String? = nil,
        gasUsed: String? = nil,
        gasPrice: String? = nil,
        lastPolledAt: Date = Date()
    ) -> Transaction {
        Transaction(
            id: self.id,
            type: self.type,
            fromAmount: self.fromAmount,
            fromToken: self.fromToken,
            toAmount: self.toAmount,
            toToken: self.toToken,
            limitPrice: self.limitPrice,
            status: status,
            date: self.date,
            txHash: self.txHash,
            blockNumber: blockNumber ?? self.blockNumber,
            gasUsed: gasUsed ?? self.gasUsed,
            gasPrice: gasPrice ?? self.gasPrice,
            lastPolledAt: lastPolledAt,
            createdAt: self.createdAt
        )
    }
    
    /// Check if transaction needs polling (pending and within polling window)
    var needsPolling: Bool {
        guard status == .pending,
              let txHash = txHash else { return false }
        
        // Poll for maximum 2 minutes from creation
        let maxPollingDuration: TimeInterval = 120 // 2 minutes
        let timeSinceCreation = Date().timeIntervalSince(createdAt)
        
        return timeSinceCreation < maxPollingDuration
    }
    
    /// Time until next poll (5 second intervals)
    var timeUntilNextPoll: TimeInterval {
        guard let lastPolled = lastPolledAt else { return 0 }
        let pollInterval: TimeInterval = 5 // 5 seconds
        let timeSinceLastPoll = Date().timeIntervalSince(lastPolled)
        return max(0, pollInterval - timeSinceLastPoll)
    }
}

/// Transaction status matching blockchain states
enum TransactionStatus: String, Codable, CaseIterable {
    case pending = "Pending"
    case confirmed = "Confirmed"
    case failed = "Failed"
    case cancelled = "Cancelled"
    
    /// Legacy compatibility with filled status
    static let filled = confirmed
}

/// Polygon API transaction receipt response
struct PolygonTransactionReceipt: Codable {
    let status: String
    let result: PolygonReceiptResult?
    let message: String
}

struct PolygonReceiptResult: Codable {
    let status: String
    let blockNumber: String?
    let gasUsed: String?
    let gasPrice: String?
    let transactionHash: String?
}

/// Transaction creation parameters from order submission
struct TransactionCreationParams {
    let type: String
    let fromAmount: String
    let fromToken: String
    let toAmount: String
    let toToken: String
    let limitPrice: String
    let txHash: String?
    
    func toTransaction() -> Transaction {
        Transaction(
            type: type,
            fromAmount: fromAmount,
            fromToken: fromToken,
            toAmount: toAmount,
            toToken: toToken,
            limitPrice: limitPrice,
            txHash: txHash
        )
    }
}