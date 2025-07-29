//
//  TransferableToken.swift
//  1Limit
//
//  Token model for send/transfer functionality
//

import Foundation

/// Represents a token that can be transferred
struct TransferableToken: Identifiable, Equatable {
    let id = UUID()
    let symbol: String
    let name: String
    let contractAddress: String?  // nil for native MATIC
    let decimals: Int
    let balance: String
    let balanceFormatted: String
    let usdValue: String?
    let isNative: Bool
    
    /// Create native MATIC token
    static func matic(balance: String, balanceFormatted: String, usdValue: String?) -> TransferableToken {
        return TransferableToken(
            symbol: "MATIC",
            name: "Polygon",
            contractAddress: nil,
            decimals: 18,
            balance: balance,
            balanceFormatted: balanceFormatted,
            usdValue: usdValue,
            isNative: true
        )
    }
    
    /// Create ERC-20 token
    static func erc20(
        symbol: String,
        name: String,
        contractAddress: String,
        decimals: Int,
        balance: String,
        balanceFormatted: String,
        usdValue: String?
    ) -> TransferableToken {
        return TransferableToken(
            symbol: symbol,
            name: name,
            contractAddress: contractAddress,
            decimals: decimals,
            balance: balance,
            balanceFormatted: balanceFormatted,
            usdValue: usdValue,
            isNative: false
        )
    }
    
    /// Display name for UI
    var displayName: String {
        return "\(symbol) (\(name))"
    }
    
    /// Contract address for display (shortened)
    var displayAddress: String? {
        guard let address = contractAddress else { return nil }
        guard address.count >= 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
}

/// Transfer data structure
struct SendTransaction {
    let id = UUID()
    let fromAddress: String
    let toAddress: String
    let token: TransferableToken
    let amount: String
    let amountWei: String  // Amount in smallest unit (wei for MATIC, token units for ERC-20)
    let gasEstimate: String?
    let gasCostUSD: String?
    let createdAt = Date()
    
    /// Total cost including gas (for native transfers only)
    var totalCostFormatted: String? {
        guard token.isNative,
              let gasEst = gasEstimate,
              let amountDouble = Double(amount),
              let gasDouble = Double(gasEst) else { return nil }
        
        let total = amountDouble + gasDouble
        return String(format: "%.6f \(token.symbol)", total)
    }
}