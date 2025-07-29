//
//  OneInchSwapService.swift
//  1Limit
//
//  1inch API integration for USDC to WMATIC swaps
//

import Foundation
import BigInt
import web3swift
import Web3Core

// MARK: - Swap Response Models

struct OneInchSwapResponse: Codable {
    let dstAmount: String
    let tx: SwapTransactionData
}

struct SwapTransactionData: Codable {
    let from: String
    let to: String
    let data: String
    let value: String
    let gas: SwapGasValue
    let gasPrice: SwapGasValue
}

enum SwapGasValue: Codable {
    case string(String)
    case int(Int)
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            self = .string(stringValue)
        } else if let intValue = try? container.decode(Int.self) {
            self = .int(intValue)
        } else {
            throw DecodingError.typeMismatch(
                SwapGasValue.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Expected String or Int")
            )
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let value):
            try container.encode(value)
        case .int(let value):
            try container.encode(value)
        }
    }
    
    var bigIntValue: BigUInt {
        switch self {
        case .string(let value):
            return BigUInt(value) ?? BigUInt(0)
        case .int(let value):
            return BigUInt(value)
        }
    }
}

// MARK: - Swap Service Protocol

protocol OneInchSwapProtocol {
    func getSwapQuote(
        srcToken: String,
        dstToken: String,
        amount: String,
        fromAddress: String
    ) async throws -> OneInchSwapResponse
    
    func executeSwap(
        swapData: OneInchSwapResponse,
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> String // Returns transaction hash
}

// MARK: - 1inch Swap Service Implementation

class OneInchSwapService: OneInchSwapProtocol {
    
    // MARK: - Properties
    
    private let nodeURL: String
    private let chainID: Int
    private let urlSession: URLSession
    private lazy var apiKey: String? = {
        let key = loadAPIKey()
        print("🔑 1inch Swap API Key loaded: \(key != nil ? "✅ Found" : "❌ Missing")")
        return key
    }()
    
    // MARK: - Initialization
    
    init(nodeURL: String, chainID: Int, urlSession: URLSession = .shared) {
        self.nodeURL = nodeURL
        self.chainID = chainID
        self.urlSession = urlSession
    }
    
    // MARK: - Public Methods
    
    func getSwapQuote(
        srcToken: String,
        dstToken: String,
        amount: String,
        fromAddress: String
    ) async throws -> OneInchSwapResponse {
        guard let apiKey = apiKey else {
            print("❌ No API key found for 1inch swap service")
            throw SwapError.apiError(401, "API key required for 1inch swap endpoint")
        }
        
        let baseURL = "https://api.1inch.dev/swap/v6.0/\(chainID)/swap"
        
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "src", value: srcToken),
            URLQueryItem(name: "dst", value: dstToken),
            URLQueryItem(name: "amount", value: amount),
            URLQueryItem(name: "from", value: fromAddress),
            URLQueryItem(name: "slippage", value: "1"), // 1% slippage
            URLQueryItem(name: "disableEstimate", value: "true")
        ]
        
        guard let url = components.url else {
            throw SwapError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 10
        
        print("🔗 1inch API URL: \(url.absoluteString)")
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw SwapError.invalidResponse
        }
        
        let responseString = String(data: data, encoding: .utf8) ?? "Unable to decode response"
        print("📊 1inch API Response: \(responseString)")
        
        guard httpResponse.statusCode == 200 else {
            throw SwapError.apiError(httpResponse.statusCode, responseString)
        }
        
