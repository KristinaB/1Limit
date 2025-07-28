//
//  WalletGenerator.swift
//  1Limit
//
//  BIP39 mnemonic wallet generation with secure keychain storage 🔐✨
//

import Foundation
import web3swift
import Web3Core
import CryptoKit
import Security
import LocalAuthentication

/// Result of wallet generation
struct GeneratedWallet {
    let mnemonic: [String]
    let address: String
    let privateKey: String
    let publicKey: String
    let createdAt: Date
    
    var mnemonicString: String {
        return mnemonic.joined(separator: " ")
    }
    
    var walletData: WalletData {
        return WalletData(address: address, privateKey: privateKey)
    }
}

/// Wallet generation errors
enum WalletGenerationError: LocalizedError {
    case mnemonicGenerationFailed
    case keyDerivationFailed
    case keychainStorageFailed
    case biometricAuthFailed
    case invalidMnemonic
    
    var errorDescription: String? {
        switch self {
        case .mnemonicGenerationFailed:
            return "Failed to generate BIP39 mnemonic phrase"
        case .keyDerivationFailed:
            return "Failed to derive private key from mnemonic"
        case .keychainStorageFailed:
            return "Failed to store wallet in keychain securely"
        case .biometricAuthFailed:
            return "Biometric authentication failed"
        case .invalidMnemonic:
            return "Invalid mnemonic phrase provided"
        }
    }
}

/// Secure wallet generation service using BIP39 standard
@MainActor
class WalletGenerator: ObservableObject {
    
    // MARK: - Properties
    
    @Published var isGenerating = false
    @Published var lastError: WalletGenerationError?
    
    private let keychainService = "com.1limit.wallet"
    private let mnemonicKey = "user_mnemonic"
    private let walletDataKey = "user_wallet_data"
    
    // MARK: - Public Methods
    
    /// Generate a new BIP39 wallet with 12-word mnemonic
    func generateNewWallet() async throws -> GeneratedWallet {
        isGenerating = true
        lastError = nil
        
        defer { isGenerating = false }
        
        do {
            print("🎲 Generating new BIP39 wallet...")
            
            // Generate 12-word BIP39 mnemonic using web3swift
            guard let mnemonics = try? BIP39.generateMnemonics(bitsOfEntropy: 128) else {
                throw WalletGenerationError.mnemonicGenerationFailed
            }
            
            let mnemonicWords = mnemonics.components(separatedBy: " ")
            guard mnemonicWords.count == 12 else {
                throw WalletGenerationError.mnemonicGenerationFailed
            }
            
            print("✅ Generated 12-word mnemonic")
            
            // Derive wallet from mnemonic
            guard let keystore = try? BIP32Keystore(mnemonics: mnemonics, password: "", mnemonicsPassword: ""),
                  let ethereumAddress = keystore.addresses?.first,
                  let privateKeyData = try? keystore.UNSAFE_getPrivateKeyData(password: "", account: ethereumAddress) else {
                throw WalletGenerationError.keyDerivationFailed
            }
            
            let address = ethereumAddress.address
            let privateKey = "0x" + privateKeyData.toHexString()
            let publicKey = try derivePublicKey(from: privateKeyData)
            
            print("🔑 Derived wallet address: \(maskAddress(address))")
            
            let generatedWallet = GeneratedWallet(
                mnemonic: mnemonicWords,
                address: address,
                privateKey: privateKey,
                publicKey: publicKey,
                createdAt: Date()
            )
            
            return generatedWallet
            
        } catch let error as WalletGenerationError {
            lastError = error
            throw error
        } catch {
            print("❌ Wallet generation failed: \(error)")
            let walletError = WalletGenerationError.mnemonicGenerationFailed
            lastError = walletError
            throw walletError
        }
    }
    
    /// Import wallet from existing BIP39 mnemonic phrase
    func importWalletFromMnemonic(_ mnemonicWords: [String]) async throws -> GeneratedWallet {
        isGenerating = true
        lastError = nil
        
        defer { isGenerating = false }
        
        do {
            print("📥 Importing wallet from mnemonic...")
            
            // Validate mnemonic
            guard mnemonicWords.count == 12 else {
                throw WalletGenerationError.invalidMnemonic
            }
            
            let mnemonicString = mnemonicWords.joined(separator: " ")
            
            // Validate BIP39 mnemonic
            guard BIP39.mnemonicsToEntropy(mnemonicString) != nil else {
                throw WalletGenerationError.invalidMnemonic
            }
            
            print("✅ Valid 12-word BIP39 mnemonic")
            
            // Derive wallet from mnemonic
            guard let keystore = try? BIP32Keystore(mnemonics: mnemonicString, password: "", mnemonicsPassword: ""),
                  let ethereumAddress = keystore.addresses?.first,
                  let privateKeyData = try? keystore.UNSAFE_getPrivateKeyData(password: "", account: ethereumAddress) else {
                throw WalletGenerationError.keyDerivationFailed
            }
            
            let address = ethereumAddress.address
            let privateKey = "0x" + privateKeyData.toHexString()
            let publicKey = try derivePublicKey(from: privateKeyData)
            
            print("🔑 Imported wallet address: \(maskAddress(address))")
            
            let importedWallet = GeneratedWallet(
                mnemonic: mnemonicWords,
                address: address,
                privateKey: privateKey,
                publicKey: publicKey,
                createdAt: Date()
            )
            
            return importedWallet
            
        } catch let error as WalletGenerationError {
            lastError = error
            throw error
        } catch {
            print("❌ Wallet import failed: \(error)")
            let walletError = WalletGenerationError.invalidMnemonic
            lastError = walletError
            throw walletError
        }
    }
    
