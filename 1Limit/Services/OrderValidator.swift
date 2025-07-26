//
//  OrderValidator.swift
//  1Limit
//
//  Validates Router V6 orders and transactions before submission
//

import Foundation
import BigInt

/// Concrete implementation of order validation for Router V6
class OrderValidator: OrderValidatorProtocol {
    
    // MARK: - Properties
    
    private let validationRules: OrderValidationRules
    
    // MARK: - Initialization
    
    init(validationRules: OrderValidationRules = .standard) {
        self.validationRules = validationRules
    }
    
    // MARK: - OrderValidatorProtocol Implementation
    
    func validateTransaction(order: RouterV6OrderInfo) -> ValidationResult {
        var issues: [String] = []
        
        // Run all validation checks
        issues.append(contentsOf: validateBasicOrder(order))
        issues.append(contentsOf: validateAmounts(order))
        issues.append(contentsOf: validateAddresses(order))
        issues.append(contentsOf: validateMakerTraits(order))
        issues.append(contentsOf: validateSalt(order))
        
        return ValidationResult(
            isValid: issues.isEmpty,
            issues: issues
        )
    }
    
    // MARK: - Private Validation Methods
    
    private func validateBasicOrder(_ order: RouterV6OrderInfo) -> [String] {
        var issues: [String] = []
        
        // Check that order is not nil/empty
        if order.maker.isEmpty {
            issues.append("Maker address cannot be empty")
        }
        
        if order.receiver.isEmpty {
            issues.append("Receiver address cannot be empty")
        }
        
        if order.makerAsset.isEmpty {
            issues.append("Maker asset address cannot be empty")
        }
        
        if order.takerAsset.isEmpty {
            issues.append("Taker asset address cannot be empty")
        }
        
        return issues
    }
    
    private func validateAmounts(_ order: RouterV6OrderInfo) -> [String] {
        var issues: [String] = []
        
        // Check amounts are not zero
        if order.makingAmount == BigUInt(0) {
            issues.append("Making amount cannot be zero")
        }
        
        if order.takingAmount == BigUInt(0) {
            issues.append("Taking amount cannot be zero")
        }
        
        // Check amounts are within reasonable bounds
        if validationRules.enforceMaxAmounts {
            let maxAmount = BigUInt(10).power(30) // 1e30 as reasonable max
            
            if order.makingAmount > maxAmount {
                issues.append("Making amount exceeds maximum allowed value")
            }
            
            if order.takingAmount > maxAmount {
                issues.append("Taking amount exceeds maximum allowed value")
            }
        }
        
        // Check for reasonable price ratios if enabled
        if validationRules.enforceReasonablePriceRatio {
            let ratio = Double(order.makingAmount) / Double(order.takingAmount)
            if ratio > validationRules.maxPriceRatio || ratio < (1.0 / validationRules.maxPriceRatio) {
                issues.append("Price ratio appears unreasonable (too high or too low)")
            }
        }
        
        return issues
    }
    
    private func validateAddresses(_ order: RouterV6OrderInfo) -> [String] {
        var issues: [String] = []
        
        // Validate address formats
        let addresses = [
            ("maker", order.maker),
            ("receiver", order.receiver),
            ("makerAsset", order.makerAsset),
            ("takerAsset", order.takerAsset)
        ]
        
        for (name, address) in addresses {
            if let issue = validateEthereumAddress(address, name: name) {
                issues.append(issue)
            }
        }
        
        // Check for same asset trading (should not trade token for itself)
        if order.makerAsset.lowercased() == order.takerAsset.lowercased() {
            issues.append("Cannot trade token for itself (makerAsset == takerAsset)")
        }
        
        // Validate known token addresses if enabled
        if validationRules.validateKnownTokens {
            if !isKnownToken(order.makerAsset) {
                issues.append("Maker asset is not a known/verified token")
            }
            
            if !isKnownToken(order.takerAsset) {
                issues.append("Taker asset is not a known/verified token")
            }
        }
        
        return issues
    }
    
    private func validateMakerTraits(_ order: RouterV6OrderInfo) -> [String] {
        var issues: [String] = []
        
        // Check MakerTraits is not zero (should contain nonce at minimum)
        if order.makerTraits == BigUInt(0) {
            issues.append("MakerTraits appears to be zero (nonce not set)")
        }
        
        // Analyze MakerTraits structure
        let analysis = MakerTraitsAnalyzer.analyzeMakerTraits(order.makerTraits)
        
        // Check nonce is valid
        if analysis.nonce == 0 && validationRules.requireNonZeroNonce {
            issues.append("Nonce in MakerTraits should not be zero")
        }
        
        // Check expiry is reasonable
        if analysis.expiry > 0 {
            let maxExpiry = UInt32(validationRules.maxExpirySeconds)
            if analysis.expiry > maxExpiry {
                issues.append("Expiry time is too far in the future (max: \(maxExpiry) seconds)")
            }
        }
        
        return issues
    }
    