        do {
            let swapResponse = try JSONDecoder().decode(OneInchSwapResponse.self, from: data)
            print("✅ Successfully decoded 1inch swap response")
            print("📊 Destination amount: \(swapResponse.dstAmount)")
            print("⛽ Gas from response: \(swapResponse.tx.gas.bigIntValue)")
            return swapResponse
        } catch {
            print("❌ Failed to decode 1inch response")
            print("🔍 Decoding error: \(error)")
            print("📝 Raw response: \(responseString)")
            throw SwapError.decodingError(error, responseString)
        }
    }
    
    func executeSwap(
        swapData: OneInchSwapResponse,
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> String {
        print("🔄 Executing 1inch swap transaction...")
        print("📋 Swap data - dstAmount: \(swapData.dstAmount)")
        print("📋 Swap data - to: \(swapData.tx.to)")
        print("📋 Swap data - data length: \(swapData.tx.data.count)")
        
        // Create web3 instance
        guard let url = URL(string: nodeURL) else {
            throw SwapError.invalidURL
        }
        
        print("🌐 Connecting to node: \(nodeURL)")
        let web3 = try await Web3.new(url)
        print("✅ Web3 connection established")
        
        // Create addresses and parse data
        print("📍 Parsing addresses...")
        print("   From: \(walletData.address)")
        print("   To: \(swapData.tx.to)")
        
        guard let fromAddress = EthereumAddress(walletData.address) else {
            print("❌ Invalid fromAddress: \(walletData.address)")
            throw SwapError.invalidTransactionData
        }
        
        guard let toAddress = EthereumAddress(swapData.tx.to) else {
            print("❌ Invalid toAddress: \(swapData.tx.to)")
            throw SwapError.invalidTransactionData
        }
        
        // Strip 0x prefix before converting hex data
        let cleanHexData = swapData.tx.data.hasPrefix("0x") ? String(swapData.tx.data.dropFirst(2)) : swapData.tx.data
        guard let transactionData = Data(hex: cleanHexData) else {
            print("❌ Invalid transaction data: \(swapData.tx.data.prefix(20))...")
            throw SwapError.invalidTransactionData
        }
        
        print("✅ Addresses and data parsed successfully")
        
        let value = BigUInt(swapData.tx.value) ?? BigUInt(0)
        
        // Get transaction parameters
        print("🔢 Getting transaction parameters...")
        let nonce = try await web3.eth.getTransactionCount(for: fromAddress, onBlock: .latest)
        let gasPrice = try await web3.eth.gasPrice()
        print("   Nonce: \(nonce)")
        print("   Gas price: \(gasPrice) wei")
        
        // Create transaction first (without gasLimit)
        print("🔨 Creating transaction...")
        var tx: CodableTransaction = .emptyTransaction
        tx.from = fromAddress
        tx.to = toAddress
        tx.value = value
        tx.data = transactionData
        tx.nonce = nonce
        tx.gasPrice = gasPrice
        tx.chainID = BigUInt(config.chainID)
        
        // Estimate gas properly using web3 (like other transactions)
        print("⛽ Estimating gas for swap transaction...")
        do {
            let estimatedGas = try await web3.eth.estimateGas(for: tx)
            tx.gasLimit = estimatedGas
            print("✅ Gas estimated: \(estimatedGas)")
        } catch {
            print("⚠️ Gas estimation failed (\(error)), using fallback: 300,000")
            tx.gasLimit = BigUInt(300_000)
        }
        
        print("📋 Transaction details:")
        print("   From: \(fromAddress.address)")
        print("   To: \(toAddress.address)")
        print("   Value: \(value)")
        print("   Gas limit: \(tx.gasLimit)")
        print("   Chain ID: \(config.chainID)")
        
        // Create keystore
        print("🔐 Creating keystore...")
        let keystore = try createKeystore(from: walletData)
        web3.addKeystoreManager(keystore)
        
        // Sign transaction manually
        print("✏️ Signing transaction...")
        let privateKeyHex = String(walletData.privateKey.dropFirst(2))
        guard let privateKeyData = Data(hex: privateKeyHex) else {
            print("❌ Invalid private key format")
            throw SwapError.invalidPrivateKey
        }
        
        try tx.sign(privateKey: privateKeyData)
        
        print("🔐 Swap transaction signed")
        print("🚀 Submitting swap to \(config.name)...")
        
        // Encode and send transaction
        print("📦 Encoding transaction...")
        guard let rawTx = tx.encode() else {
            print("❌ Failed to encode transaction")
            throw SwapError.transactionEncodingFailed
        }
        
        print("📤 Sending transaction to network...")
        let result = try await web3.eth.send(raw: rawTx)
        let txHash = result.hash
        
        print("🎉 Transaction sent successfully!")
        
        print("✅ Swap transaction submitted successfully!")
        print("🔗 TX Hash: \(txHash)")
        
        if config.chainID == 137 {
            print("🌍 Polygonscan: https://polygonscan.com/tx/\(txHash)")
        }
        
        return txHash
    }
    
    // MARK: - Helper Methods
    
    private func loadAPIKey() -> String? {
        // Try to load from app bundle first (for iOS app)
        if let path = Bundle.main.path(forResource: "api_keys", ofType: "txt"),
           let content = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !content.isEmpty {
            return content
        }
        
        // Try to load from config directory (fallback for development)
        if let homeDir = NSHomeDirectory() as String?,
           let configPath = URL(string: homeDir)?.appendingPathComponent("config/api_keys.txt").path,
           let content = try? String(contentsOfFile: configPath, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
           !content.isEmpty {
            return content
        }
        
        return nil
    }
    
    private func createKeystore(from wallet: WalletData) throws -> KeystoreManager {
        var privateKey = wallet.privateKey
        
        // Remove 0x prefix if present
        if privateKey.hasPrefix("0x") {
            privateKey = String(privateKey.dropFirst(2))
        }
        
        guard let privateKeyData = Data(fromHex: privateKey) else {
            throw SwapError.invalidPrivateKey
        }
        
        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKeyData, password: "") else {
            throw SwapError.keystoreCreationFailed
        }
        
        return KeystoreManager([keystore])
    }
}

