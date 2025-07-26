//
//  GasPriceEstimator.swift
//  1Limit
//
//  Estimates gas prices and calculates transaction fees for different networks
//

import Foundation
import BigInt
import web3swift
import Web3Core

/// Concrete implementation of gas price estimation and fee calculation
class GasPriceEstimator: GasPriceEstimatorProtocol {
    
    // MARK: - Properties
    
    private let networkConfig: NetworkConfig
    private let estimationStrategy: GasEstimationStrategy
    private let web3Provider: Web3ProviderProtocol
    
    // MARK: - Initialization
    
    init(
        networkConfig: NetworkConfig,
        strategy: GasEstimationStrategy = .dynamic,
        web3Provider: Web3ProviderProtocol = DefaultWeb3Provider()
    ) {
        self.networkConfig = networkConfig
        self.estimationStrategy = strategy
        self.web3Provider = web3Provider
    }
    
    // MARK: - GasPriceEstimatorProtocol Implementation
    
    func estimateGasPrice() async -> UInt64 {
        switch estimationStrategy {
        case .static(let gasPrice):
            return gasPrice
        case .dynamic:
            return await estimateDynamicGasPrice()
        case .eip1559:
            return await estimateEIP1559GasPrice()
        }
    }
    
    func calculateTransactionFee(gasPrice: UInt64, gasLimit: UInt64 = 300_000) -> TransactionFee {
        let totalFeeWei = gasPrice * gasLimit
        let feeMatic = Double(totalFeeWei) / 1e18
        
        return TransactionFee(
            feeWei: totalFeeWei,
            feeMatic: feeMatic
        )
    }
    
    // MARK: - Private Gas Estimation Methods
    
    private func estimateDynamicGasPrice() async -> UInt64 {
        do {
            let web3 = try await web3Provider.createWeb3Instance(nodeURL: networkConfig.nodeURL)
            let baseGasPrice = try await web3.eth.gasPrice()
            
            // Apply network-specific boost
            let boost = getNetworkGasBoost()
            let adjustedPrice = baseGasPrice * BigUInt(boost.multiplier) / BigUInt(100)
            
            // Add base fee for network congestion
            let finalPrice = adjustedPrice + BigUInt(boost.baseFeeWei)
            
            return UInt64(finalPrice)
        } catch {
            print("⚠️ Failed to estimate gas price dynamically: \(error)")
            return getFallbackGasPrice()
        }
    }
    
    private func estimateEIP1559GasPrice() async -> UInt64 {
        do {
            let web3 = try await web3Provider.createWeb3Instance(nodeURL: networkConfig.nodeURL)
            let baseGasPrice = try await web3.eth.gasPrice()
            
            // For EIP-1559, calculate maxFeePerGas
            let priorityFee = BigUInt(getNetworkPriorityFee())
            let maxFee = baseGasPrice + priorityFee + BigUInt(10_000_000_000) // Extra buffer
            
            return UInt64(maxFee)
        } catch {
            print("⚠️ Failed to estimate EIP-1559 gas price: \(error)")
            return getFallbackGasPrice()
        }
    }
    
    // MARK: - Network-Specific Configuration
    
    private func getNetworkGasBoost() -> GasBoostConfig {
        switch networkConfig.chainID {
        case 137: // Polygon
            return GasBoostConfig(multiplier: 120, baseFeeWei: 10_000_000_000) // 20% boost + 10 gwei base
        case 1: // Ethereum
            return GasBoostConfig(multiplier: 110, baseFeeWei: 5_000_000_000)  // 10% boost + 5 gwei base
        default: // Other networks
            return GasBoostConfig(multiplier: 115, baseFeeWei: 2_000_000_000)  // 15% boost + 2 gwei base
        }
    }
    
    private func getNetworkPriorityFee() -> UInt64 {
        switch networkConfig.chainID {
        case 137: // Polygon
            return 25_000_000_000 // 25 gwei minimum for Polygon
        case 1: // Ethereum
            return 2_000_000_000  // 2 gwei for Ethereum
        default:
            return 1_000_000_000  // 1 gwei for other networks
        }
    }
    
    private func getFallbackGasPrice() -> UInt64 {
        switch networkConfig.chainID {
        case 137: // Polygon
            return 45_000_000_000 // 45 gwei fallback for Polygon
        case 1: // Ethereum
            return 20_000_000_000 // 20 gwei fallback for Ethereum
        default:
            return 10_000_000_000 // 10 gwei fallback for others
        }
    }
}

// MARK: - Gas Estimation Strategy

/// Strategy pattern for different gas estimation approaches
enum GasEstimationStrategy {
    case static(UInt64)  // Use fixed gas price
    case dynamic         // Query network for current gas price
    case eip1559        // Use EIP-1559 estimation
}

/// Configuration for gas boost settings
struct GasBoostConfig {
    let multiplier: Int    // Percentage multiplier (e.g., 120 = 20% boost)
    let baseFeeWei: UInt64 // Base fee to add in wei
}

// MARK: - Web3 Provider Protocol

