//
//  RouterV6Protocols.swift
//  1Limit
//
//  Protocol definitions for Router V6 OOP architecture
//

import Foundation
import BigInt

// MARK: - Core Data Structures

/// Router V6 order information
struct RouterV6OrderInfo {
    let salt: BigUInt
    let maker: String        // Address as hex string
    let receiver: String     // Address as hex string  
    let makerAsset: String   // Address as hex string
    let takerAsset: String   // Address as hex string
    let makingAmount: BigUInt
    let takingAmount: BigUInt
    let makerTraits: BigUInt
}

/// EIP-712 domain information
struct EIP712DomainInfo {
    let name: String
    let version: String
    let chainID: Int
    let verifyingContract: String
}

/// Network configuration
struct NetworkConfig {
    let name: String
    let nodeURL: String
    let routerV6: String
    let wmatic: String
    let usdc: String
    let chainID: Int
    let domainName: String
    let domainVersion: String
}

// Note: WalletData is defined in WalletLoader.swift

// MARK: - Core Protocol Definitions

/// Protocol for generating order parameters (salt, nonce)
protocol OrderParameterGeneratorProtocol {
    func generateSDKStyleSalt() -> BigUInt
    func generateRandomNonce() -> UInt64
}

/// Protocol for calculating Router V6 MakerTraits
protocol MakerTraitsCalculatorProtocol {
    func calculateMakerTraitsV6(nonce: UInt64, expiry: UInt32) -> BigUInt
}

/// Protocol for providing EIP-712 domain configuration
protocol EIP712DomainProviderProtocol {
    func createEIP712Domain() -> EIP712DomainInfo
}

/// Protocol for validating Router V6 orders and transactions
protocol OrderValidatorProtocol {
    func validateTransaction(order: RouterV6OrderInfo) -> ValidationResult
}

/// Protocol for estimating gas prices and fees
protocol GasPriceEstimatorProtocol {
    func estimateGasPrice() async -> UInt64
    func calculateTransactionFee(gasPrice: UInt64, gasLimit: UInt64) -> TransactionFee
}

/// Protocol for checking wallet and token balances
protocol BalanceCheckerProtocol {
    func checkWalletBalance(walletAddress: String, nodeURL: String) async -> Bool
    func checkTokenBalance(tokenAddress: String, walletAddress: String, requiredAmount: BigUInt, nodeURL: String) async -> TokenBalanceResult
    func checkTokenAllowances(order: RouterV6OrderInfo, walletAddress: String, routerAddress: String, nodeURL: String) async -> Bool
    func performComprehensiveCheck(order: RouterV6OrderInfo, walletAddress: String, routerAddress: String, nodeURL: String) async -> ComprehensiveBalanceResult
}

/// Protocol for submitting transactions to blockchain
protocol TransactionSubmitterProtocol {
    func submitRouterV6Transaction(
        order: RouterV6OrderInfo,
        compactSignature: (r: Data, vs: Data),
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> TransactionResult
}

/// Protocol for creating Router V6 orders
protocol OrderFactoryProtocol {
    func createRouterV6Order(
        walletAddress: String,
        salt: BigUInt,
        makerTraits: BigUInt,
        config: NetworkConfig
    ) -> RouterV6OrderInfo
    
    func createCompleteOrder(
        walletAddress: String,
        makerAsset: String,
        takerAsset: String,
        makingAmount: BigUInt,
        takingAmount: BigUInt,
        config: NetworkConfig,
        orderConfig: OrderConfiguration
    ) async -> OrderCreationResult
}

/// Protocol for logging operations
protocol LoggerProtocol {
    func addLog(_ message: String) async
}

// MARK: - Supporting Data Structures

struct ValidationResult {
    let isValid: Bool
    let issues: [String]
}

struct TransactionFee {
    let feeWei: UInt64
    let feeMatic: Double
}

struct TransactionResult {
    let hash: String
    let success: Bool
    let gasUsed: UInt64?
    let error: String?
}

// Note: Types like OrderConfiguration, OrderCreationResult, OrderParameters, 
// ComprehensiveBalanceResult, and TokenBalanceResult are defined in their respective service files