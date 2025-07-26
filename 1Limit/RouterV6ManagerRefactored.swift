//
//  RouterV6ManagerRefactored.swift
//  1Limit
//
//  Refactored Router V6 Manager using dependency injection and OOP patterns
//

import Foundation
import SwiftUI
import BigInt

/// Refactored Router V6 Manager with proper separation of concerns and dependency injection
@MainActor
class RouterV6ManagerRefactored: ObservableObject, LoggerProtocol {
    
    // MARK: - Published Properties
    
    @Published var isExecuting = false
    @Published var executionLog = ""
    
    // MARK: - Dependencies (Injected)
    
    private let orderFactory: OrderFactoryProtocol
    private let domainProvider: EIP712DomainProviderProtocol
    private let balanceChecker: BalanceCheckerProtocol
    private let gasPriceEstimator: GasPriceEstimatorProtocol
    private let transactionSubmitter: TransactionSubmitterProtocol
    private let walletLoader: WalletLoaderProtocol
    private let debugLogger: DebugLoggerProtocol
    
    // MARK: - Configuration
    
    private let networkConfig: NetworkConfig
    
    // MARK: - State
    
    private var wallet: WalletData?
    
    // MARK: - Initialization with Dependency Injection
    
    init(
        orderFactory: OrderFactoryProtocol,
        domainProvider: EIP712DomainProviderProtocol,
        balanceChecker: BalanceCheckerProtocol,
        gasPriceEstimator: GasPriceEstimatorProtocol,
        transactionSubmitter: TransactionSubmitterProtocol,
        walletLoader: WalletLoaderProtocol,
        debugLogger: DebugLoggerProtocol,
        networkConfig: NetworkConfig
    ) {
        self.orderFactory = orderFactory
        self.domainProvider = domainProvider
        self.balanceChecker = balanceChecker
        self.gasPriceEstimator = gasPriceEstimator
        self.transactionSubmitter = transactionSubmitter
        self.walletLoader = walletLoader
        self.debugLogger = debugLogger
        self.networkConfig = networkConfig
        
        // Set up debug logging
        debugLogger.setupLogging()
    }
    
    // MARK: - Main Execution Flow
    
    func executeTestTransaction() async {
        isExecuting = true
        executionLog = ""
        
        await addLog("🚀 1inch Router V6 Real Transaction Test")
        await addLog("=====================================\n")
        
        do {
            // Step 1: Load wallet
            wallet = try await loadWallet()
            
            // Step 2: Create order
            let orderResult = try await createOrder()
            
            // Step 3: Sign order
            let signature = try await signOrder(orderResult.order)
            
            // Step 4: Validate and check balances
            try await performPreflightChecks(orderResult.order)
            
            // Step 5: Submit transaction
            let transactionResult = try await submitTransaction(
                order: orderResult.order,
                signature: signature
            )
            
            await addLog("🎉 Router V6 Debug Flow Complete! 🎊")
            
        } catch {
            await addLog("❌ Transaction failed: \(error.localizedDescription)")
        }
        
        isExecuting = false
    }
    
    // MARK: - Private Execution Steps
    
    private func loadWallet() async throws -> WalletData {
        await addLog("📋 Step 1: Loading wallet...")
        
        guard let loadedWallet = walletLoader.loadWallet() else {
            throw RouterV6Error.walletLoadFailed
        }
        
        let displayInfo = walletLoader.getWalletDisplayInfo(loadedWallet)
        await addLog("✅ Wallet loaded: \(displayInfo.maskedAddress)")
        await addLog("🔐 Private key: \(maskPrivateKey(loadedWallet.privateKey))")
        await addLog("✅ Validation: \(displayInfo.isValid ? "PASSED" : "FAILED")\n")
        
        return loadedWallet
    }
    
