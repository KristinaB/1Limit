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
        
        // Hash the struct data using existing functions
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
        
        // Sign with SECP256K1 from web3swift
        let signResult = SECP256K1.signForRecovery(
            hash: finalHash,
            privateKey: privateKeyData,
            useExtraEntropy: false
        )
        
        // Extract raw signature (65 bytes: r + s + v)
        guard let rawSig = signResult.rawSignature,
              rawSig.count == 65 else {
            throw EIP712Error.signingFailed
        }
        
        let v = rawSig[64]
        print("🔑 Signature v: \(v)")
        
        // Return full 65-byte signature (r + s + v)
        return rawSig
    }
    
    // Convert standard signature to EIP-2098 compact format
    static func toCompactSignature(signature: Data) -> CompactSignature {
        guard signature.count == 65 else {
            fatalError("Invalid signature length")
        }
        
        let r = signature.prefix(32)
        let s = signature.dropFirst(32).prefix(32)
        let v = signature[64]
        
        // Create vs by setting the high bit of s based on v
        var vs = Data(s)
        if v == 28 {
            vs[0] |= 0x80
        }
        
        return CompactSignature(r: r, vs: vs)
    }
}

// CompactSignature is already defined in RouterV6Manager.swift

// EIP-712 errors
enum EIP712Error: Error {
    case invalidPrivateKey
    case invalidTypedData
    case signingFailed
}

// EIP-712 signer helper (needed for struct hashing)
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