    private func validateSalt(_ order: RouterV6OrderInfo) -> [String] {
        var issues: [String] = []
        
        // Check salt is not zero
        if order.salt == BigUInt(0) {
            issues.append("Salt cannot be zero")
        }
        
        // Check salt is within 96-bit range (like 1inch SDK)
        let maxUint96 = BigUInt(2).power(96) - 1
        if order.salt > maxUint96 {
            issues.append("Salt exceeds 96-bit range (not SDK-style)")
        }
        
        return issues
    }
    
    // MARK: - Helper Methods
    
    private func validateEthereumAddress(_ address: String, name: String) -> String? {
        // Check format
        if !address.hasPrefix("0x") {
            return "\(name) address must start with '0x'"
        }
        
        if address.count != 42 {
            return "\(name) address must be 42 characters long (got \(address.count))"
        }
        
        // Check hex characters
        let hexChars = String(address.dropFirst(2))
        let hexCharacterSet = CharacterSet(charactersIn: "0123456789abcdefABCDEF")
        if hexChars.rangeOfCharacter(from: hexCharacterSet.inverted) != nil {
            return "\(name) address contains invalid hex characters"
        }
        
        // Check for zero address if enabled
        if validationRules.rejectZeroAddress && address.lowercased() == "0x0000000000000000000000000000000000000000" {
            return "\(name) cannot be zero address"
        }
        
        return nil
    }
    
    private func isKnownToken(_ address: String) -> Bool {
        // List of known token addresses (this would be more comprehensive in production)
        let knownTokens = [
            "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", // WMATIC on Polygon
            "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359", // USDC on Polygon
            "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2", // WETH on Ethereum
            "0xA0b86a33E6417c286d4190b2e4b6d4cd59F8Ae9c"  // USDC on Ethereum
        ]
        
        return knownTokens.contains { $0.lowercased() == address.lowercased() }
    }
}

// MARK: - Validation Rules Configuration

/// Configuration for validation rules and limits
struct OrderValidationRules {
    let enforceMaxAmounts: Bool
    let enforceReasonablePriceRatio: Bool
    let maxPriceRatio: Double
    let validateKnownTokens: Bool
    let requireNonZeroNonce: Bool
    let maxExpirySeconds: TimeInterval
    let rejectZeroAddress: Bool
    
    /// Standard validation rules for production
    static let standard = OrderValidationRules(
        enforceMaxAmounts: true,
        enforceReasonablePriceRatio: false, // Disabled to allow any price
        maxPriceRatio: 1_000_000.0,
        validateKnownTokens: false, // Disabled for flexibility
        requireNonZeroNonce: true,
        maxExpirySeconds: 86400 * 30, // 30 days
        rejectZeroAddress: true
    )
    
    /// Strict validation rules for high-security environments
    static let strict = OrderValidationRules(
        enforceMaxAmounts: true,
        enforceReasonablePriceRatio: true,
        maxPriceRatio: 10_000.0,
        validateKnownTokens: true,
        requireNonZeroNonce: true,
        maxExpirySeconds: 86400 * 7, // 7 days
        rejectZeroAddress: true
    )
    
    /// Relaxed validation rules for testing/development
    static let relaxed = OrderValidationRules(
        enforceMaxAmounts: false,
        enforceReasonablePriceRatio: false,
        maxPriceRatio: Double.infinity,
        validateKnownTokens: false,
        requireNonZeroNonce: false,
        maxExpirySeconds: Double.infinity,
        rejectZeroAddress: false
    )
}

// MARK: - Advanced Validation Strategies

/// Strategy pattern for different validation approaches
enum ValidationStrategy {
    case basic      // Only essential checks
    case standard   // Standard production validation
    case strict     // Maximum security validation
    case custom(OrderValidationRules)
}

/// Factory for creating validators with different strategies
class ValidatorFactory {
    
    static func createValidator(strategy: ValidationStrategy) -> OrderValidatorProtocol {
        switch strategy {
        case .basic:
            return OrderValidator(validationRules: .relaxed)
        case .standard:
            return OrderValidator(validationRules: .standard)
        case .strict:
            return OrderValidator(validationRules: .strict)
        case .custom(let rules):
            return OrderValidator(validationRules: rules)
        }
    }
}

// MARK: - Validation Result Extensions

extension ValidationResult {
    
    var description: String {
        if isValid {
            return "✅ Order validation passed"
        } else {
            return "❌ Order validation failed:\n" + issues.map { "  • \($0)" }.joined(separator: "\n")
        }
    }
    
    /// Get only critical issues that would prevent transaction submission
    var criticalIssues: [String] {
        return issues.filter { issue in
            issue.contains("cannot be zero") ||
            issue.contains("invalid") ||
            issue.contains("format") ||
            issue.contains("empty")
        }
    }
    
    /// Check if order has only warnings (can still be submitted)
    var hasOnlyWarnings: Bool {
        return !isValid && criticalIssues.isEmpty
    }
}