/// Protocol for Web3 instance creation (allows for testing)
protocol Web3ProviderProtocol {
    func createWeb3Instance(nodeURL: String) async throws -> Web3
}

/// Default Web3 provider implementation
class DefaultWeb3Provider: Web3ProviderProtocol {
    
    func createWeb3Instance(nodeURL: String) async throws -> Web3 {
        guard let url = URL(string: nodeURL) else {
            throw GasEstimationError.invalidNodeURL
        }
        return try await Web3.new(url)
    }
}

/// Mock Web3 provider for testing
class MockWeb3Provider: Web3ProviderProtocol {
    
    private let mockGasPrice: BigUInt
    
    init(mockGasPrice: BigUInt = BigUInt(30_000_000_000)) {
        self.mockGasPrice = mockGasPrice
    }
    
    func createWeb3Instance(nodeURL: String) async throws -> Web3 {
        // Return mock implementation for testing
        throw GasEstimationError.mockingNotImplemented
    }
}

// MARK: - Gas Price History and Analytics

/// Class for tracking and analyzing gas price history
class GasPriceAnalyzer {
    
    private var priceHistory: [GasPriceSnapshot] = []
    private let maxHistorySize: Int
    
    init(maxHistorySize: Int = 100) {
        self.maxHistorySize = maxHistorySize
    }
    
    /// Record a gas price observation
    func recordGasPrice(_ price: UInt64, timestamp: Date = Date()) {
        let snapshot = GasPriceSnapshot(price: price, timestamp: timestamp)
        priceHistory.append(snapshot)
        
        // Maintain history size limit
        if priceHistory.count > maxHistorySize {
            priceHistory.removeFirst()
        }
    }
    
    /// Get gas price statistics
    func getGasPriceStatistics() -> GasPriceStatistics? {
        guard !priceHistory.isEmpty else { return nil }
        
        let prices = priceHistory.map { $0.price }
        let sortedPrices = prices.sorted()
        
        let average = prices.reduce(0, +) / UInt64(prices.count)
        let median = sortedPrices[sortedPrices.count / 2]
        let min = sortedPrices.first!
        let max = sortedPrices.last!
        
        return GasPriceStatistics(
            average: average,
            median: median,
            min: min,
            max: max,
            sampleCount: prices.count
        )
    }
    
    /// Predict optimal gas price based on history
    func predictOptimalGasPrice(targetConfirmationTime: TimeInterval = 60) -> UInt64? {
        guard let stats = getGasPriceStatistics() else { return nil }
        
        // Simple prediction: use 75th percentile for reasonable confirmation time
        let sortedPrices = priceHistory.map { $0.price }.sorted()
        let percentile75Index = Int(Double(sortedPrices.count) * 0.75)
        
        return sortedPrices[min(percentile75Index, sortedPrices.count - 1)]
    }
}

/// Snapshot of gas price at a specific time
struct GasPriceSnapshot {
    let price: UInt64
    let timestamp: Date
}

/// Gas price statistics
struct GasPriceStatistics {
    let average: UInt64
    let median: UInt64
    let min: UInt64
    let max: UInt64
    let sampleCount: Int
    
    var description: String {
        return """
        Gas Price Statistics (\(sampleCount) samples):
          Average: \(average) wei (\(String(format: "%.1f", Double(average) / 1e9)) gwei)
          Median:  \(median) wei (\(String(format: "%.1f", Double(median) / 1e9)) gwei)
          Range:   \(min) - \(max) wei
        """
    }
}

// MARK: - Gas Estimation Errors

enum GasEstimationError: LocalizedError {
    case invalidNodeURL
    case networkRequestFailed
    case mockingNotImplemented
    case gasEstimationTimeout
    
    var errorDescription: String? {
        switch self {
        case .invalidNodeURL:
            return "Invalid node URL provided"
        case .networkRequestFailed:
            return "Network request for gas price failed"
        case .mockingNotImplemented:
            return "Mocking functionality not implemented"
        case .gasEstimationTimeout:
            return "Gas price estimation timed out"
        }
    }
}

// MARK: - Factory for Gas Estimators

/// Factory for creating gas estimators for different scenarios
class GasEstimatorFactory {
    
    /// Create estimator for production use
    static func createProductionEstimator(networkConfig: NetworkConfig) -> GasPriceEstimatorProtocol {
        return GasPriceEstimator(
            networkConfig: networkConfig,
            strategy: .eip1559,
            web3Provider: DefaultWeb3Provider()
        )
    }
    
    /// Create estimator for testing
    static func createTestEstimator(fixedGasPrice: UInt64) -> GasPriceEstimatorProtocol {
        let mockConfig = NetworkConfig(
            name: "Test",
            nodeURL: "http://localhost:8545",
            routerV6: "0x0000000000000000000000000000000000000000",
            wmatic: "0x0000000000000000000000000000000000000000",
            usdc: "0x0000000000000000000000000000000000000000",
            chainID: 1337,
            domainName: "Test",
            domainVersion: "1"
        )
        
        return GasPriceEstimator(
            networkConfig: mockConfig,
            strategy: .static(fixedGasPrice),
            web3Provider: MockWeb3Provider()
        )
    }
}