import Foundation
import web3swift
import Web3Core
import BigInt
import CryptoSwift

// Production-ready EIP-712 signing implementation for Router V6 using web3swift's SECP256K1
class EIP712SignerWeb3 {
    
    // EIP-712 domain separator for Router V6
    struct EIP712Domain {
        let name: String
        let version: String
        let chainId: BigUInt
        let verifyingContract: String
    }
    
    // Router V6 Order structure for EIP-712
    struct RouterV6Order {
        let salt: BigUInt
        let maker: String        // Address as hex string
        let receiver: String     // Address as hex string  
        let makerAsset: String   // Address as hex string
        let takerAsset: String   // Address as hex string
        let makingAmount: BigUInt
        let takingAmount: BigUInt
        let makerTraits: BigUInt
    }
    
    // Create EIP-712 typed data exactly like Go implementation
    static func createRouterV6TypedData(order: RouterV6Order, domain: EIP712Domain) -> [String: Any] {
        let types: [String: Any] = [
            "EIP712Domain": [
                ["name": "name", "type": "string"],
                ["name": "version", "type": "string"],
                ["name": "chainId", "type": "uint256"],
                ["name": "verifyingContract", "type": "address"]
            ],
            "Order": [
                ["name": "salt", "type": "uint256"],
                ["name": "maker", "type": "address"],
                ["name": "receiver", "type": "address"],
                ["name": "makerAsset", "type": "address"],
                ["name": "takerAsset", "type": "address"],
                ["name": "makingAmount", "type": "uint256"],
                ["name": "takingAmount", "type": "uint256"],
                ["name": "makerTraits", "type": "uint256"]
            ]
        ]
        
        let domainData: [String: Any] = [
            "name": domain.name,
            "version": domain.version,
            "chainId": domain.chainId.description,
            "verifyingContract": domain.verifyingContract
        ]
        
        // CRITICAL FIX: Working RouterV6Wallet uses hex addresses in EIP-712 message, NOT uint256!
        let message: [String: Any] = [
            "salt": order.salt.description,
            "maker": order.maker,
            "receiver": order.receiver,
            "makerAsset": order.makerAsset,
            "takerAsset": order.takerAsset,
            "makingAmount": order.makingAmount.description,
            "takingAmount": order.takingAmount.description,
            "makerTraits": order.makerTraits.description
        ]
        
        // DEBUG: Log exact EIP-712 message values for comparison
        print("🔍 EIP-712 Original Values:")
        print("   salt: \(order.salt.description)")
        print("   maker (hex): \(order.maker)")
        print("   receiver (hex): \(order.receiver)")
        print("   makerAsset (hex): \(order.makerAsset)")
        print("   takerAsset (hex): \(order.takerAsset)")
        print("   makingAmount: \(order.makingAmount.description)")
        print("   takingAmount: \(order.takingAmount.description)")
        print("   makerTraits: \(order.makerTraits.description)")
        
        print("✅ EIP-712 Message (matches working RouterV6Wallet exactly):")
        print("   Using hex addresses in EIP-712 message, NOT uint256")
        
        Task { @MainActor in
            // Log EIP-712 message values (removed shared instance dependency)
            // await RouterV6Manager.sharedInstance?.addLog("   salt: \(order.salt.description)")
            // await RouterV6Manager.sharedInstance?.addLog("   maker: \(order.maker)")
            // await RouterV6Manager.sharedInstance?.addLog("   receiver: \(order.receiver)")
            // await RouterV6Manager.sharedInstance?.addLog("   makerAsset: \(order.makerAsset)")
            // await RouterV6Manager.sharedInstance?.addLog("   takerAsset: \(order.takerAsset)")
            // await RouterV6Manager.sharedInstance?.addLog("   makingAmount: \(order.makingAmount.description)")
            // await RouterV6Manager.sharedInstance?.addLog("   takingAmount: \(order.takingAmount.description)")
            // await RouterV6Manager.sharedInstance?.addLog("   makerTraits: \(order.makerTraits.description)")
            // await RouterV6Manager.sharedInstance?.addLog("✅ EIP-712 Message (matches working RouterV6Wallet exactly)")
        }
        
        return [
            "types": types,
            "primaryType": "Order",
            "domain": domainData,
            "message": message
        ]
    }
    
