//
//  TokenTransferService.swift
//  1Limit
//
//  Service for handling token transfers (native MATIC and ERC-20)
//

import Foundation
import web3swift
import BigInt

/// Gas estimation result
struct GasEstimationResult {
    let gasEstimate: String      // In MATIC
    let gasCostUSD: String?      // USD value
    let gasLimit: String         // Gas limit in units
    let gasPrice: String         // Gas price in gwei
}

/// Transfer result
struct TransferResult {
    let success: Bool
    let transactionHash: String?
    let error: Error?
}

/// Protocol for token transfer operations
protocol TokenTransferProtocol {
    func estimateGas(for transaction: SendTransaction) async throws -> GasEstimationResult
    func executeSend(_ transaction: SendTransaction) async throws -> Bool
}

/// Token transfer service handling both native and ERC-20 transfers
@MainActor
class TokenTransferService: ObservableObject, TokenTransferProtocol {
    
    // MARK: - Dependencies
    
    private let priceService = PriceService.shared
    private let walletLoader = WalletLoader.shared
    private let nodeURL = "https://polygon-bor-rpc.publicnode.com"
    
    // MARK: - Configuration
    
    private let networkConfig = NetworkConfig(
        name: "Polygon Mainnet",
        nodeURL: "https://polygon-bor-rpc.publicnode.com",
        routerV6: "0x111111125421cA6dc452d289314280a0f8842A65",
        wmatic: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
        usdc: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
        chainID: 137,
        domainName: "1inch Aggregation Router",
        domainVersion: "6"
    )
    
    // MARK: - Transfer Operations
    
    /// Estimate gas fees for a transfer
    func estimateGas(for transaction: SendTransaction) async throws -> GasEstimationResult {
        if transaction.token.isNative {
            return try await estimateNativeTransferGas(transaction)
        } else {
            return try await estimateERC20TransferGas(transaction)
        }
    }
    
    /// Execute a send transaction
    func executeSend(_ transaction: SendTransaction) async throws -> Bool {
        if transaction.token.isNative {
            return try await executeNativeTransfer(transaction)
        } else {
            return try await executeERC20Transfer(transaction)
        }
    }
    
    // MARK: - Native MATIC Transfer
    
    private func estimateNativeTransferGas(_ transaction: SendTransaction) async throws -> GasEstimationResult {
        // Standard gas limit for native transfer is 21,000 units
        let gasLimit = BigUInt(21000)
        
        // Get current gas price
        let gasPrice = try await getCurrentGasPrice()
        
        // Calculate total gas cost in wei
        let gasCostWei = gasLimit * gasPrice
        
        // Convert to MATIC (18 decimals)
        let gasCostMatic = Double(gasCostWei) / 1e18
        let gasCostFormatted = String(format: "%.6f", gasCostMatic)
        
        // Get USD value
        var gasCostUSD: String?
        if let maticPrice = priceService.getPrice(for: "MATIC") {
            let usdValue = gasCostMatic * maticPrice.usdPrice
            gasCostUSD = String(format: "$%.4f", usdValue)
        }
        
        // Convert gas price from wei to gwei for display
        let gasPriceGwei = Double(gasPrice) / 1e9
        
        return GasEstimationResult(
            gasEstimate: gasCostFormatted,
            gasCostUSD: gasCostUSD,
            gasLimit: String(gasLimit),
            gasPrice: String(format: "%.2f", gasPriceGwei)
        )
    }
    
    private func executeNativeTransfer(_ transaction: SendTransaction) async throws -> Bool {
        guard let wallet = await walletLoader.loadWallet() else {
            throw TransferError.noWallet
        }
        
        // This is a simplified implementation
        // In production, you would use web3swift to create and send the transaction
        
        print("🚀 Executing native MATIC transfer:")
        print("   From: \(transaction.fromAddress)")
        print("   To: \(transaction.toAddress)")
        print("   Amount: \(transaction.amount) MATIC")
        print("   Amount Wei: \(transaction.amountWei)")
        
        // Simulate successful transfer for demo
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
        
        return true
    }
    
