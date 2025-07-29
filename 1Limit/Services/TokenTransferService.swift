//
//  TokenTransferService.swift
//  1Limit
//
//  Service for handling token transfers (native MATIC and ERC-20)
//

import Foundation
import web3swift
import BigInt
import Web3Core

/// Gas estimation result
struct GasEstimationResult {
    let gasEstimate: String      // In MATIC
    let gasCostUSD: String?      // USD value
    let gasLimit: String         // Gas limit in units
    let gasPrice: String         // Gas price in gwei
}

/// Transfer result
struct TransferResult {
    let success: Bool
    let transactionHash: String?
    let error: Error?
}

/// Protocol for token transfer operations
protocol TokenTransferProtocol {
    func estimateGas(for transaction: SendTransaction) async throws -> GasEstimationResult
    func executeSend(_ transaction: SendTransaction) async throws -> Bool
}

/// Token transfer service handling both native and ERC-20 transfers
@MainActor
class TokenTransferService: ObservableObject, TokenTransferProtocol {
    
    // MARK: - Dependencies
    
    private let priceService = PriceService.shared
    private let walletLoader = WalletLoader.shared
    private let nodeURL = "https://polygon-bor-rpc.publicnode.com"
    
    // MARK: - Configuration
    
    private let networkConfig = NetworkConfig(
        name: "Polygon Mainnet",
        nodeURL: "https://polygon-bor-rpc.publicnode.com",
        routerV6: "0x111111125421cA6dc452d289314280a0f8842A65",
        wmatic: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
        usdc: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
        chainID: 137,
        domainName: "1inch Aggregation Router",
        domainVersion: "6"
    )
    
    // MARK: - Transfer Operations
    
    /// Estimate gas fees for a transfer
    func estimateGas(for transaction: SendTransaction) async throws -> GasEstimationResult {
        if transaction.token.isNative {
            return try await estimateNativeTransferGas(transaction)
        } else {
            return try await estimateERC20TransferGas(transaction)
        }
    }
    
    /// Execute a send transaction
    func executeSend(_ transaction: SendTransaction) async throws -> Bool {
        if transaction.token.isNative {
            return try await executeNativeTransfer(transaction)
        } else {
            return try await executeERC20Transfer(transaction)
        }
    }
    
    // MARK: - Native MATIC Transfer
    
    private func estimateNativeTransferGas(_ transaction: SendTransaction) async throws -> GasEstimationResult {
        // Standard gas limit for native transfer is 21,000 units
        let gasLimit = BigUInt(21000)
        
        // Get current gas price
        let gasPrice = try await getCurrentGasPrice()
        
        // Calculate total gas cost in wei
        let gasCostWei = gasLimit * gasPrice
        
        // Convert to MATIC (18 decimals)
        let gasCostMatic = Double(gasCostWei) / 1e18
        let gasCostFormatted = String(format: "%.6f", gasCostMatic)
        
        // Get USD value
        var gasCostUSD: String?
        if let maticPrice = priceService.getPrice(for: "MATIC") {
            let usdValue = gasCostMatic * maticPrice.usdPrice
            gasCostUSD = String(format: "$%.4f", usdValue)
        }
        
        // Convert gas price from wei to gwei for display
        let gasPriceGwei = Double(gasPrice) / 1e9
        
        return GasEstimationResult(
            gasEstimate: gasCostFormatted,
            gasCostUSD: gasCostUSD,
            gasLimit: String(gasLimit),
            gasPrice: String(format: "%.2f", gasPriceGwei)
        )
    }
    
