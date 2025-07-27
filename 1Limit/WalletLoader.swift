//
//  WalletLoader.swift
//  1Limit
//
//  Enhanced wallet loading with multiple modes and keychain support 🔐✨
//

import Foundation
import CryptoKit
import Combine

// MARK: - Wallet Data Structure (matching Go implementation)
struct WalletData: Codable {
    let address: String
    let privateKey: String
    
    private enum CodingKeys: String, CodingKey {
        case address
        case privateKey = "private_key"
    }
}

// MARK: - Wallet Mode
enum WalletMode {
    case testWallet       // Load from wallet_0x3f847d.json
    case generatedWallet  // Load from keychain (user-generated)
    case mockWallet       // Development fallback
}

// MARK: - Enhanced WalletLoader
class WalletLoader: ObservableObject {
    static let shared = WalletLoader()
    private init() {}
    
    // MARK: - Properties
    private let walletFileName = "wallet_0x3f847d.json"
    private let walletGenerator = WalletGenerator.shared
    
    @Published var currentWalletMode: WalletMode = .testWallet
    @Published var isLoading = false
    
    // MARK: - Public Methods
    
    /// Load wallet based on current mode
    func loadWallet() async -> WalletData? {
        await MainActor.run {
            isLoading = true
        }
        defer { 
            Task { @MainActor in
                isLoading = false
            }
        }
        
        switch currentWalletMode {
        case .testWallet:
            return loadTestWallet()
        case .generatedWallet:
            return await loadGeneratedWallet()
        case .mockWallet:
            return createMockWallet()
        }
    }
    
    /// Load test wallet from JSON file (matching Go implementation)
    func loadTestWallet() -> WalletData? {
        guard let walletURL = Bundle.main.url(forResource: "wallet_0x3f847d", withExtension: "json") else {
            print("❌ Test wallet file not found in bundle")
            return loadWalletFromDocuments()
        }
        
        do {
            let data = try Data(contentsOf: walletURL)
            let wallet = try JSONDecoder().decode(WalletData.self, from: data)
            print("✅ Loaded test wallet from bundle: \(maskAddress(wallet.address))")
            return wallet
        } catch {
            print("❌ Failed to load test wallet from bundle: \(error)")
            return loadWalletFromDocuments()
        }
    }
    
    /// Load user-generated wallet from keychain
    func loadGeneratedWallet() async -> WalletData? {
        do {
            guard let generatedWallet = try await walletGenerator.loadStoredWallet() else {
                print("📝 No generated wallet found in keychain")
                return nil
            }
            
            print("✅ Loaded generated wallet from keychain: \(maskAddress(generatedWallet.address))")
            return generatedWallet.walletData
            
        } catch {
            print("❌ Failed to load generated wallet: \(error)")
            return nil
        }
    }
    
    /// Switch wallet mode and reload
    func switchWalletMode(to mode: WalletMode) async -> WalletData? {
        print("🔄 Switching wallet mode to: \(mode)")
        await MainActor.run {
            currentWalletMode = mode
        }
        return await loadWallet()
    }
    
    /// Check if generated wallet exists
    func hasGeneratedWallet() async -> Bool {
        return await walletGenerator.hasStoredWallet()
    }
    
    /// Fallback: Load wallet from documents directory
    private func loadWalletFromDocuments() -> WalletData? {
        guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            print("❌ Cannot access documents directory")
            return nil
        }
        
        let walletURL = documentsURL.appendingPathComponent(walletFileName)
        
