//
//  EIP712DomainProvider.swift
//  1Limit
//
//  Provides EIP-712 domain configuration for different networks and Router versions
//

import Foundation
import BigInt

/// Concrete implementation of EIP-712 domain configuration provider
class EIP712DomainProvider: EIP712DomainProviderProtocol {
    
    // MARK: - Properties
    
    private let networkConfig: NetworkConfig
    private let domainStrategy: DomainConfigurationStrategy
    
    // MARK: - Initialization
    
    init(networkConfig: NetworkConfig, strategy: DomainConfigurationStrategy = .routerV6) {
        self.networkConfig = networkConfig
        self.domainStrategy = strategy
    }
    
    // MARK: - EIP712DomainProviderProtocol Implementation
    
    func createEIP712Domain() -> EIP712DomainInfo {
        switch domainStrategy {
        case .routerV6:
            return createRouterV6Domain()
        case .routerV5:
            return createRouterV5Domain()
        case .custom(let config):
            return createCustomDomain(config: config)
        }
    }
    
    // MARK: - Private Domain Creation Methods
    
    private func createRouterV6Domain() -> EIP712DomainInfo {
        return EIP712DomainInfo(
            name: networkConfig.domainName,
            version: networkConfig.domainVersion,
            chainID: networkConfig.chainID,
            verifyingContract: networkConfig.routerV6
        )
    }
    
    private func createRouterV5Domain() -> EIP712DomainInfo {
        // Router V5 uses different domain configuration
        return EIP712DomainInfo(
            name: "1inch Exchange",
            version: "5",
            chainID: networkConfig.chainID,
            verifyingContract: networkConfig.routerV6 // Would be routerV5 if we had it
        )
    }
    
    private func createCustomDomain(config: CustomDomainConfig) -> EIP712DomainInfo {
        return EIP712DomainInfo(
            name: config.name,
            version: config.version,
            chainID: config.chainID,
            verifyingContract: config.verifyingContract
        )
    }
}

// MARK: - Domain Configuration Strategy

/// Strategy pattern for different domain configurations
enum DomainConfigurationStrategy {
    case routerV6
    case routerV5
    case custom(CustomDomainConfig)
}

/// Custom domain configuration
struct CustomDomainConfig {
    let name: String
    let version: String
    let chainID: Int
    let verifyingContract: String
}

// MARK: - Network-Specific Domain Providers

/// Factory for creating domain providers for different networks
class DomainProviderFactory {
    
    /// Create domain provider for Polygon Mainnet
    static func createPolygonMainnetProvider() -> EIP712DomainProviderProtocol {
        let config = NetworkConfig(
            name: "Polygon Mainnet",
            nodeURL: "https://polygon-bor-rpc.publicnode.com",
            routerV6: "0x111111125421cA6dc452d289314280a0f8842A65",
            wmatic: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
            usdc: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            chainID: 137,
            domainName: "1inch Aggregation Router",
            domainVersion: "6"
        )
        return EIP712DomainProvider(networkConfig: config, strategy: .routerV6)
    }
    
    /// Create domain provider for Ethereum Mainnet
    static func createEthereumMainnetProvider() -> EIP712DomainProviderProtocol {
        let config = NetworkConfig(
            name: "Ethereum Mainnet",
            nodeURL: "https://ethereum-rpc.publicnode.com",
            routerV6: "0x111111125421cA6dc452d289314280a0f8842A65",
            wmatic: "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // WETH
            usdc: "0xA0b86a33E6417c286d4190b2e4b6d4cd59F8Ae9c",   // USDC
            chainID: 1,
            domainName: "1inch Aggregation Router",
            domainVersion: "6"
        )
        return EIP712DomainProvider(networkConfig: config, strategy: .routerV6)
    }
    
    /// Create domain provider for testing/development
    static func createTestnetProvider(chainID: Int, contractAddress: String) -> EIP712DomainProviderProtocol {
        let config = NetworkConfig(
            name: "Test Network",
            nodeURL: "http://localhost:8545",
            routerV6: contractAddress,
            wmatic: "0x0000000000000000000000000000000000000000",
            usdc: "0x0000000000000000000000000000000000000000",
            chainID: chainID,
            domainName: "1inch Aggregation Router",
            domainVersion: "6"
        )
        return EIP712DomainProvider(networkConfig: config, strategy: .routerV6)
    }
}

// MARK: - Domain Validation

/// Utility class for validating EIP-712 domains
class DomainValidator {
    
    /// Validate that domain configuration is correct for Router V6
    static func validateRouterV6Domain(_ domain: EIP712DomainInfo) -> DomainValidationResult {
        var issues: [String] = []
        
        // Check domain name
        if domain.name != "1inch Aggregation Router" {
            issues.append("Domain name should be '1inch Aggregation Router', got '\(domain.name)'")
        }
        
        // Check version for Router V6
        if domain.version != "6" {
            issues.append("Domain version should be '6' for Router V6, got '\(domain.version)'")
        }
        
        // Check chain ID is valid
        if domain.chainID <= 0 {
            issues.append("Chain ID must be positive, got \(domain.chainID)")
        }
        
        // Check verifying contract format
        if !domain.verifyingContract.hasPrefix("0x") || domain.verifyingContract.count != 42 {
            issues.append("Verifying contract address format invalid: \(domain.verifyingContract)")
        }
        
        return DomainValidationResult(
            isValid: issues.isEmpty,
            issues: issues,
            domain: domain
        )
    }
    
    /// Check if domain matches expected Router V6 configuration for a given network
    static func verifyNetworkDomain(_ domain: EIP712DomainInfo, expectedChainID: Int, expectedContract: String) -> Bool {
        return domain.chainID == expectedChainID &&
               domain.verifyingContract.lowercased() == expectedContract.lowercased() &&
               domain.name == "1inch Aggregation Router" &&
               domain.version == "6"
    }
}

/// Result of domain validation
struct DomainValidationResult {
    let isValid: Bool
    let issues: [String]
    let domain: EIP712DomainInfo
    
    var description: String {
        if isValid {
            return "✅ Domain validation passed for \(domain.name) v\(domain.version) on chain \(domain.chainID)"
        } else {
            return "❌ Domain validation failed:\n" + issues.map { "  • \($0)" }.joined(separator: "\n")
        }
    }
}