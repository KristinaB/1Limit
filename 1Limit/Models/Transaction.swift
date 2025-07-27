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
    
    // USD Values
    let fromAmountUSD: Double?
    let toAmountUSD: Double?
    let gasFeeUSD: Double?
    let limitPriceUSD: Double?
    let totalCostUSD: Double?
    
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
        createdAt: Date = Date(),
        fromAmountUSD: Double? = nil,
        toAmountUSD: Double? = nil,
        gasFeeUSD: Double? = nil,
        limitPriceUSD: Double? = nil,
        totalCostUSD: Double? = nil
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
        self.fromAmountUSD = fromAmountUSD
        self.toAmountUSD = toAmountUSD
        self.gasFeeUSD = gasFeeUSD
        self.limitPriceUSD = limitPriceUSD
        self.totalCostUSD = totalCostUSD
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
            createdAt: self.createdAt,
            fromAmountUSD: self.fromAmountUSD,
            toAmountUSD: self.toAmountUSD,
            gasFeeUSD: self.gasFeeUSD,
            limitPriceUSD: self.limitPriceUSD,
            totalCostUSD: self.totalCostUSD
        )
    }
    
    /// Create a new transaction with updated USD values
    func withUpdatedUSDValues(
        fromAmountUSD: Double? = nil,
        toAmountUSD: Double? = nil,
        gasFeeUSD: Double? = nil,
        limitPriceUSD: Double? = nil,
        totalCostUSD: Double? = nil
    ) -> Transaction {
        Transaction(
            id: self.id,
            type: self.type,
            fromAmount: self.fromAmount,
            fromToken: self.fromToken,
            toAmount: self.toAmount,
            toToken: self.toToken,
            limitPrice: self.limitPrice,
            status: self.status,
            date: self.date,
            txHash: self.txHash,
            blockNumber: self.blockNumber,
            gasUsed: self.gasUsed,
            gasPrice: self.gasPrice,
            lastPolledAt: self.lastPolledAt,
            createdAt: self.createdAt,
            fromAmountUSD: fromAmountUSD ?? self.fromAmountUSD,
            toAmountUSD: toAmountUSD ?? self.toAmountUSD,
            gasFeeUSD: gasFeeUSD ?? self.gasFeeUSD,
            limitPriceUSD: limitPriceUSD ?? self.limitPriceUSD,
            totalCostUSD: totalCostUSD ?? self.totalCostUSD
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
    
    /// Calculate USD values from current token prices
    func calculateUSDValues(using priceService: PriceService) async -> Transaction {
        var fromUSD: Double? = nil
        var toUSD: Double? = nil
        var limitUSD: Double? = nil
        var gasUSD: Double? = nil
        var totalUSD: Double? = nil
        
        // Calculate from amount USD
        let fromPrice = await MainActor.run { priceService.getPrice(for: fromToken) }
        print("🔍 USD Calc - fromToken: \(fromToken), price: \(fromPrice?.usdPrice ?? 0), amount: \(fromAmount)")
        if let fromPrice = fromPrice, let fromDouble = Double(fromAmount) {
            fromUSD = fromDouble * fromPrice.usdPrice
            print("✅ USD Calc - fromUSD: \(fromUSD ?? 0)")
        } else {
            print("❌ USD Calc - Failed to get fromPrice or parse fromAmount")
        }
        
        // Calculate to amount USD  
        let toPrice = await MainActor.run { priceService.getPrice(for: toToken) }
        if let toPrice = toPrice, let toDouble = Double(toAmount) {
            toUSD = toDouble * toPrice.usdPrice
        }
        
        // Calculate limit price USD (rate * from token price)
        let limitFromPrice = await MainActor.run { priceService.getPrice(for: fromToken) }
        if let limitFromPrice = limitFromPrice, let limitDouble = Double(limitPrice) {
            limitUSD = limitDouble * limitFromPrice.usdPrice
        }
        
        // Calculate gas fee USD (if transaction is confirmed)
        if let gasUsedStr = gasUsed,
           let gasPriceStr = gasPrice,
           let gasUsedValue = Double(gasUsedStr),
           let gasPriceValue = Double(gasPriceStr) {
            let maticPrice = await MainActor.run { priceService.getPrice(for: "WMATIC") }
            if let maticPrice = maticPrice {
                // Convert wei to MATIC (1 MATIC = 10^18 wei)
                let gasFeeInMatic = (gasUsedValue * gasPriceValue) / 1e18
                gasUSD = gasFeeInMatic * maticPrice.usdPrice
            }
        }
        
        // Calculate total cost USD (from amount + gas fee)
        if let fromValue = fromUSD, let gasValue = gasUSD {
            totalUSD = fromValue + gasValue
        } else if let fromValue = fromUSD {
            totalUSD = fromValue
        }
        
        let updatedTransaction = withUpdatedUSDValues(
            fromAmountUSD: fromUSD,
            toAmountUSD: toUSD,
            gasFeeUSD: gasUSD,
            limitPriceUSD: limitUSD,
            totalCostUSD: totalUSD
        )
        
        print("💰 USD Values - from: \(updatedTransaction.fromAmountUSD?.description ?? "nil"), to: \(updatedTransaction.toAmountUSD?.description ?? "nil"), limit: \(updatedTransaction.limitPriceUSD?.description ?? "nil")")
        
        return updatedTransaction
    }
    
    /// Formatted USD value strings for UI display
    var formattedFromAmountUSD: String? {
        guard let value = fromAmountUSD else { return nil }
        return String(format: "$%.2f", value)
    }
    
    var formattedToAmountUSD: String? {
        guard let value = toAmountUSD else { return nil }
        return String(format: "$%.2f", value)
    }
    
    var formattedGasFeeUSD: String? {
        guard let value = gasFeeUSD else { return nil }
        return String(format: "$%.2f", value)
    }
    
    var formattedLimitPriceUSD: String? {
        guard let value = limitPriceUSD else { return nil }
        return String(format: "$%.2f", value)
    }
    
    var formattedTotalCostUSD: String? {
        guard let value = totalCostUSD else { return nil }
        return String(format: "$%.2f", value)
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