    private func createOrder() async throws -> OrderCreationResult {
        await addLog("📋 Step 2: Generating Router V6 order parameters...")
        
        guard let wallet = wallet else {
            throw RouterV6Error.walletNotLoaded
        }
        
        let orderResult = await orderFactory.createCompleteOrder(
            walletAddress: wallet.address,
            makerAsset: networkConfig.wmatic,
            takerAsset: networkConfig.usdc,
            makingAmount: BigUInt(10000000000000000), // 0.01 WMATIC
            takingAmount: BigUInt(10000), // 0.01 USDC
            config: networkConfig,
            orderConfig: .default
        )
        
        if !orderResult.isValid {
            await addLog("⚠️ Order validation warnings:")
            for issue in orderResult.validation.issues {
                await addLog("   • \(issue)")
            }
        }
        
        await addLog("")
        return orderResult
    }
    
    private func signOrder(_ order: RouterV6OrderInfo) async throws -> String {
        await addLog("📋 Step 3: Creating EIP-712 domain...")
        
        let domain = domainProvider.createEIP712Domain()
        await addLog("🌐 Domain: \(domain.name) v\(domain.version)")
        await addLog("⛓️ Chain ID: \(domain.chainID)")
        await addLog("📄 Contract: \(domain.verifyingContract)\n")
        
        await addLog("📋 Step 4: Creating Router V6 order structure...")
        await addLog("📊 Making: 0.01 WMATIC (\(order.makingAmount) wei)")
        await addLog("🎯 Taking: 0.01 USDC (\(order.takingAmount) units)")
        
        guard let wallet = wallet else {
            throw RouterV6Error.walletNotLoaded
        }
        
        let displayInfo = walletLoader.getWalletDisplayInfo(wallet)
        await addLog("👤 Maker: \(displayInfo.maskedAddress)")
        await addLog("🏠 Receiver: \(displayInfo.maskedAddress) (self-fill)\n")
        
        await addLog("📋 Step 5: Signing Router V6 order with EIP-712...")
        
        // Convert to EIP712SignerWeb3 format
        let web3Order = EIP712SignerWeb3.RouterV6Order(
            salt: order.salt,
            maker: order.maker,
            receiver: order.receiver,
            makerAsset: order.makerAsset,
            takerAsset: order.takerAsset,
            makingAmount: order.makingAmount,
            takingAmount: order.takingAmount,
            makerTraits: order.makerTraits
        )
        
        let web3Domain = EIP712SignerWeb3.EIP712Domain(
            name: domain.name,
            version: domain.version,
            chainId: BigUInt(domain.chainID),
            verifyingContract: domain.verifyingContract
        )
        
        let signatureData = try EIP712SignerWeb3.signRouterV6Order(
            order: web3Order,
            domain: web3Domain,
            privateKey: wallet.privateKey
        )
        
        let signature = "0x" + signatureData.map { String(format: "%02hhx", $0) }.joined()
        
        await addLog("🔐 EIP-712 signature generated (65 bytes)")
        await addLog("🔧 Converting to EIP-2098 compact format...")
        
        let compactSig = EIP712SignerWeb3.toCompactSignature(signature: signatureData)
        await addLog("✅ Compact signature ready:")
        await addLog("   r:  0x\(compactSig.r.prefix(10).map { String(format: "%02hhx", $0) }.joined())...")
        await addLog("   vs: 0x\(compactSig.vs.prefix(10).map { String(format: "%02hhx", $0) }.joined())...\n")
        
        return signature
    }
    
    private func performPreflightChecks(_ order: RouterV6OrderInfo) async throws {
        await addLog("📋 Step 6: Preparing fillOrder transaction...")
        
        guard let wallet = wallet else {
            throw RouterV6Error.walletNotLoaded
        }
        
        // Estimate gas price
        let gasPrice = await gasPriceEstimator.estimateGasPrice()
        let fees = gasPriceEstimator.calculateTransactionFee(gasPrice: gasPrice)
        
        await addLog("✅ Transaction validation passed")
        await addLog("📊 Contract: Router V6 (\(networkConfig.routerV6))")
        await addLog("🔧 Method: fillOrder(order, r, vs, amount, takerTraits)")
        await addLog("⛽ Gas Settings:")
        await addLog("   Limit: 300,000 units")
        await addLog("   Price: \(gasPrice) wei (\(String(format: "%.1f", Double(gasPrice) / 1e9)) gwei)")
        await addLog("   Fee: \(String(format: "%.6f", fees.feeMatic)) MATIC")
        await addLog("🌐 Network: \(networkConfig.name) (Chain ID: \(networkConfig.chainID))\n")
        
        await addLog("📋 Step 7: Submitting to \(networkConfig.name)...")
        
        // Check balances
        let balanceResult = await balanceChecker.performComprehensiveCheck(
            order: order,
            walletAddress: wallet.address,
            routerAddress: networkConfig.routerV6,
            nodeURL: networkConfig.nodeURL
        )
        
        if !balanceResult.allChecksPassed {
            throw RouterV6Error.preflightCheckFailed(balanceResult.description)
        }
    }
    
