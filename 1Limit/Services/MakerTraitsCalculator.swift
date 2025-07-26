//
//  MakerTraitsCalculator.swift
//  1Limit
//
//  Calculates Router V6 MakerTraits with proper bit positioning and flags
//

import Foundation
import BigInt

/// Concrete implementation of MakerTraits calculation for Router V6
class MakerTraitsCalculator: MakerTraitsCalculatorProtocol {
    
    // MARK: - MakerTraits Bit Positions (Router V6 Specification)
    
    private enum BitPosition {
        static let nonceStart: Int = 120      // Nonce stored in bits 120-160 (40 bits)
        static let expiryStart: Int = 160     // Expiry stored in bits 160-192 (32 bits)
        static let allowPartialFills: Int = 80    // ALLOW_PARTIAL_FILLS flag
        static let allowMultipleFills: Int = 81   // ALLOW_MULTIPLE_FILLS flag
        static let hasExtension: Int = 249        // HAS_EXTENSION_FLAG
        static let postInteraction: Int = 251     // POST_INTERACTION_CALL_FLAG
        static let allowPartialFillsBit253: Int = 253 // Alternative ALLOW_PARTIAL_FILLS position
    }
    
    // MARK: - Properties
    
    private let configuration: MakerTraitsConfiguration
    
    // MARK: - Initialization
    
    init(configuration: MakerTraitsConfiguration = .default) {
        self.configuration = configuration
    }
    
    // MARK: - MakerTraitsCalculatorProtocol Implementation
    
    /// Calculate maker traits exactly like SwiftOrderSubmitter working implementation
    func calculateMakerTraitsV6(nonce: UInt64, expiry: UInt32) -> BigUInt {
        var traits = BigUInt(0)
        
        // CRITICAL: Set nonce in bits 120-160 (40 bits for nonce)
        let nonceBits = BigUInt(nonce) << BitPosition.nonceStart
        traits |= nonceBits
        
        // Add expiry in bits 160-192 (32 bits) - MATCH working implementation exactly
        let expiryBits = BigUInt(expiry) << BitPosition.expiryStart
        traits |= expiryBits
        
        // Add configuration flags if enabled
        if configuration.allowPartialFills {
            if configuration.useAlternativePartialFillsBit {
                traits |= BigUInt(1) << BitPosition.allowPartialFillsBit253
            } else {
                traits |= BigUInt(1) << BitPosition.allowPartialFills
            }
        }
        
        if configuration.allowMultipleFills {
            traits |= BigUInt(1) << BitPosition.allowMultipleFills
        }
        
        if configuration.hasExtension {
            traits |= BigUInt(1) << BitPosition.hasExtension
        }
        
        if configuration.hasPostInteraction {
            traits |= BigUInt(1) << BitPosition.postInteraction
        }
        
        // Debug logging for comparison with working implementation
        logTraitsCalculation(nonce: nonce, expiry: expiry, nonceBits: nonceBits, 
                           expiryBits: expiryBits, finalTraits: traits)
        
        return traits
    }
    
    // MARK: - Private Helper Methods
    
    private func logTraitsCalculation(
        nonce: UInt64,
        expiry: UInt32,
        nonceBits: BigUInt,
        expiryBits: BigUInt,
        finalTraits: BigUInt
    ) {
        print("🔍 DEBUG MakerTraits calculation:")
        print("   Nonce: \(nonce) (40-bit)")
        print("   Expiry: \(expiry) (32-bit)")
        print("   Nonce << 120: \(nonceBits)")
        print("   Expiry << 160: \(expiryBits)")
        print("   Configuration: \(configuration)")
        print("   Final traits: \(finalTraits)")
    }
}

// MARK: - MakerTraits Configuration

/// Configuration object for MakerTraits calculation
struct MakerTraitsConfiguration {
    let allowPartialFills: Bool
    let allowMultipleFills: Bool
    let hasExtension: Bool
    let hasPostInteraction: Bool
    let useAlternativePartialFillsBit: Bool
    
    /// Default configuration matching working implementation
    static let `default` = MakerTraitsConfiguration(
        allowPartialFills: false,
        allowMultipleFills: false,
        hasExtension: false,
        hasPostInteraction: false,
        useAlternativePartialFillsBit: false
    )
    
    /// Configuration for advanced order types
    static let advanced = MakerTraitsConfiguration(
        allowPartialFills: true,
        allowMultipleFills: true,
        hasExtension: false,
        hasPostInteraction: false,
        useAlternativePartialFillsBit: true
    )
    
    /// Configuration for orders with extensions
    static let withExtensions = MakerTraitsConfiguration(
        allowPartialFills: true,
        allowMultipleFills: false,
        hasExtension: true,
        hasPostInteraction: true,
        useAlternativePartialFillsBit: false
    )
}

// MARK: - MakerTraits Analyzer

/// Utility class for analyzing and decomposing MakerTraits values
class MakerTraitsAnalyzer {
    
    /// Decompose MakerTraits back into individual components
    static func analyzeMakerTraits(_ traits: BigUInt) -> MakerTraitsAnalysis {
        // Extract nonce (bits 120-160)
        let nonceMask = BigUInt((1 << 40) - 1) // 40-bit mask
        let nonce = UInt64((traits >> 120) & nonceMask)
        
        // Extract expiry (bits 160-192)
        let expiryMask = BigUInt((1 << 32) - 1) // 32-bit mask
        let expiry = UInt32((traits >> 160) & expiryMask)
        
        // Extract flags
        let allowPartialFills = (traits & (BigUInt(1) << 80)) != 0
        let allowMultipleFills = (traits & (BigUInt(1) << 81)) != 0
        let hasExtension = (traits & (BigUInt(1) << 249)) != 0
        let hasPostInteraction = (traits & (BigUInt(1) << 251)) != 0
        let allowPartialFillsBit253 = (traits & (BigUInt(1) << 253)) != 0
        
        return MakerTraitsAnalysis(
            nonce: nonce,
            expiry: expiry,
            allowPartialFills: allowPartialFills,
            allowMultipleFills: allowMultipleFills,
            hasExtension: hasExtension,
            hasPostInteraction: hasPostInteraction,
            allowPartialFillsBit253: allowPartialFillsBit253
        )
    }
}

/// Result of MakerTraits analysis
struct MakerTraitsAnalysis {
    let nonce: UInt64
    let expiry: UInt32
    let allowPartialFills: Bool
    let allowMultipleFills: Bool
    let hasExtension: Bool
    let hasPostInteraction: Bool
    let allowPartialFillsBit253: Bool
    
    var description: String {
        return """
        MakerTraits Analysis:
          Nonce: \(nonce) (slot: \(nonce >> 8), bit: \(nonce & 0xff))
          Expiry: \(expiry) seconds
          Allow Partial Fills: \(allowPartialFills)
          Allow Multiple Fills: \(allowMultipleFills)
          Has Extension: \(hasExtension)
          Has Post Interaction: \(hasPostInteraction)
          Alt Partial Fills (bit 253): \(allowPartialFillsBit253)
        """
    }
}