    // MARK: - ERC-20 Token Transfer
    
    private func estimateERC20TransferGas(_ transaction: SendTransaction) async throws -> GasEstimationResult {
        // ERC-20 transfers typically use around 65,000 gas units
        let gasLimit = BigUInt(65000)
        
        // Get current gas price
        let gasPrice = try await getCurrentGasPrice()
        
        // Calculate total gas cost in wei
        let gasCostWei = gasLimit * gasPrice
        
        // Convert to MATIC (18 decimals)
        let gasCostMatic = Double(gasCostWei) / 1e18
        let gasCostFormatted = String(format: "%.6f", gasCostMatic)
        
        // Get USD value
        var gasCostUSD: String?
        if let maticPrice = priceService.getPrice(for: "MATIC") {
            let usdValue = gasCostMatic * maticPrice.usdPrice
            gasCostUSD = String(format: "$%.4f", usdValue)
        }
        
        // Convert gas price from wei to gwei for display
        let gasPriceGwei = Double(gasPrice) / 1e9
        
        return GasEstimationResult(
            gasEstimate: gasCostFormatted,
            gasCostUSD: gasCostUSD,
            gasLimit: String(gasLimit),
            gasPrice: String(format: "%.2f", gasPriceGwei)
        )
    }
    
    private func executeERC20Transfer(_ transaction: SendTransaction) async throws -> Bool {
        guard let wallet = await walletLoader.loadWallet() else {
            throw TransferError.noWallet
        }
        
        guard let contractAddress = transaction.token.contractAddress else {
            throw TransferError.missingContractAddress
        }
        
        // This is a simplified implementation
        // In production, you would use web3swift to interact with the ERC-20 contract
        
        print("🚀 Executing ERC-20 token transfer:")
        print("   Token: \(transaction.token.symbol)")
        print("   Contract: \(contractAddress)")
        print("   From: \(transaction.fromAddress)")
        print("   To: \(transaction.toAddress)")
        print("   Amount: \(transaction.amount) \(transaction.token.symbol)")
        print("   Amount Units: \(transaction.amountWei)")
        
        // Simulate successful transfer for demo
        try await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
        
        return true
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentGasPrice() async throws -> BigUInt {
        // In production, you would query the actual network for gas price
        // For demo, return a reasonable gas price for Polygon (30 gwei)
        return BigUInt(30) * BigUInt(10).power(9) // 30 gwei in wei
    }
}

// MARK: - Error Types

enum TransferError: Error, LocalizedError {
    case noWallet
    case insufficientBalance
    case invalidAmount
    case missingContractAddress
    case gasPriceUnavailable
    case networkError(String)
    case transactionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noWallet:
            return "No wallet available"
        case .insufficientBalance:
            return "Insufficient balance for transfer"
        case .invalidAmount:
            return "Invalid transfer amount"
        case .missingContractAddress:
            return "Token contract address not found"
        case .gasPriceUnavailable:
            return "Could not get current gas price"
        case .networkError(let message):
            return "Network error: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        }
    }
}

// MARK: - Mock Service for Testing

class MockTokenTransferService: TokenTransferProtocol {
    var shouldSucceed = true
    var gasEstimateDelay: TimeInterval = 1.0
    var transferDelay: TimeInterval = 2.0
    var mockGasEstimate = "0.002"
    var mockGasCostUSD = "$0.0034"
    
    func estimateGas(for transaction: SendTransaction) async throws -> GasEstimationResult {
        try await Task.sleep(nanoseconds: UInt64(gasEstimateDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw TransferError.networkError("Mock gas estimation failed")
        }
        
        return GasEstimationResult(
            gasEstimate: mockGasEstimate,
            gasCostUSD: mockGasCostUSD,
            gasLimit: transaction.token.isNative ? "21000" : "65000",
            gasPrice: "30.0"
        )
    }
    
    func executeSend(_ transaction: SendTransaction) async throws -> Bool {
        try await Task.sleep(nanoseconds: UInt64(transferDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw TransferError.transactionFailed("Mock transfer failed")
        }
        
        return true
    }
}