    /// Securely store wallet in iOS keychain
    func storeWalletSecurely(_ wallet: GeneratedWallet, requireBiometric: Bool = true) async throws {
        print("🔒 Storing wallet securely in keychain...")
        
        do {
            // Store mnemonic with biometric protection if requested
            try await storeInKeychain(
                key: mnemonicKey,
                data: wallet.mnemonicString.data(using: .utf8)!,
                requireBiometric: requireBiometric
            )
            
            // Store wallet data (address + private key) with biometric protection
            let walletDataJSON = try JSONEncoder().encode(wallet.walletData)
            try await storeInKeychain(
                key: walletDataKey,
                data: walletDataJSON,
                requireBiometric: requireBiometric
            )
            
            print("✅ Wallet stored securely in keychain")
            
        } catch {
            print("❌ Failed to store wallet in keychain: \(error)")
            throw WalletGenerationError.keychainStorageFailed
        }
    }
    
    /// Load stored wallet from keychain
    func loadStoredWallet() async throws -> GeneratedWallet? {
        print("🔍 Loading stored wallet from keychain...")
        
        do {
            // Load mnemonic
            guard let mnemonicData = try await loadFromKeychain(key: mnemonicKey),
                  let mnemonicString = String(data: mnemonicData, encoding: .utf8) else {
                print("📝 No stored mnemonic found")
                return nil
            }
            
            // Load wallet data
            guard let walletDataJSON = try await loadFromKeychain(key: walletDataKey),
                  let walletData = try? JSONDecoder().decode(WalletData.self, from: walletDataJSON) else {
                print("📝 No stored wallet data found")
                return nil
            }
            
            let mnemonicWords = mnemonicString.components(separatedBy: " ")
            guard mnemonicWords.count == 12 else {
                throw WalletGenerationError.invalidMnemonic
            }
            
            // Derive public key for completeness
            let privateKeyHex = String(walletData.privateKey.dropFirst(2))
            guard let privateKeyData = Data(hex: privateKeyHex) else {
                throw WalletGenerationError.keyDerivationFailed
            }
            
            let publicKey = try derivePublicKey(from: privateKeyData)
            
            let storedWallet = GeneratedWallet(
                mnemonic: mnemonicWords,
                address: walletData.address,
                privateKey: walletData.privateKey,
                publicKey: publicKey,
                createdAt: Date() // Note: Creation date not stored, using current date
            )
            
            print("✅ Loaded stored wallet: \(maskAddress(walletData.address))")
            return storedWallet
            
        } catch {
            print("❌ Failed to load wallet from keychain: \(error)")
            return nil
        }
    }
    
    /// Check if wallet is stored in keychain
    func hasStoredWallet() async -> Bool {
        do {
            let mnemonicData = try await loadFromKeychain(key: mnemonicKey)
            let walletData = try await loadFromKeychain(key: walletDataKey)
            return mnemonicData != nil && walletData != nil
        } catch {
            return false
        }
    }
    
    /// Clear stored wallet from keychain (use with caution!)
    func clearStoredWallet() async throws {
        print("🗑️ Clearing stored wallet from keychain...")
        
        try await deleteFromKeychain(key: mnemonicKey)
        try await deleteFromKeychain(key: walletDataKey)
        
        print("✅ Wallet cleared from keychain")
    }
    
    // MARK: - Private Helper Methods
    
    private func derivePublicKey(from privateKeyData: Data) throws -> String {
        // Use CryptoKit to derive public key from private key
        let privateKey = try P256.Signing.PrivateKey(rawRepresentation: privateKeyData.prefix(32))
        let publicKeyData = privateKey.publicKey.compressedRepresentation
        return "0x" + publicKeyData.toHexString()
    }
    
    private func maskAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    // MARK: - Keychain Operations
    
    private func storeInKeychain(key: String, data: Data, requireBiometric: Bool) async throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        if requireBiometric {
            // Add biometric authentication requirement
            let access = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
                .biometryAny,
                nil
            )
            query[kSecAttrAccessControl as String] = access
        }
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw WalletGenerationError.keychainStorageFailed
        }
    }
    
    private func loadFromKeychain(key: String) async throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            throw WalletGenerationError.keychainStorageFailed
        }
        
        return result as? Data
    }
    
    private func deleteFromKeychain(key: String) async throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw WalletGenerationError.keychainStorageFailed
        }
    }
}

// MARK: - Extensions

extension Data {
    func toHexString() -> String {
        return map { String(format: "%02hhx", $0) }.joined()
    }
    
    init?(hex: String) {
        let len = hex.count / 2
        var data = Data(capacity: len)
        var i = hex.startIndex
        for _ in 0..<len {
            let j = hex.index(i, offsetBy: 2)
            let bytes = hex[i..<j]
            if var num = UInt8(bytes, radix: 16) {
                data.append(&num, count: 1)
            } else {
                return nil
            }
            i = j
        }
        self = data
    }
}

// MARK: - Shared Instance

extension WalletGenerator {
    static let shared = WalletGenerator()
}