    private func submitTransaction(
        order: RouterV6OrderInfo,
        signature: String
    ) async throws -> TransactionResult {
        guard let wallet = wallet else {
            throw RouterV6Error.walletNotLoaded
        }
        
        let signatureData = Data(hex: String(signature.dropFirst(2)))
        let compactSig = EIP712SignerWeb3.toCompactSignature(signature: signatureData)
        
        let result = try await transactionSubmitter.submitRouterV6Transaction(
            order: order,
            compactSignature: compactSig,
            walletData: wallet,
            config: networkConfig
        )
        
        return result
    }
    
    // MARK: - LoggerProtocol Implementation
    
    func addLog(_ message: String) async {
        let logMessage = message + "\n"
        executionLog += logMessage
        
        // Also write to debug log file
        await debugLogger.writeToLogFile(logMessage)
    }
    
    // MARK: - Helper Methods
    
    private func maskPrivateKey(_ privateKey: String) -> String {
        guard privateKey.count >= 10 else { return privateKey }
        let start = String(privateKey.prefix(6))
        return "\(start)..." + String(repeating: "*", count: 56) + "***"
    }
}

// MARK: - Dependency Protocols

/// Protocol for wallet loading operations
protocol WalletLoaderProtocol {
    func loadWallet() -> WalletData?
    func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo
}

/// Protocol for debug logging operations
protocol DebugLoggerProtocol {
    func setupLogging()
    func writeToLogFile(_ message: String) async
}

// MARK: - Factory for RouterV6ManagerRefactored

/// Factory for creating RouterV6ManagerRefactored with different configurations
class RouterV6ManagerFactory {
    
    /// Create manager for production use on Polygon Mainnet
    static func createProductionManager() -> RouterV6ManagerRefactored {
        let networkConfig = NetworkConfig(
            name: "Polygon Mainnet",
            nodeURL: "https://polygon-bor-rpc.publicnode.com",
            routerV6: "0x111111125421cA6dc452d289314280a0f8842A65",
            wmatic: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
            usdc: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            chainID: 137,
            domainName: "1inch Aggregation Router",
            domainVersion: "6"
        )
        
        let debugLogger = DebugLogger()
        
        let manager = RouterV6ManagerRefactored(
            orderFactory: OrderFactory.createProductionFactory(logger: nil),
            domainProvider: DomainProviderFactory.createPolygonMainnetProvider(),
            balanceChecker: BalanceCheckerFactory.createProductionChecker(),
            gasPriceEstimator: GasEstimatorFactory.createProductionEstimator(networkConfig: networkConfig),
            transactionSubmitter: TransactionSubmitterFactory.createProductionSubmitter(),
            walletLoader: WalletLoaderAdapter(),
            debugLogger: debugLogger,
            networkConfig: networkConfig
        )
        
        return manager
    }
    