    // Sign Router V6 order with web3swift's SECP256K1
    static func signRouterV6Order(
        order: RouterV6Order,
        domain: EIP712Domain,
        privateKey: String
    ) throws -> Data {
        // Create EIP712 typed data
        let eip712Data = createRouterV6TypedData(order: order, domain: domain)
        
        // Remove 0x prefix if present
        let cleanPrivateKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
        let privateKeyData = Data(hex: cleanPrivateKey)
        guard privateKeyData.count == 32 else {
            throw EIP712Error.invalidPrivateKey
        }
        
        // Use the existing EIP-712 implementation from EIP712Signer
        guard let types = eip712Data["types"] as? [String: Any],
              let domainData = eip712Data["domain"] as? [String: Any],
              let message = eip712Data["message"] as? [String: Any] else {
            throw EIP712Error.invalidTypedData
        }
        
        // Use the exact same EIP-712 implementation from EIP712Signer
        let structHash = try EIP712Signer.hashStruct(primaryType: "Order", data: message, types: types)
        let domainHash = try EIP712Signer.hashStruct(primaryType: "EIP712Domain", data: domainData, types: types)
        
        // Create final hash with EIP-191 prefix
        var finalHashData = Data()
        finalHashData.append(Data([0x19, 0x01])) // EIP-191 prefix
        finalHashData.append(domainHash)
        finalHashData.append(structHash)
        
        let finalHash = finalHashData.sha3(.keccak256)
        
        print("🔐 EIP-712 Hash Components:")
        print("   Domain Hash: 0x\(domainHash.toHexString())")
        print("   Struct Hash: 0x\(structHash.toHexString())")
        print("   Final Hash: 0x\(finalHash.toHexString())")
        
        // Also add to iOS debug logging system
        Task { @MainActor in
            // await RouterV6Manager.sharedInstance?.addLog("🔐 EIP-712 Hash Components:")
            // await RouterV6Manager.sharedInstance?.addLog("   Domain Hash: 0x\(domainHash.toHexString())")
            // await RouterV6Manager.sharedInstance?.addLog("   Struct Hash: 0x\(structHash.toHexString())")
            // await RouterV6Manager.sharedInstance?.addLog("   Final Hash: 0x\(finalHash.toHexString())")
        }
        
        // Sign with SECP256K1 from web3swift
        let signResult = SECP256K1.signForRecovery(
            hash: finalHash,
            privateKey: privateKeyData,
            useExtraEntropy: false
        )
        
        guard let serialized = signResult.serializedSignature else {
            throw EIP712Error.signingFailed
        }
        
        // Extract v from raw signature (last byte)
        guard let rawSig = signResult.rawSignature,
              rawSig.count == 65 else {
            throw EIP712Error.signingFailed
        }
        
        let v = rawSig[64]
        
        // Build full signature (r + s + v) - ensure exactly 65 bytes (EXACT COPY from working implementation)
        var fullSignature = Data()
        fullSignature.append(serialized) // r + s (64 bytes)
        fullSignature.append(v) // v (1 byte)
        
        // Ensure exactly 65 bytes (trim any extra bytes)
        if fullSignature.count > 65 {
            fullSignature = fullSignature.prefix(65)
        }
        
        print("🔐 SECP256K1 signature generated:")
        print("   r: 0x\(serialized.prefix(32).toHexString())")
        print("   s: 0x\(serialized.dropFirst(32).toHexString())")
        print("   v: \(v)")
        print("   Full signature length: \(fullSignature.count) bytes")
        
        return fullSignature
    }
    
    // Convert signature to EIP-2098 compact format (r, vs) - EXACT COPY from working implementation
    static func toCompactSignature(signature: Data) -> (r: Data, vs: Data) {
        print("🔧 Converting signature - Length: \(signature.count) bytes")
        
        guard signature.count == 65 else {
            print("❌ Invalid signature length: \(signature.count), expected 65")
            print("   Signature: 0x\(signature.toHexString())")
            return (Data(repeating: 0, count: 32), Data(repeating: 0, count: 32))
        }
        
        let r = signature.prefix(32)
        let s = signature.dropFirst(32).prefix(32)
        let v = signature[64]
        
        print("🔐 Signature components:")
        print("   r: 0x\(r.toHexString())")
        print("   s: 0x\(s.toHexString())")
        print("   v: \(v)")
        
        // Create vs according to EIP-2098
        var vs = Data(s)
        if v == 28 {
            vs[0] |= 0x80 // Set high bit for recovery when v == 28
            print("   Applied recovery bit for v=28")
        }
        
        print("🎯 EIP-2098 result:")
        print("   r: 0x\(r.toHexString())")
        print("   vs: 0x\(vs.toHexString())")
        
        return (Data(r), vs)
    }
    
    // Convert address to uint256 (critical for Router V6 EIP-712 compatibility)
    static func addressToUint256(_ address: String) throws -> BigUInt {
        let cleanAddress = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
        guard cleanAddress.count == 40 else {
            throw EIP712Error.invalidAddress
        }
        guard let result = BigUInt(cleanAddress, radix: 16) else {
            throw EIP712Error.invalidAddress
        }
        return result
    }
    
    // Hash struct according to EIP-712
    static func hashStruct(primaryType: String, data: [String: Any], types: [String: Any]) throws -> Data {
        let typeHash = try hashType(primaryType: primaryType, types: types)
        let encodedValues = try encodeData(primaryType: primaryType, data: data, types: types)
        
        var toHash = Data()
        toHash.append(typeHash)
        toHash.append(encodedValues)
        
        return toHash.sha3(.keccak256)
    }
    
    // Hash type string
    static func hashType(primaryType: String, types: [String: Any]) throws -> Data {
        let typeString = try encodeType(primaryType: primaryType, types: types)
        return typeString.data(using: .utf8)!.sha3(.keccak256)
    }
    