// MARK: - Swap Errors

enum SwapError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int, String)
    case decodingError(Error, String)
    case invalidTransactionData
    case invalidPrivateKey
    case keystoreCreationFailed
    case transactionEncodingFailed
    case networkError(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid 1inch API URL"
        case .invalidResponse:
            return "Invalid response from 1inch API"
        case .apiError(let code, let message):
            return "1inch API error \(code): \(message)"
        case .decodingError(let error, let response):
            return "Failed to decode 1inch response: \(error.localizedDescription)\nResponse: \(response)"
        case .invalidTransactionData:
            return "Invalid transaction data from 1inch API"
        case .invalidPrivateKey:
            return "Invalid private key for swap transaction"
        case .keystoreCreationFailed:
            return "Failed to create keystore for swap"
        case .transactionEncodingFailed:
            return "Failed to encode swap transaction"
        case .networkError(let message):
            return "Network error: \(message)"
        }
    }
}

// MARK: - Data Extension (Note: init(hex:) is already defined in WalletGenerator.swift)

// MARK: - Mock Implementation for Testing

class MockOneInchSwapService: OneInchSwapProtocol {
    var shouldSucceed = true
    var mockDelay: TimeInterval = 1.0
    var mockTransactionHash = "0xabcdef1234567890abcdef1234567890abcdef1234567890abcdef1234567890"
    
    func getSwapQuote(
        srcToken: String,
        dstToken: String,
        amount: String,
        fromAddress: String
    ) async throws -> OneInchSwapResponse {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SwapError.apiError(400, "Mock swap quote failed")
        }
        
        return OneInchSwapResponse(
            dstAmount: "10000000000000000", // 0.01 WMATIC
            tx: SwapTransactionData(
                from: fromAddress,
                to: "0x111111125421cA6dc452d289314280a0f8842A65", // 1inch Router V6
                data: "0x12345678", // Mock transaction data
                value: "0",
                gas: .string("300000"),
                gasPrice: .string("30000000000")
            )
        )
    }
    
    func executeSwap(
        swapData: OneInchSwapResponse,
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> String {
        try await Task.sleep(nanoseconds: UInt64(mockDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw SwapError.networkError("Mock swap execution failed")
        }
        
        return mockTransactionHash
    }
}

// MARK: - Factory

class OneInchSwapServiceFactory {
    
    /// Create production swap service
    static func createProduction(
        nodeURL: String,
        chainID: Int
    ) -> OneInchSwapProtocol {
        return OneInchSwapService(
            nodeURL: nodeURL,
            chainID: chainID
        )
    }
    
    /// Create mock swap service for testing
    static func createMock() -> OneInchSwapProtocol {
        return MockOneInchSwapService()
    }
}