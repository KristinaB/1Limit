//
//  AddressValidationService.swift
//  1Limit
//
//  Service for validating Ethereum addresses
//

import Foundation
import SwiftUI

/// Address validation result
struct AddressValidationResult {
    let isValid: Bool
    let normalizedAddress: String?
    let errorMessage: String?
    
    static func valid(_ address: String) -> AddressValidationResult {
        return AddressValidationResult(
            isValid: true,
            normalizedAddress: address,
            errorMessage: nil
        )
    }
    
    static func invalid(_ message: String) -> AddressValidationResult {
        return AddressValidationResult(
            isValid: false,
            normalizedAddress: nil,
            errorMessage: message
        )
    }
}

/// Protocol for address validation
protocol AddressValidationProtocol {
    func validateAddress(_ address: String) -> AddressValidationResult
    func isValidEthereumAddress(_ address: String) -> Bool
}

/// Address validation service
class AddressValidationService: ObservableObject, AddressValidationProtocol {
    
    /// Validate an Ethereum address
    func validateAddress(_ address: String) -> AddressValidationResult {
        let trimmedAddress = address.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check empty
        guard !trimmedAddress.isEmpty else {
            return .invalid("Please enter a recipient address")
        }
        
        // Check basic format
        guard trimmedAddress.hasPrefix("0x") else {
            return .invalid("Address must start with '0x'")
        }
        
        // Check length (42 characters: 0x + 40 hex digits)
        guard trimmedAddress.count == 42 else {
            return .invalid("Address must be 42 characters long")
        }
        
        // Check hex characters
        let hexPart = String(trimmedAddress.dropFirst(2))
        guard hexPart.allSatisfy({ $0.isHexDigit }) else {
            return .invalid("Address contains invalid characters")
        }
        
        // Check not zero address
        let zeroAddress = "0x0000000000000000000000000000000000000000"
        guard trimmedAddress.lowercased() != zeroAddress else {
            return .invalid("Cannot send to zero address")
        }
        
        // Normalize to lowercase (addresses are case-insensitive)
        let normalizedAddress = trimmedAddress.lowercased()
        return .valid(normalizedAddress)
    }
    
    /// Quick check if address is valid Ethereum format
    func isValidEthereumAddress(_ address: String) -> Bool {
        return validateAddress(address).isValid
    }
}

/// Mock service for testing
class MockAddressValidationService: AddressValidationProtocol {
    var shouldReturnValid = true
    var customErrorMessage = "Invalid address"
    
    func validateAddress(_ address: String) -> AddressValidationResult {
        if shouldReturnValid {
            return .valid(address.lowercased())
        } else {
            return .invalid(customErrorMessage)
        }
    }
    
    func isValidEthereumAddress(_ address: String) -> Bool {
        return shouldReturnValid
    }
}

extension Character {
    var isHexDigit: Bool {
        return ("0"..."9").contains(self) || ("a"..."f").contains(self) || ("A"..."F").contains(self)
    }
}