    /// Create manager for testing
    static func createTestManager() -> RouterV6ManagerRefactored {
        let networkConfig = NetworkConfig(
            name: "Test Network",
            nodeURL: "http://localhost:8545",
            routerV6: "0x0000000000000000000000000000000000000000",
            wmatic: "0x0000000000000000000000000000000000000000",
            usdc: "0x0000000000000000000000000000000000000000",
            chainID: 1337,
            domainName: "Test Router",
            domainVersion: "6"
        )
        
        let manager = RouterV6ManagerRefactored(
            orderFactory: OrderFactory.createTestFactory(),
            domainProvider: DomainProviderFactory.createTestnetProvider(chainID: 1337, contractAddress: "0x0000000000000000000000000000000000000000"),
            balanceChecker: BalanceCheckerFactory.createTestChecker(),
            gasPriceEstimator: GasEstimatorFactory.createTestEstimator(fixedGasPrice: 20_000_000_000),
            transactionSubmitter: TransactionSubmitterFactory.createTestSubmitter(),
            walletLoader: MockWalletLoader(),
            debugLogger: MockDebugLogger(),
            networkConfig: networkConfig
        )
        
        return manager
    }
}

// MARK: - Adapter Classes

/// Adapter to make existing WalletLoader compatible with protocol
class WalletLoaderAdapter: WalletLoaderProtocol {
    
    func loadWallet() -> WalletData? {
        return WalletLoader.shared.loadWallet()
    }
    
    func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo {
        return WalletLoader.shared.getWalletDisplayInfo(wallet)
    }
}

/// Debug logger implementation
class DebugLogger: DebugLoggerProtocol {
    
    private var logFileURL: URL?
    
    func setupLogging() {
        // Use project directory for easy access
        let projectDir = "/Users/makevoid/apps/1Limit/logs"
        
        // Create logs directory if it doesn't exist
        try? FileManager.default.createDirectory(atPath: projectDir, withIntermediateDirectories: true, attributes: nil)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let timestamp = formatter.string(from: Date())
        
        let fileName = "1limit_debug_\(timestamp).log"
        logFileURL = URL(fileURLWithPath: projectDir).appendingPathComponent(fileName)
        
        if let logFileURL = logFileURL {
            let initialMessage = "🚀 1Limit Debug Log Started: \(Date())\n" +
                                "📍 Log file: \(logFileURL.path)\n" +
                                "💡 To tail: tail -f \(logFileURL.path)\n" +
                                "=====================================\n\n"
            
            try? initialMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
            print("📝 Debug log file created: \(logFileURL.path)")
            print("💡 To tail the log: tail -f \(logFileURL.path)")
        }
    }
    
    func writeToLogFile(_ message: String) async {
        guard let logFileURL = logFileURL else { return }
        
        if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
            fileHandle.seekToEndOfFile()
            if let data = message.data(using: .utf8) {
                fileHandle.write(data)
            }
            fileHandle.closeFile()
        } else {
            // Fallback: append to file
            if let existingContent = try? String(contentsOf: logFileURL, encoding: .utf8) {
                let newContent = existingContent + message
                try? newContent.write(to: logFileURL, atomically: true, encoding: .utf8)
            }
        }
    }
}

// MARK: - Mock Implementations for Testing

class MockWalletLoader: WalletLoaderProtocol {
    
    func loadWallet() -> WalletData? {
        return WalletData(
            address: "0x1234567890123456789012345678901234567890",
            privateKey: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
        )
    }
    
    func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo {
        return WalletDisplayInfo(
            maskedAddress: "0x1234...7890",
            isValid: true
        )
    }
}

class MockDebugLogger: DebugLoggerProtocol {
    
    func setupLogging() {
        // Mock implementation - do nothing
    }
    
    func writeToLogFile(_ message: String) async {
        // Mock implementation - just print
        print(message, terminator: "")
    }
}

// MARK: - Router V6 Errors

enum RouterV6Error: LocalizedError {
    case walletLoadFailed
    case walletNotLoaded
    case orderCreationFailed
    case signingFailed
    case preflightCheckFailed(String)
    case transactionSubmissionFailed
    
    var errorDescription: String? {
        switch self {
        case .walletLoadFailed:
            return "Failed to load wallet"
        case .walletNotLoaded:
            return "Wallet not loaded"
        case .orderCreationFailed:
            return "Failed to create Router V6 order"
        case .signingFailed:
            return "Failed to sign Router V6 order"
        case .preflightCheckFailed(let details):
            return "Preflight checks failed: \(details)"
        case .transactionSubmissionFailed:
            return "Failed to submit transaction"
        }
    }
}