    // Encode type string
    static func encodeType(primaryType: String, types: [String: Any]) throws -> String {
        guard let fields = types[primaryType] as? [[String: String]] else {
            throw EIP712Error.invalidTypedData
        }
        
        let fieldStrings = fields.map { field in
            "\(field["type"]!) \(field["name"]!)"
        }.joined(separator: ",")
        
        return "\(primaryType)(\(fieldStrings))"
    }
    
    // Encode data according to type
    static func encodeData(primaryType: String, data: [String: Any], types: [String: Any]) throws -> Data {
        guard let fields = types[primaryType] as? [[String: String]] else {
            throw EIP712Error.invalidTypedData
        }
        
        var encoded = Data()
        
        for field in fields {
            let fieldName = field["name"]!
            let fieldType = field["type"]!
            
            if let value = data[fieldName] {
                encoded.append(try encodeValue(value: value, type: fieldType, types: types))
            } else {
                // Default value for missing fields
                encoded.append(Data(repeating: 0, count: 32))
            }
        }
        
        return encoded
    }
    
    // Encode single value
    static func encodeValue(value: Any, type: String, types: [String: Any]) throws -> Data {
        if type == "address" {
            // Address encoding
            if let address = value as? String {
                let cleanAddress = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
                let addressData = Data(hex: cleanAddress)
                return Data(repeating: 0, count: 12) + addressData
            }
        } else if type == "uint256" {
            // Uint256 encoding
            if let stringValue = value as? String,
               let bigInt = BigUInt(stringValue) {
                var data = bigInt.serialize()
                // Pad to 32 bytes
                if data.count < 32 {
                    data = Data(repeating: 0, count: 32 - data.count) + data
                }
                return data
            }
        } else if type == "string" {
            // String encoding - return keccak256 hash
            if let stringValue = value as? String {
                return stringValue.data(using: .utf8)!.sha3(.keccak256)
            }
        }
        
        // Default: return 32 zero bytes
        return Data(repeating: 0, count: 32)
    }
}

// CompactSignature is already defined in RouterV6Manager.swift

// EIP-712 errors
enum EIP712Error: Error {
    case invalidPrivateKey
    case invalidTypedData
    case signingFailed
    case invalidType
    case missingField
    case invalidValue
    case unsupportedType
    case invalidAddress
}

// EIP-712 signer helper (exact copy from working RouterV6Wallet)
class EIP712Signer {
    
    // Hash struct according to EIP-712
    static func hashStruct(primaryType: String, data: [String: Any], types: [String: Any]) throws -> Data {
        let typeHash = try hashType(primaryType: primaryType, types: types)
        let encodedValues = try encodeData(primaryType: primaryType, data: data, types: types)
        
        var toHash = Data()
        toHash.append(typeHash)
        toHash.append(encodedValues)
        
        return toHash.sha3(.keccak256)
    }
    
    // Hash type string
    static func hashType(primaryType: String, types: [String: Any]) throws -> Data {
        let typeString = try encodeType(primaryType: primaryType, types: types)
        return typeString.data(using: .utf8)!.sha3(.keccak256)
    }
    
    // Encode type string
    static func encodeType(primaryType: String, types: [String: Any]) throws -> String {
        guard let fields = types[primaryType] as? [[String: String]] else {
            throw EIP712Error.invalidTypedData
        }
        
        let fieldStrings = fields.map { field in
            "\(field["type"]!) \(field["name"]!)"
        }.joined(separator: ",")
        
        return "\(primaryType)(\(fieldStrings))"
    }
    
    // Encode data according to type
    static func encodeData(primaryType: String, data: [String: Any], types: [String: Any]) throws -> Data {
        guard let fields = types[primaryType] as? [[String: String]] else {
            throw EIP712Error.invalidTypedData
        }
        
        var encoded = Data()
        
        for field in fields {
            let fieldName = field["name"]!
            let fieldType = field["type"]!
            
            if let value = data[fieldName] {
                encoded.append(try encodeValue(value: value, type: fieldType, types: types))
            } else {
                // Default value for missing fields
                encoded.append(Data(repeating: 0, count: 32))
            }
        }
        
        return encoded
    }
    
    // Encode single value
    static func encodeValue(value: Any, type: String, types: [String: Any]) throws -> Data {
        if type == "address" {
            // Address encoding
            if let address = value as? String {
                let cleanAddress = address.hasPrefix("0x") ? String(address.dropFirst(2)) : address
                let addressData = Data(hex: cleanAddress)
                return Data(repeating: 0, count: 12) + addressData
            }
        } else if type == "uint256" {
            // Uint256 encoding
            if let stringValue = value as? String,
               let bigInt = BigUInt(stringValue) {
                var data = bigInt.serialize()
                // Pad to 32 bytes
                if data.count < 32 {
                    data = Data(repeating: 0, count: 32 - data.count) + data
                }
                return data
            }
        } else if type == "string" {
            // String encoding - return keccak256 hash
            if let stringValue = value as? String {
                return stringValue.data(using: .utf8)!.sha3(.keccak256)
            }
        }
        
        // Default: return 32 zero bytes
        return Data(repeating: 0, count: 32)
    }
}