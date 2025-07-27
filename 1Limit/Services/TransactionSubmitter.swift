//
//  TransactionSubmitter.swift
//  1Limit
//
//  Handles Router V6 transaction submission to blockchain with proper error handling
//

import Foundation
import BigInt
import web3swift
import Web3Core

/// Concrete implementation of Router V6 transaction submission
class TransactionSubmitter: TransactionSubmitterProtocol {
    
    // MARK: - Properties
    
    private let web3Provider: Web3ProviderProtocol
    private let submissionStrategy: SubmissionStrategy
    private let logger: LoggerProtocol?
    
    // MARK: - Initialization
    
    init(
        web3Provider: Web3ProviderProtocol = DefaultWeb3Provider(),
        strategy: SubmissionStrategy = .eip1559,
        logger: LoggerProtocol? = nil
    ) {
        self.web3Provider = web3Provider
        self.submissionStrategy = strategy
        self.logger = logger
    }
    
    // MARK: - TransactionSubmitterProtocol Implementation
    
    func submitRouterV6Transaction(
        order: RouterV6OrderInfo,
        compactSignature: (r: Data, vs: Data),
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> TransactionResult {
        await logMessage("🚀 Submitting Router V6 transaction...")
        
        switch submissionStrategy {
        case .eip1559:
            return try await submitEIP1559Transaction(
                order: order,
                compactSignature: compactSignature,
                walletData: walletData,
                config: config
            )
        case .legacy:
            return try await submitLegacyTransaction(
                order: order,
                compactSignature: compactSignature,
                walletData: walletData,
                config: config
            )
        case .gasEstimated:
            return try await submitWithGasEstimation(
                order: order,
                compactSignature: compactSignature,
                walletData: walletData,
                config: config
            )
        }
    }
    
    // MARK: - Private Submission Methods
    
    private func submitEIP1559Transaction(
        order: RouterV6OrderInfo,
        compactSignature: (r: Data, vs: Data),
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> TransactionResult {
        await logMessage("⛽ Using EIP-1559 transaction format...")
        
        let web3 = try await web3Provider.createWeb3Instance(nodeURL: config.nodeURL)
        
        // Create Router V6 contract
        guard let contractAddress = EthereumAddress(config.routerV6),
              let contract = web3.contract(RouterV6ABI.fullABI, at: contractAddress) else {
            throw TransactionSubmissionError.contractCreationFailed
        }
        
        await logMessage("📄 Router V6 contract loaded")
        
        // Prepare fillOrder parameters
        let fillParams = try prepareFillOrderParameters(order: order, compactSignature: compactSignature)
        
        await logMessage("🔍 DEBUG: Compact signature data:")
        await logMessage("   compactSig.r: 0x\(compactSignature.r.map { String(format: "%02hhx", $0) }.joined()) (\(compactSignature.r.count) bytes)")
        await logMessage("   compactSig.vs: 0x\(compactSignature.vs.map { String(format: "%02hhx", $0) }.joined()) (\(compactSignature.vs.count) bytes)")
        
        // Create write operation
        guard let writeOp = contract.createWriteOperation("fillOrder", parameters: fillParams) else {
            await logMessage("❌ createWriteOperation returned nil - parameter/ABI mismatch")
            throw TransactionSubmissionError.transactionCreationFailed
        }
        
        let encodedData = writeOp.transaction.data
        await logMessage("📦 FillOrder data encoded: \(encodedData.toHexString())")
        await logMessage("📦 FillOrder data encoded successfully")
        
        // Get transaction parameters
        guard let fromAddress = EthereumAddress(walletData.address) else {
            throw TransactionSubmissionError.invalidAddress
        }
        
        let txNonce = try await web3.eth.getTransactionCount(for: fromAddress)
        let baseGasPrice = try await web3.eth.gasPrice()
        
        // Calculate EIP-1559 gas parameters
        let priorityFee = BigUInt("25000000000") // 25 gwei minimum for Polygon
        let maxFee = baseGasPrice + priorityFee + BigUInt("20000000000") // Extra buffer
        
        await logMessage("⛽ EIP-1559 Gas Settings:")
        await logMessage("   Nonce: \(txNonce)")
        await logMessage("   Priority Fee: 25 gwei")
        await logMessage("   Max Fee: \(String(format: "%.1f", Double(maxFee) / 1e9)) gwei")
        await logMessage("   Gas Limit: 300,000")
        
        // Create manual EIP-1559 transaction
        let manualTransaction = CodableTransaction(
            type: .eip1559,
            to: contractAddress,
            nonce: txNonce,
            chainID: BigUInt(config.chainID),
            value: BigUInt(0),
            data: encodedData,
            gasLimit: BigUInt(300_000),
            maxFeePerGas: maxFee,
            maxPriorityFeePerGas: priorityFee
        )
        
        // Sign manually with private key
        let privateKeyHex = String(walletData.privateKey.dropFirst(2))
        guard let privateKeyData = Data(hex: privateKeyHex) else {
            throw Web3Error.dataError
        }
        
        var signedTx = manualTransaction
        try signedTx.sign(privateKey: privateKeyData)
        
        await logMessage("🔐 EIP-1559 transaction signed manually")
        await logMessage("🚀 Submitting to \(config.name) with EIP-1559...")
        
        // Encode and send raw transaction
        guard let rawTx = signedTx.encode() else {
            throw TransactionSubmissionError.transactionEncodingFailed
        }
        
        let result = try await web3.eth.send(raw: rawTx)
        let txHash = result.hash
        
        await logMessage("✅ REAL transaction submitted successfully!")
        await logMessage("🔗 TX Hash: \(txHash)")
        
        if config.chainID == 137 {
            await logMessage("🌍 Polygonscan: https://polygonscan.com/tx/\(txHash)")
        }
        
        // Wait for confirmation
        let gasUsed = await waitForTransactionConfirmation(web3: web3, txHash: txHash, config: config)
        
        return TransactionResult(
            hash: txHash,
            success: gasUsed != nil,
            gasUsed: gasUsed,
            error: gasUsed == nil ? "Transaction failed" : nil
        )
    }
    
    private func submitLegacyTransaction(
        order: RouterV6OrderInfo,
        compactSignature: (r: Data, vs: Data),
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> TransactionResult {
        await logMessage("⛽ Using legacy transaction format...")
        
        // Legacy implementation would go here
        // For now, fallback to EIP-1559
        return try await submitEIP1559Transaction(
            order: order,
            compactSignature: compactSignature,
            walletData: walletData,
            config: config
        )
    }
    
    private func submitWithGasEstimation(
        order: RouterV6OrderInfo,
        compactSignature: (r: Data, vs: Data),
        walletData: WalletData,
        config: NetworkConfig
    ) async throws -> TransactionResult {
        await logMessage("⛽ Using dynamic gas estimation...")
        
        // Gas estimation implementation would go here
        // For now, fallback to EIP-1559
        return try await submitEIP1559Transaction(
            order: order,
            compactSignature: compactSignature,
            walletData: walletData,
            config: config
        )
    }
    
    // MARK: - Helper Methods
    
    private func prepareFillOrderParameters(
        order: RouterV6OrderInfo,
        compactSignature: (r: Data, vs: Data)
    ) throws -> [AnyObject] {
        // Prepare fillOrder parameters EXACTLY like working implementation
        let orderTuple = [
            order.salt as AnyObject,
            try AddressConverter.addressToUint256(order.maker) as AnyObject,
            try AddressConverter.addressToUint256(order.maker) as AnyObject, // receiver = maker
            try AddressConverter.addressToUint256(order.makerAsset) as AnyObject,
            try AddressConverter.addressToUint256(order.takerAsset) as AnyObject,
            order.makingAmount as AnyObject,
            order.takingAmount as AnyObject,
            order.makerTraits as AnyObject
        ]
        
        return [
            orderTuple as AnyObject,
            compactSignature.r as AnyObject,
            compactSignature.vs as AnyObject,
            order.makingAmount as AnyObject,
            BigUInt(0) as AnyObject
        ]
    }
    
    private func waitForTransactionConfirmation(
        web3: Web3,
        txHash: String,
        config: NetworkConfig
    ) async -> UInt64? {
        await logMessage("⏳ Waiting for transaction confirmation...")
        
        // Wait up to 30 attempts with 2 second intervals
        for attempt in 1...30 {
            do {
                guard let txHashData = Data(hex: txHash.replacingOccurrences(of: "0x", with: "")) else {
                    await logMessage("❌ Invalid transaction hash format")
                    return nil
                }
                let receipt = try await web3.eth.transactionReceipt(txHashData)
                
                if receipt.status == TransactionReceipt.TXStatus.ok {
                    await logMessage("✅ Transaction confirmed successfully!")
                    await logMessage("⛽ Gas used: \(receipt.gasUsed)")
                    await logMessage("📝 Logs: \(receipt.logs.count) events")
                    return UInt64(receipt.gasUsed)
                } else {
                    await logMessage("❌ Transaction failed with status: \(receipt.status)")
                    return nil
                }
            } catch {
                // Continue waiting - transaction might still be pending
            }
            
            // Progress indication every 5 attempts
            if attempt % 5 == 0 {
                await logMessage("   Still waiting... (attempt \(attempt)/30)")
            }
            
            // 2 second sleep between attempts
            try? await Task.sleep(nanoseconds: 2_000_000_000)
        }
        
        await logMessage("⚠️ Transaction confirmation timeout - check manually")
        if config.chainID == 137 {
            await logMessage("🔗 Check status: https://polygonscan.com/tx/\(txHash)")
        }
        
        return nil
    }
    
    private func logMessage(_ message: String) async {
        await logger?.addLog(message)
    }
}

// MARK: - Submission Strategy

/// Strategy pattern for different transaction submission approaches
enum SubmissionStrategy {
    case eip1559        // Use EIP-1559 transactions (recommended)
    case legacy         // Use legacy gas pricing
    case gasEstimated   // Use dynamic gas estimation
}

// MARK: - Address Converter Utility

/// Utility class for address conversions required by Router V6
class AddressConverter {
    
    /// Convert Ethereum address to uint256 (required by Router V6)
    static func addressToUint256(_ address: String) throws -> BigUInt {
        guard address.hasPrefix("0x") && address.count == 42 else {
            throw TransactionSubmissionError.invalidAddress
        }
        
        guard let addressData = Data(hex: String(address.dropFirst(2))) else {
            throw Web3Error.dataError
        }
        guard addressData.count == 20 else {
            throw TransactionSubmissionError.invalidAddress
        }
        
        return BigUInt(addressData)
    }
    
    /// Convert uint256 back to Ethereum address
    static func uint256ToAddress(_ value: BigUInt) -> String {
        let data = value.serialize()
        let addressData = data.suffix(20) // Take last 20 bytes
        return "0x" + addressData.map { String(format: "%02hhx", $0) }.joined()
    }
}

// MARK: - Router V6 ABI

/// Router V6 ABI definitions
class RouterV6ABI {
    
    static let fullABI = """
    [
        {
            "inputs": [
                {
                    "components": [
                        {"internalType": "uint256", "name": "salt", "type": "uint256"},
                        {"internalType": "Address", "name": "maker", "type": "uint256"},
                        {"internalType": "Address", "name": "receiver", "type": "uint256"},
                        {"internalType": "Address", "name": "makerAsset", "type": "uint256"},
                        {"internalType": "Address", "name": "takerAsset", "type": "uint256"},
                        {"internalType": "uint256", "name": "makingAmount", "type": "uint256"},
                        {"internalType": "uint256", "name": "takingAmount", "type": "uint256"},
                        {"internalType": "MakerTraits", "name": "makerTraits", "type": "uint256"}
                    ],
                    "internalType": "struct IOrderMixin.Order",
                    "name": "order",
                    "type": "tuple"
                },
                {"internalType": "bytes32", "name": "r", "type": "bytes32"},
                {"internalType": "bytes32", "name": "vs", "type": "bytes32"},
                {"internalType": "uint256", "name": "amount", "type": "uint256"},
                {"internalType": "TakerTraits", "name": "takerTraits", "type": "uint256"}
            ],
            "name": "fillOrder",
            "outputs": [
                {"internalType": "uint256", "name": "", "type": "uint256"},
                {"internalType": "uint256", "name": "", "type": "uint256"},
                {"internalType": "bytes32", "name": "", "type": "bytes32"}
            ],
            "stateMutability": "payable",
            "type": "function"
        }
    ]
    """
}

// MARK: - Transaction Submission Errors

enum TransactionSubmissionError: LocalizedError {
    case contractCreationFailed
    case transactionCreationFailed
    case transactionEncodingFailed
    case invalidAddress
    case signingFailed
    case networkError(String)
    case gasEstimationFailed
    case confirmationTimeout
    
    var errorDescription: String? {
        switch self {
        case .contractCreationFailed:
            return "Failed to create Router V6 contract instance"
        case .transactionCreationFailed:
            return "Failed to create Router V6 transaction"
        case .transactionEncodingFailed:
            return "Failed to encode transaction for submission"
        case .invalidAddress:
            return "Invalid Ethereum address format"
        case .signingFailed:
            return "Failed to sign transaction"
        case .networkError(let message):
            return "Network error: \(message)"
        case .gasEstimationFailed:
            return "Failed to estimate gas price"
        case .confirmationTimeout:
            return "Transaction confirmation timeout"
        }
    }
}

// MARK: - Transaction Submitter Factory

/// Factory for creating transaction submitters with different configurations
class TransactionSubmitterFactory {
    
    /// Create submitter for production use
    static func createProductionSubmitter(logger: LoggerProtocol? = nil) -> TransactionSubmitterProtocol {
        return TransactionSubmitter(
            web3Provider: DefaultWeb3Provider(),
            strategy: .eip1559,
            logger: logger
        )
    }
    
    /// Create submitter for testing
    static func createTestSubmitter() -> TransactionSubmitterProtocol {
        return TransactionSubmitter(
            web3Provider: MockWeb3Provider(),
            strategy: .eip1559,
            logger: nil
        )
    }
    
    /// Create submitter with custom strategy
    static func createCustomSubmitter(
        strategy: SubmissionStrategy,
        logger: LoggerProtocol? = nil
    ) -> TransactionSubmitterProtocol {
        return TransactionSubmitter(
            web3Provider: DefaultWeb3Provider(),
            strategy: strategy,
            logger: logger
        )
    }
}

// MARK: - Transaction Monitoring

/// Class for monitoring transaction submission and status
class TransactionMonitor {
    
    private var pendingTransactions: [String: TransactionInfo] = [:]
    
    /// Track a submitted transaction
    func trackTransaction(_ hash: String, order: RouterV6OrderInfo, submittedAt: Date = Date()) {
        let info = TransactionInfo(
            hash: hash,
            order: order,
            submittedAt: submittedAt,
            status: .pending
        )
        pendingTransactions[hash] = info
    }
    
    /// Update transaction status
    func updateTransactionSubmissionStatus(_ hash: String, status: TransactionSubmissionStatus, gasUsed: UInt64? = nil) {
        guard var info = pendingTransactions[hash] else { return }
        info.status = status
        info.gasUsed = gasUsed
        info.confirmedAt = Date()
        pendingTransactions[hash] = info
    }
    
    /// Get pending transactions
    func getPendingTransactions() -> [TransactionInfo] {
        return Array(pendingTransactions.values.filter { $0.status == .pending })
    }
    
    /// Clean up old transactions
    func cleanupOldTransactions(olderThan: TimeInterval = 3600) { // 1 hour
        let cutoffDate = Date().addingTimeInterval(-olderThan)
        pendingTransactions = pendingTransactions.filter { _, info in
            info.submittedAt > cutoffDate
        }
    }
}

/// Information about a tracked transaction
struct TransactionInfo {
    let hash: String
    let order: RouterV6OrderInfo
    let submittedAt: Date
    var status: TransactionSubmissionStatus
    var gasUsed: UInt64?
    var confirmedAt: Date?
}

/// Transaction submission status enumeration
enum TransactionSubmissionStatus {
    case pending
    case confirmed
    case failed
    case dropped
}