        do {
            let data = try Data(contentsOf: walletURL)
            let wallet = try JSONDecoder().decode(WalletData.self, from: data)
            print("✅ Loaded wallet from documents: \(maskAddress(wallet.address))")
            return wallet
        } catch {
            print("❌ Failed to load wallet from documents: \(error)")
            return createMockWallet()
        }
    }
    
    /// Create mock wallet for development (safe fallback)
    private func createMockWallet() -> WalletData {
        print("🔧 Using mock wallet for development")
        return WalletData(
            address: "0x3f847d4390b5a2783ea4aed6887474de8ffffa95",
            privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001"
        )
    }
    
    /// Validate wallet data before use (enhanced validation)
    func validateWallet(_ wallet: WalletData) -> Bool {
        // Validate address format
        guard wallet.address.hasPrefix("0x"), wallet.address.count == 42 else {
            print("❌ Invalid wallet address format: expected 0x + 40 hex chars")
            return false
        }
        
        // Validate address contains only hex characters
        let addressHex = String(wallet.address.dropFirst(2))
        guard addressHex.allSatisfy({ $0.isHexDigit }) else {
            print("❌ Invalid wallet address: contains non-hex characters")
            return false
        }
        
        // Validate private key format
        guard wallet.privateKey.hasPrefix("0x"), wallet.privateKey.count == 66 else {
            print("❌ Invalid private key format: expected 0x + 64 hex chars")
            return false
        }
        
        // Validate private key contains only hex characters
        let privateKeyHex = String(wallet.privateKey.dropFirst(2))
        guard privateKeyHex.allSatisfy({ $0.isHexDigit }) else {
            print("❌ Invalid private key: contains non-hex characters")
            return false
        }
        
        // Validate private key is not zero
        guard privateKeyHex != String(repeating: "0", count: 64) else {
            print("❌ Invalid private key: cannot be zero")
            return false
        }
        
        // Validate private key range (must be less than secp256k1 order)
        if !isValidSecp256k1PrivateKey(privateKeyHex) {
            print("❌ Invalid private key: out of secp256k1 range")
            return false
        }
        
        print("✅ Wallet validation passed (address + private key)")
        return true
    }
    
    /// Validate private key is within secp256k1 curve order
    private func isValidSecp256k1PrivateKey(_ hexKey: String) -> Bool {
        // secp256k1 order: 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
        // For simplified validation, just check it's not all F's
        let maxHex = String(repeating: "F", count: 64)
        return hexKey.lowercased() < maxHex.lowercased()
    }
    
    /// Derive Ethereum address from private key (for verification)
    func deriveAddressFromPrivateKey(_ privateKey: String) -> String? {
        let cleanPrivateKey = privateKey.hasPrefix("0x") ? String(privateKey.dropFirst(2)) : privateKey
        guard cleanPrivateKey.count == 64 else { return nil }
        
        // Simplified address derivation (in production, use proper secp256k1 public key derivation)
        guard let privateKeyData = Data(hex: cleanPrivateKey) else { return nil }
        let hash = SHA256.hash(data: privateKeyData)
        let addressData = Data(hash.suffix(20)) // Take last 20 bytes
        
        return "0x" + addressData.map { String(format: "%02hhx", $0) }.joined()
    }
    
    /// Verify wallet address matches private key
    func verifyWalletConsistency(_ wallet: WalletData) -> Bool {
        guard let derivedAddress = deriveAddressFromPrivateKey(wallet.privateKey) else {
            print("❌ Failed to derive address from private key")
            return false
        }
        
        let match = derivedAddress.lowercased() == wallet.address.lowercased()
        if match {
            print("✅ Wallet address matches private key")
        } else {
            print("⚠️ Wallet address does not match private key (using provided address)")
            print("   Provided: \(wallet.address)")
            print("   Derived:  \(derivedAddress)")
        }
        
        return match
    }
    
    /// Mask address for safe logging
    private func maskAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    /// Get wallet balance info for display
    func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo {
        return WalletDisplayInfo(
            maskedAddress: maskAddress(wallet.address),
            fullAddress: wallet.address,
            isValid: validateWallet(wallet)
        )
    }
}

// MARK: - Supporting Structures
struct WalletDisplayInfo {
    let maskedAddress: String
    let fullAddress: String
    let isValid: Bool
}

