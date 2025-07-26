//
//  WalletLoader.swift
//  1Limit
//
//  Ported from Go to Swift - Secure wallet loading functionality
//

import Foundation

// MARK: - Wallet Data Structure (matching Go implementation)
struct WalletData: Codable {
    let address: String
    let privateKey: String
    
    private enum CodingKeys: String, CodingKey {
        case address
        case privateKey = "private_key"
    }
}

// MARK: - WalletLoader (Ported from Go)
class WalletLoader {
    static let shared = WalletLoader()
    private init() {}
    
    private let walletFileName = "wallet_0x3f847d.json"
    
    /// Load wallet from JSON file (matching Go implementation)
    func loadWallet() -> WalletData? {
        guard let walletURL = Bundle.main.url(forResource: "wallet_0x3f847d", withExtension: "json") else {
            print("❌ Wallet file not found in bundle")
            return loadWalletFromDocuments()
        }
        
        do {
            let data = try Data(contentsOf: walletURL)
            let wallet = try JSONDecoder().decode(WalletData.self, from: data)
            print("✅ Loaded wallet from bundle: \(maskAddress(wallet.address))")
            return wallet
        } catch {
            print("❌ Failed to load wallet from bundle: \(error)")
            return loadWalletFromDocuments()
        }
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
    
    /// Validate wallet data before use
    func validateWallet(_ wallet: WalletData) -> Bool {
        // Basic validation
        guard wallet.address.hasPrefix("0x"), wallet.address.count == 42 else {
            print("❌ Invalid wallet address format")
            return false
        }
        
        guard wallet.privateKey.hasPrefix("0x"), wallet.privateKey.count == 66 else {
            print("❌ Invalid private key format")
            return false
        }
        
        print("✅ Wallet validation passed")
        return true
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