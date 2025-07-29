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
    let srcAmount: String
    let gas: String
    let gasPrice: String
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
    
    private let apiKey: String
    private let nodeURL: String
    private let chainID: Int
    private let urlSession: URLSession
    
    // MARK: - Initialization
    
    init(apiKey: String, nodeURL: String, chainID: Int, urlSession: URLSession = .shared) {
        self.apiKey = apiKey
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
            return swapResponse
        } catch {
            throw SwapError.decodingError(error, responseString)
        }
    }
    
    func executeSwap(
        swapData: OneInchSwapResponse,
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> String {
        print("🔄 Executing 1inch swap transaction...")
        
        // Create web3 instance
        guard let url = URL(string: nodeURL) else {
            throw SwapError.invalidURL
        }
        
        let web3 = try await Web3.new(url)
        
        // Create addresses and parse data
        guard let fromAddress = EthereumAddress(walletData.address),
              let toAddress = EthereumAddress(swapData.tx.to),
              let transactionData = Data(hex: swapData.tx.data) else {
            throw SwapError.invalidTransactionData
        }
        
        let value = BigUInt(swapData.tx.value) ?? BigUInt(0)
        
        // Get transaction parameters
        let nonce = try await web3.eth.getTransactionCount(for: fromAddress, onBlock: .latest)
        let gasPrice = try await web3.eth.gasPrice()
        
        // Parse gas limit from 1inch response
        var gasLimit = swapData.tx.gas.bigIntValue
        
        // Ensure minimum gas limit for swaps
        let minGasLimit = BigUInt(300_000)
        if gasLimit < BigUInt(50_000) {
            print("⚠️ Low gas limit detected (\(gasLimit)), using \(minGasLimit)")
            gasLimit = minGasLimit
        }
        
        // Create transaction
        var tx: CodableTransaction = .emptyTransaction
        tx.from = fromAddress
        tx.to = toAddress
        tx.value = value
        tx.data = transactionData
        tx.nonce = nonce
        tx.gasLimit = gasLimit
        tx.gasPrice = gasPrice
        tx.chainID = BigUInt(config.chainID)
        
        // Create keystore
        let keystore = try createKeystore(from: walletData)
        web3.addKeystoreManager(keystore)
        
        // Sign transaction manually
        let privateKeyHex = String(walletData.privateKey.dropFirst(2))
        guard let privateKeyData = Data(hex: privateKeyHex) else {
            throw SwapError.invalidPrivateKey
        }
        
        try tx.sign(privateKey: privateKeyData)
        
        print("🔐 Swap transaction signed")
        print("🚀 Submitting swap to \(config.name)...")
        
        // Encode and send transaction
        guard let rawTx = tx.encode() else {
            throw SwapError.transactionEncodingFailed
        }
        
        let result = try await web3.eth.send(raw: rawTx)
        let txHash = result.hash
        
        print("✅ Swap transaction submitted successfully!")
        print("🔗 TX Hash: \(txHash)")
        
        if config.chainID == 137 {
            print("🌍 Polygonscan: https://polygonscan.com/tx/\(txHash)")
        }
        
        return txHash
    }
    
    // MARK: - Helper Methods
    
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
            srcAmount: amount,
            gas: "300000",
            gasPrice: "30000000000",
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
        apiKey: String,
        nodeURL: String,
        chainID: Int
    ) -> OneInchSwapProtocol {
        return OneInchSwapService(
            apiKey: apiKey,
            nodeURL: nodeURL,
            chainID: chainID
        )
    }
    
    /// Create mock swap service for testing
    static func createMock() -> OneInchSwapProtocol {
        return MockOneInchSwapService()
    }
}