    private func executeNativeTransfer(_ transaction: SendTransaction) async throws -> Bool {
        guard let wallet = await walletLoader.loadWallet() else {
            throw TransferError.noWallet
        }
        
        print("🚀 Executing native MATIC transfer:")
        print("   From: \(transaction.fromAddress)")
        print("   To: \(transaction.toAddress)")
        print("   Amount: \(transaction.amount) MATIC")
        print("   Amount Wei: \(transaction.amountWei)")
        
        // Create web3 instance
        guard let url = URL(string: nodeURL) else {
            throw TransferError.networkError("Invalid node URL")
        }
        
        let web3 = try await Web3.new(url)
        
        // Create addresses
        guard let fromAddress = EthereumAddress(transaction.fromAddress),
              let toAddress = EthereumAddress(transaction.toAddress),
              let amountWei = BigUInt(transaction.amountWei) else {
            throw TransferError.invalidAmount
        }
        
        // Create keystore
        let keystore = try createKeystore(from: wallet)
        web3.addKeystoreManager(keystore)
        
        // Create transaction for native token
        var tx: CodableTransaction = .emptyTransaction
        tx.from = fromAddress
        tx.to = toAddress
        tx.value = amountWei
        tx.chainID = BigUInt(networkConfig.chainID) // Set Polygon chain ID (137)
        
        // Get gas price and nonce
        tx.gasPrice = try await web3.eth.gasPrice()
        tx.nonce = try await web3.eth.getTransactionCount(for: fromAddress, onBlock: .latest)
        
        // Create fallback operation for native token
        let contract = web3.contract(Web3.Utils.coldWalletABI, at: toAddress, abiVersion: 2)
        contract?.transaction = tx
        
        guard let writeOperation = contract?.createWriteOperation("fallback", parameters: []) else {
            throw TransferError.transactionFailed("Failed to create write operation")
        }
        
        // Estimate gas
        tx.gasLimit = try await web3.eth.estimateGas(for: writeOperation.transaction)
        
        // Update transaction in write operation with all parameters
        writeOperation.transaction = tx
        writeOperation.transaction.chainID = BigUInt(networkConfig.chainID)
        writeOperation.transaction.nonce = tx.nonce
        writeOperation.transaction.gasPrice = tx.gasPrice
        writeOperation.transaction.gasLimit = tx.gasLimit
        
        // Set policies
        let policies = Policies(
            noncePolicy: .latest,
            gasLimitPolicy: .manual(tx.gasLimit),
            gasPricePolicy: .manual(tx.gasPrice ?? BigUInt(30) * BigUInt(10).power(9))
        )
        
        do {
            // Submit transaction
            let result = try await writeOperation.writeToChain(
                password: "",
                policies: policies
            )
            
            print("✅ Transaction submitted: \(result.hash)")
            
            // Add to TransactionManager
            await addTransactionToManager(
                hash: result.hash,
                transaction: transaction,
                type: "Native Transfer"
            )
            
            return true
        } catch {
            print("❌ Transaction failed: \(error)")
            throw TransferError.transactionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - ERC-20 Token Transfer
    
    private func estimateERC20TransferGas(_ transaction: SendTransaction) async throws -> GasEstimationResult {
        // ERC-20 transfers typically use around 65,000 gas units
        let gasLimit = BigUInt(65000)
        
        // Get current gas price
        let gasPrice = try await getCurrentGasPrice()
        
        // Calculate total gas cost in wei
        let gasCostWei = gasLimit * gasPrice
        
        // Convert to MATIC (18 decimals)
        let gasCostMatic = Double(gasCostWei) / 1e18
        let gasCostFormatted = String(format: "%.6f", gasCostMatic)
        
        // Get USD value
        var gasCostUSD: String?
        if let maticPrice = priceService.getPrice(for: "MATIC") {
            let usdValue = gasCostMatic * maticPrice.usdPrice
            gasCostUSD = String(format: "$%.4f", usdValue)
        }
        
        // Convert gas price from wei to gwei for display
        let gasPriceGwei = Double(gasPrice) / 1e9
        
        return GasEstimationResult(
            gasEstimate: gasCostFormatted,
            gasCostUSD: gasCostUSD,
            gasLimit: String(gasLimit),
            gasPrice: String(format: "%.2f", gasPriceGwei)
        )
    }
    
    private func executeERC20Transfer(_ transaction: SendTransaction) async throws -> Bool {
        guard let wallet = await walletLoader.loadWallet() else {
            throw TransferError.noWallet
        }
        
        guard let contractAddress = transaction.token.contractAddress else {
            throw TransferError.missingContractAddress
        }
        
        print("🚀 Executing ERC-20 token transfer:")
        print("   Token: \(transaction.token.symbol)")
        print("   Contract: \(contractAddress)")
        print("   From: \(transaction.fromAddress)")
        print("   To: \(transaction.toAddress)")
        print("   Amount: \(transaction.amount) \(transaction.token.symbol)")
        print("   Amount Units: \(transaction.amountWei)")
        
        // Create web3 instance
        guard let url = URL(string: nodeURL) else {
            throw TransferError.networkError("Invalid node URL")
        }
        
        let web3 = try await Web3.new(url)
        
        // Create addresses
        guard let fromAddress = EthereumAddress(transaction.fromAddress),
              let toAddress = EthereumAddress(transaction.toAddress),
              let tokenContractAddress = EthereumAddress(contractAddress),
              let amountUnits = BigUInt(transaction.amountWei) else {
            throw TransferError.invalidAmount
        }
        
        // Create keystore
        let keystore = try createKeystore(from: wallet)
        web3.addKeystoreManager(keystore)
        
        // Create transaction for ERC-20 token
        var tx: CodableTransaction = .emptyTransaction
        tx.from = fromAddress
        tx.to = tokenContractAddress // Token contract address
        tx.value = 0 // No native token value for ERC-20 transfers
        tx.chainID = BigUInt(networkConfig.chainID) // Set Polygon chain ID (137)
        
        // Get gas price and nonce
        tx.gasPrice = try await web3.eth.gasPrice()
        tx.nonce = try await web3.eth.getTransactionCount(for: fromAddress, onBlock: .latest)
        
        // Create ERC-20 contract
        let contract = web3.contract(Web3.Utils.erc20ABI, at: tokenContractAddress, abiVersion: 2)
        contract?.transaction = tx
        
        // Create transfer operation with target address and amount
        guard let writeOperation = contract?.createWriteOperation(
            "transfer",
            parameters: [toAddress as AnyObject, amountUnits as AnyObject]
        ) else {
            throw TransferError.transactionFailed("Failed to create transfer operation")
        }
        
        // Estimate gas
        tx.gasLimit = try await web3.eth.estimateGas(for: writeOperation.transaction)
        
        // Update transaction in write operation with all parameters
        writeOperation.transaction = tx
        writeOperation.transaction.chainID = BigUInt(networkConfig.chainID)
        writeOperation.transaction.nonce = tx.nonce
        writeOperation.transaction.gasPrice = tx.gasPrice
        writeOperation.transaction.gasLimit = tx.gasLimit
        
        // Set policies
        let policies = Policies(
            noncePolicy: .latest,
            gasLimitPolicy: .manual(tx.gasLimit),
            gasPricePolicy: .manual(tx.gasPrice ?? BigUInt(30) * BigUInt(10).power(9))
        )
        
        do {
            // Submit transaction
            let result = try await writeOperation.writeToChain(
                password: "",
                policies: policies
            )
            
            print("✅ ERC-20 transfer submitted: \(result.hash)")
            
            // Add to TransactionManager
            await addTransactionToManager(
                hash: result.hash,
                transaction: transaction,
                type: "Token Transfer"
            )
            
            return true
        } catch {
            print("❌ ERC-20 transfer failed: \(error)")
            throw TransferError.transactionFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCurrentGasPrice() async throws -> BigUInt {
        // Query actual network for gas price
        guard let url = URL(string: nodeURL) else {
            // Fallback to reasonable gas price for Polygon (30 gwei)
            return BigUInt(30) * BigUInt(10).power(9)
        }
        
        let web3 = try await Web3.new(url)
        
        do {
            let gasPrice = try await web3.eth.gasPrice()
            print("💰 Current gas price: \(gasPrice) wei (\(Double(gasPrice) / 1e9) gwei)")
            return gasPrice
        } catch {
            print("⚠️ Failed to get gas price, using default: \(error)")
            return BigUInt(30) * BigUInt(10).power(9) // 30 gwei fallback
        }
    }
    
    private func createKeystore(from wallet: WalletData) throws -> KeystoreManager {
        // Create keystore from wallet private key
        var privateKey = wallet.privateKey
        
        // Remove 0x prefix if present
        if privateKey.hasPrefix("0x") {
            privateKey = String(privateKey.dropFirst(2))
        }
        
        guard let privateKeyData = Data(fromHex: privateKey) else {
            throw TransferError.noWallet
        }
        
        guard let keystore = try? EthereumKeystoreV3(privateKey: privateKeyData, password: "") else {
            throw TransferError.noWallet
        }
        
        let keystoreManager = KeystoreManager([keystore])
        
        // Log for debugging
        if let addresses = keystore.addresses {
            print("🔑 Keystore addresses: \(addresses.map { $0.address })")
            print("🔑 Expected address: \(wallet.address)")
        }
        
        return keystoreManager
    }
    
    private func addTransactionToManager(
        hash: String,
        transaction: SendTransaction,
        type: String
    ) async {
        // Get TransactionManager and add the transaction
        let transactionManager = TransactionManagerFactory.createProduction()
        
        let newTransaction = Transaction(
            type: type,
            fromAmount: transaction.amount,
            fromToken: transaction.token.symbol,
            toAmount: transaction.amount, // For simple transfers, amounts are the same
            toToken: transaction.token.symbol,
            limitPrice: "0", // Not a limit order
            txHash: hash,
            fromAmountUSD: Double(transaction.amount) ?? 0 * (Double(transaction.gasCostUSD?.dropFirst() ?? "0") ?? 0),
            toAmountUSD: Double(transaction.amount) ?? 0 * (Double(transaction.gasCostUSD?.dropFirst() ?? "0") ?? 0),
            gasFeeUSD: Double(transaction.gasCostUSD?.dropFirst() ?? "0")
        )
        
        await transactionManager.addTransaction(newTransaction)
    }
}

// MARK: - Extensions

extension Data {
    init?(fromHex hex: String) {
        var data = Data()
        var hex = hex
        
        // Remove 0x prefix if present
        if hex.hasPrefix("0x") {
            hex = String(hex.dropFirst(2))
        }
        
        // Ensure even number of characters
        if hex.count % 2 != 0 {
            hex = "0" + hex
        }
        
        for i in stride(from: 0, to: hex.count, by: 2) {
            let j = hex.index(hex.startIndex, offsetBy: i)
            let k = hex.index(j, offsetBy: 2)
            let bytes = hex[j..<k]
            if var byte = UInt8(bytes, radix: 16) {
                data.append(&byte, count: 1)
            } else {
                return nil
            }
        }
        
        self = data
    }
}

// MARK: - Error Types

enum TransferError: Error, LocalizedError {
    case noWallet
    case insufficientBalance
    case invalidAmount
    case missingContractAddress
    case gasPriceUnavailable
    case networkError(String)
    case transactionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noWallet:
            return "No wallet available"
        case .insufficientBalance:
            return "Insufficient balance for transfer"
        case .invalidAmount:
            return "Invalid transfer amount"
        case .missingContractAddress:
            return "Token contract address not found"
        case .gasPriceUnavailable:
            return "Could not get current gas price"
        case .networkError(let message):
            return "Network error: \(message)"
        case .transactionFailed(let message):
            return "Transaction failed: \(message)"
        }
    }
}

// MARK: - Mock Service for Testing

class MockTokenTransferService: TokenTransferProtocol {
    var shouldSucceed = true
    var gasEstimateDelay: TimeInterval = 1.0
    var transferDelay: TimeInterval = 2.0
    var mockGasEstimate = "0.002"
    var mockGasCostUSD = "$0.0034"
    
    func estimateGas(for transaction: SendTransaction) async throws -> GasEstimationResult {
        try await Task.sleep(nanoseconds: UInt64(gasEstimateDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw TransferError.networkError("Mock gas estimation failed")
        }
        
        return GasEstimationResult(
            gasEstimate: mockGasEstimate,
            gasCostUSD: mockGasCostUSD,
            gasLimit: transaction.token.isNative ? "21000" : "65000",
            gasPrice: "30.0"
        )
    }
    
    func executeSend(_ transaction: SendTransaction) async throws -> Bool {
        try await Task.sleep(nanoseconds: UInt64(transferDelay * 1_000_000_000))
        
        if !shouldSucceed {
            throw TransferError.transactionFailed("Mock transfer failed")
        }
        
        return true
    }
}