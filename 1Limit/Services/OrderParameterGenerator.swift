//
//  OrderParameterGenerator.swift
//  1Limit
//
//  Generates Router V6 order parameters (salt, nonce) with proper randomization
//

import Foundation
import BigInt
import Security

/// Concrete implementation of order parameter generation for Router V6
class OrderParameterGenerator: OrderParameterGeneratorProtocol {
    
    // MARK: - Properties
    
    private let secureRandom: SecureRandomGeneratorProtocol
    
    // MARK: - Initialization
    
    init(secureRandom: SecureRandomGeneratorProtocol = SecureRandomGenerator()) {
        self.secureRandom = secureRandom
    }
    
    // MARK: - OrderParameterGeneratorProtocol Implementation
    
    /// Generate 96-bit salt exactly like 1inch SDK (matching Go implementation)
    func generateSDKStyleSalt() -> BigUInt {
        guard let randomData = secureRandom.generateRandomData(length: 12) else {
            // Fallback to deterministic generation if secure random fails
            return BigUInt(UInt64.random(in: 1...UInt64.max))
        }
        
        let salt = BigUInt(randomData)
        // Ensure it's within 96-bit range
        let maxUint96 = BigUInt(2).power(96) - 1
        return salt & maxUint96
    }
    
    /// Generate 40-bit nonce for MakerTraits (matching Go implementation)
    func generateRandomNonce() -> UInt64 {
        guard let randomData = secureRandom.generateRandomData(length: 5) else {
            // Fallback to standard random if secure random fails
            return UInt64.random(in: 1...UInt64.max) & 0xFFFFFFFFFF
        }
        
        // Convert to UInt64 and mask to 40 bits
        let nonce = randomData.withUnsafeBytes { $0.load(as: UInt64.self) }
        return nonce & 0xFFFFFFFFFF // 40-bit mask
    }
}

// MARK: - Secure Random Generation Protocol

/// Protocol for secure random number generation (allows for testing)
protocol SecureRandomGeneratorProtocol {
    func generateRandomData(length: Int) -> Data?
}

/// Concrete implementation using Security framework
class SecureRandomGenerator: SecureRandomGeneratorProtocol {
    
    func generateRandomData(length: Int) -> Data? {
        var data = Data(count: length)
        let result = data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.bindMemory(to: UInt8.self).baseAddress else {
                return errSecAllocate
            }
            return SecRandomCopyBytes(kSecRandomDefault, length, baseAddress)
        }
        return result == errSecSuccess ? data : nil
    }
}

// MARK: - Parameter Generation Strategy

/// Strategy pattern for different parameter generation approaches
enum ParameterGenerationStrategy {
    case production  // Uses secure random generation
    case testing     // Uses deterministic generation for testing
    case development // Uses pseudo-random for development
}

/// Factory for creating parameter generators with different strategies
class ParameterGeneratorFactory {
    
    static func createGenerator(strategy: ParameterGenerationStrategy) -> OrderParameterGeneratorProtocol {
        switch strategy {
        case .production:
            return OrderParameterGenerator(secureRandom: SecureRandomGenerator())
        case .testing:
            return OrderParameterGenerator(secureRandom: DeterministicRandomGenerator())
        case .development:
            return OrderParameterGenerator(secureRandom: PseudoRandomGenerator())
        }
    }
}

// MARK: - Alternative Random Generators

/// Deterministic random generator for testing
class DeterministicRandomGenerator: SecureRandomGeneratorProtocol {
    private var seed: UInt64
    
    init(seed: UInt64 = 12345) {
        self.seed = seed
    }
    
    func generateRandomData(length: Int) -> Data? {
        var data = Data(count: length)
        for i in 0..<length {
            seed = seed &* 1103515245 &+ 12345  // Linear congruential generator
            data[i] = UInt8(seed >> 8)
        }
        return data
    }
}

/// Pseudo-random generator for development
class PseudoRandomGenerator: SecureRandomGeneratorProtocol {
    
    func generateRandomData(length: Int) -> Data? {
        var data = Data(count: length)
        for i in 0..<length {
            data[i] = UInt8.random(in: 0...255)
        }
        return data
    }
}