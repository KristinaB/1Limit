//
//  BalanceChecker.swift
//  1Limit
//
//  Validates wallet and token balances before Router V6 transaction submission
//

import Foundation
import BigInt
import web3swift
import Web3Core

/// Concrete implementation of balance checking for Router V6 transactions
class BalanceChecker: BalanceCheckerProtocol {
    
    // MARK: - Properties
    
    private let web3Provider: Web3ProviderProtocol
    private let balanceThresholds: BalanceThresholds
    private let logger: LoggerProtocol?
    
    // MARK: - Initialization
    
    init(
        web3Provider: Web3ProviderProtocol = DefaultWeb3Provider(),
        balanceThresholds: BalanceThresholds = .default,
        logger: LoggerProtocol? = nil
    ) {
        self.web3Provider = web3Provider
        self.balanceThresholds = balanceThresholds
        self.logger = logger
    }
    
    // MARK: - BalanceCheckerProtocol Implementation
    
    func checkWalletBalance(walletAddress: String, nodeURL: String) async -> Bool {
        do {
            let web3 = try await web3Provider.createWeb3Instance(nodeURL: nodeURL)
            
            guard let address = EthereumAddress(walletAddress) else {
                await logMessage("❌ Invalid wallet address format: \(walletAddress)")
                return false
            }
            
            let balance = try await web3.eth.getBalance(for: address)
            let balanceEth = Double(balance) / 1e18
            
            await logMessage("💰 MATIC Balance: \(String(format: "%.6f", balanceEth)) MATIC")
            
            let hasBalance = balance >= BigUInt(balanceThresholds.minimumGasBalanceWei)
            if hasBalance {
                await logMessage("✅ Sufficient balance for transaction")
            } else {
                let requiredMatic = Double(balanceThresholds.minimumGasBalanceWei) / 1e18
                await logMessage("❌ Insufficient balance - need at least \(String(format: "%.6f", requiredMatic)) MATIC")
            }
            
            return hasBalance
        } catch {
            await logMessage("❌ Balance check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    func checkTokenAllowances(
        order: RouterV6OrderInfo,
        walletAddress: String,
        routerAddress: String,
        nodeURL: String
    ) async -> Bool {
        do {
            let web3 = try await web3Provider.createWeb3Instance(nodeURL: nodeURL)
            
            guard let walletAddr = EthereumAddress(walletAddress),
                  let routerAddr = EthereumAddress(routerAddress),
                  let tokenAddr = EthereumAddress(order.makerAsset) else {
                await logMessage("❌ Invalid address format in allowance check")
                return false
            }
            
            // Create ERC20 contract instance
            guard let tokenContract = web3.contract(ERC20_ABI, at: tokenAddr) else {
                await logMessage("❌ Failed to create token contract")
                return false
            }
            
            // Check allowance
            guard let allowanceOperation = tokenContract.createReadOperation(
                "allowance",
                parameters: [walletAddr, routerAddr]
            ) else {
                await logMessage("❌ Failed to create allowance check operation")
                return false
            }
            
            let allowanceResult = try await allowanceOperation.callContractMethod()
            guard let allowance = allowanceResult["0"] as? BigUInt else {
                await logMessage("❌ Failed to parse allowance result")
                return false
            }
            
            let requiredAmount = order.makingAmount
            await logMessage("📊 Token allowance: \(allowance)")
            await logMessage("📊 Required amount: \(requiredAmount)")
            
            let hasAllowance = allowance >= requiredAmount
            if hasAllowance {
                await logMessage("✅ Sufficient token allowance")
            } else {
                await logMessage("❌ Need to approve Router V6 to spend tokens first")
                await logMessage("💡 Try: token.approve(\(routerAddress), \(requiredAmount))")
            }
            
            return hasAllowance
        } catch {
            await logMessage("❌ Token allowance check failed: \(error.localizedDescription)")
            return false
        }
    }
    
    // MARK: - Extended Balance Checking Methods
    
    /// Check token balance of the maker
    func checkTokenBalance(
        tokenAddress: String,
        walletAddress: String,
        requiredAmount: BigUInt,
        nodeURL: String
    ) async -> TokenBalanceResult {
        do {
            let web3 = try await web3Provider.createWeb3Instance(nodeURL: nodeURL)
            
            guard let walletAddr = EthereumAddress(walletAddress),
                  let tokenAddr = EthereumAddress(tokenAddress) else {
                return TokenBalanceResult(
                    hasBalance: false,
                    actualBalance: BigUInt(0),
                    requiredBalance: requiredAmount,
                    error: "Invalid address format"
                )
            }
            
            // Create ERC20 contract instance
            guard let tokenContract = web3.contract(ERC20_ABI, at: tokenAddr) else {
                return TokenBalanceResult(
                    hasBalance: false,
                    actualBalance: BigUInt(0),
                    requiredBalance: requiredAmount,
                    error: "Failed to create token contract"
                )
            }
            
            // Check balance
            guard let balanceOperation = tokenContract.createReadOperation(
                "balanceOf",
                parameters: [walletAddr]
            ) else {
                return TokenBalanceResult(
                    hasBalance: false,
                    actualBalance: BigUInt(0),
                    requiredBalance: requiredAmount,
                    error: "Failed to create balance check operation"
                )
            }
            
            let balanceResult = try await balanceOperation.callContractMethod()
            guard let balance = balanceResult["0"] as? BigUInt else {
                return TokenBalanceResult(
                    hasBalance: false,
                    actualBalance: BigUInt(0),
                    requiredBalance: requiredAmount,
                    error: "Failed to parse balance result"
                )
            }
            
            return TokenBalanceResult(
                hasBalance: balance >= requiredAmount,
                actualBalance: balance,
                requiredBalance: requiredAmount,
                error: nil
            )
        } catch {
            return TokenBalanceResult(
                hasBalance: false,
                actualBalance: BigUInt(0),
                requiredBalance: requiredAmount,
                error: error.localizedDescription
            )
        }
    }
    
    /// Comprehensive pre-flight check for Router V6 transaction
    func performComprehensiveCheck(
        order: RouterV6OrderInfo,
        walletAddress: String,
        routerAddress: String,
        nodeURL: String
    ) async -> ComprehensiveBalanceResult {
        await logMessage("🔍 Running comprehensive pre-flight checks...")
        
        // Check wallet balance
        let hasWalletBalance = await checkWalletBalance(
            walletAddress: walletAddress,
            nodeURL: nodeURL
        )
        
        // Check token balance
        let tokenBalanceResult = await checkTokenBalance(
            tokenAddress: order.makerAsset,
            walletAddress: walletAddress,
            requiredAmount: order.makingAmount,
            nodeURL: nodeURL
        )
        
        // Check token allowance
        let hasAllowance = await checkTokenAllowances(
            order: order,
            walletAddress: walletAddress,
            routerAddress: routerAddress,
            nodeURL: nodeURL
        )
        
        let allChecksPassed = hasWalletBalance && tokenBalanceResult.hasBalance && hasAllowance
        
        return ComprehensiveBalanceResult(
            hasWalletBalance: hasWalletBalance,
            tokenBalanceResult: tokenBalanceResult,
            hasTokenAllowance: hasAllowance,
            allChecksPassed: allChecksPassed
        )
    }
    
    // MARK: - Private Helper Methods
    
    private func logMessage(_ message: String) async {
        await logger?.addLog(message)
    }
    
    // MARK: - ERC20 ABI
    
    private let ERC20_ABI = """
    [
        {
            "constant": true,
            "inputs": [
                {"name": "_owner", "type": "address"},
                {"name": "_spender", "type": "address"}
            ],
            "name": "allowance",
            "outputs": [{"name": "", "type": "uint256"}],
            "type": "function"
        },
        {
            "constant": true,
            "inputs": [{"name": "_owner", "type": "address"}],
            "name": "balanceOf",
            "outputs": [{"name": "", "type": "uint256"}],
            "type": "function"
        }
    ]
    """
}

// MARK: - Balance Thresholds Configuration

/// Configuration for balance thresholds and limits
struct BalanceThresholds {
    let minimumGasBalanceWei: UInt64
    let recommendedGasBalanceWei: UInt64
    let minimumTokenBalancePercentage: Double  // e.g., 1.05 for 5% buffer
    
    /// Default thresholds for production use
    static let `default` = BalanceThresholds(
        minimumGasBalanceWei: 20_000_000_000_000_000, // 0.02 MATIC
        recommendedGasBalanceWei: 50_000_000_000_000_000, // 0.05 MATIC
        minimumTokenBalancePercentage: 1.0 // Exact amount required
    )
    
    /// Conservative thresholds for high-value transactions
    static let conservative = BalanceThresholds(
        minimumGasBalanceWei: 100_000_000_000_000_000, // 0.1 MATIC
        recommendedGasBalanceWei: 200_000_000_000_000_000, // 0.2 MATIC
        minimumTokenBalancePercentage: 1.05 // 5% buffer
    )
    
    /// Minimal thresholds for testing
    static let minimal = BalanceThresholds(
        minimumGasBalanceWei: 1_000_000_000_000_000, // 0.001 MATIC
        recommendedGasBalanceWei: 5_000_000_000_000_000, // 0.005 MATIC
        minimumTokenBalancePercentage: 1.0
    )
}

// MARK: - Result Types

/// Result of token balance check
struct TokenBalanceResult {
    let hasBalance: Bool
    let actualBalance: BigUInt
    let requiredBalance: BigUInt
    let error: String?
    
    var description: String {
        if hasBalance {
            return "✅ Token balance sufficient: \(actualBalance) (required: \(requiredBalance))"
        } else {
            let deficit = requiredBalance > actualBalance ? requiredBalance - actualBalance : BigUInt(0)
            return "❌ Token balance insufficient: \(actualBalance) (required: \(requiredBalance), deficit: \(deficit))"
        }
    }
}

/// Result of comprehensive balance check
struct ComprehensiveBalanceResult {
    let hasWalletBalance: Bool
    let tokenBalanceResult: TokenBalanceResult
    let hasTokenAllowance: Bool
    let allChecksPassed: Bool
    
    var description: String {
        var status = "📊 Comprehensive Balance Check Results:\n"
        status += "  Wallet Balance: \(hasWalletBalance ? "✅" : "❌")\n"
        status += "  Token Balance: \(tokenBalanceResult.hasBalance ? "✅" : "❌")\n"
        status += "  Token Allowance: \(hasTokenAllowance ? "✅" : "❌")\n"
        status += "  Overall: \(allChecksPassed ? "✅ READY" : "❌ NOT READY")"
        
        if let error = tokenBalanceResult.error {
            status += "\n  Error: \(error)"
        }
        
        return status
    }
}

// MARK: - Balance Checker Factory

/// Factory for creating balance checkers with different configurations
class BalanceCheckerFactory {
    
    /// Create balance checker for production use
    static func createProductionChecker(logger: LoggerProtocol? = nil) -> BalanceCheckerProtocol {
        return BalanceChecker(
            web3Provider: DefaultWeb3Provider(),
            balanceThresholds: .default,
            logger: logger
        )
    }
    
    /// Create balance checker for high-value transactions
    static func createConservativeChecker(logger: LoggerProtocol? = nil) -> BalanceCheckerProtocol {
        return BalanceChecker(
            web3Provider: DefaultWeb3Provider(),
            balanceThresholds: .conservative,
            logger: logger
        )
    }
    
    /// Create balance checker for testing
    static func createTestChecker() -> BalanceCheckerProtocol {
        return BalanceChecker(
            web3Provider: MockWeb3Provider(),
            balanceThresholds: .minimal,
            logger: nil
        )
    }
}

// MARK: - Balance Monitoring

/// Class for monitoring balance changes over time
class BalanceMonitor {
    
    private var balanceHistory: [BalanceSnapshot] = []
    private let maxHistorySize: Int
    
    init(maxHistorySize: Int = 50) {
        self.maxHistorySize = maxHistorySize
    }
    
    /// Record a balance snapshot
    func recordBalance(
        walletAddress: String,
        balance: BigUInt,
        tokenBalances: [String: BigUInt] = [:],
        timestamp: Date = Date()
    ) {
        let snapshot = BalanceSnapshot(
            walletAddress: walletAddress,
            balance: balance,
            tokenBalances: tokenBalances,
            timestamp: timestamp
        )
        
        balanceHistory.append(snapshot)
        
        // Maintain history size limit
        if balanceHistory.count > maxHistorySize {
            balanceHistory.removeFirst()
        }
    }
    
    /// Get balance change over time
    func getBalanceChange(since: Date) -> BalanceChange? {
        let relevantSnapshots = balanceHistory.filter { $0.timestamp >= since }
        guard let earliest = relevantSnapshots.first,
              let latest = relevantSnapshots.last else {
            return nil
        }
        
        let balanceChange = Int64(latest.balance) - Int64(earliest.balance)
        
        return BalanceChange(
            startBalance: earliest.balance,
            endBalance: latest.balance,
            change: balanceChange,
            timeSpan: latest.timestamp.timeIntervalSince(earliest.timestamp)
        )
    }
}

/// Snapshot of wallet balance at a specific time
struct BalanceSnapshot {
    let walletAddress: String
    let balance: BigUInt
    let tokenBalances: [String: BigUInt]
    let timestamp: Date
}

/// Balance change over a time period
struct BalanceChange {
    let startBalance: BigUInt
    let endBalance: BigUInt
    let change: Int64  // Can be negative
    let timeSpan: TimeInterval
    
    var percentageChange: Double {
        guard startBalance > 0 else { return 0 }
        return Double(change) / Double(startBalance) * 100
    }
}