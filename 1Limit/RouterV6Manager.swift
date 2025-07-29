//
//  RouterV6Manager.swift
//  1Limit
//
//  Refactored Router V6 Manager using dependency injection and OOP patterns
//

import BigInt
import Foundation
import SwiftUI

/// Router V6 Manager with proper separation of concerns and dependency injection
@MainActor
class RouterV6Manager: ObservableObject, LoggerProtocol {

  // MARK: - Published Properties

  @Published var isExecuting = false
  @Published var executionLog = ""

  // MARK: - Dependencies (Injected)

  private let orderFactory: OrderFactoryProtocol
  private let domainProvider: EIP712DomainProviderProtocol
  private let balanceChecker: BalanceCheckerProtocol
  private let gasPriceEstimator: GasPriceEstimatorProtocol
  private let transactionSubmitter: TransactionSubmitterProtocol
  private let walletLoader: WalletLoaderProtocol
  private let debugLogger: DebugLoggerProtocol
  private let transactionPersistence: TransactionPersistenceProtocol
  private let transactionPolling: TransactionPollingProtocol
  private let transactionManager: TransactionManagerProtocol?
  private let oneInchSwapService: OneInchSwapProtocol

  // MARK: - Configuration

  private let networkConfig: NetworkConfig

  // MARK: - State

  private var wallet: WalletData?

  // MARK: - Initialization with Dependency Injection

  init(
    orderFactory: OrderFactoryProtocol,
    domainProvider: EIP712DomainProviderProtocol,
    balanceChecker: BalanceCheckerProtocol,
    gasPriceEstimator: GasPriceEstimatorProtocol,
    transactionSubmitter: TransactionSubmitterProtocol,
    walletLoader: WalletLoaderProtocol,
    debugLogger: DebugLoggerProtocol,
    transactionPersistence: TransactionPersistenceProtocol,
    transactionPolling: TransactionPollingProtocol,
    transactionManager: TransactionManagerProtocol? = nil,
    oneInchSwapService: OneInchSwapProtocol,
    networkConfig: NetworkConfig
  ) {
    self.orderFactory = orderFactory
    self.domainProvider = domainProvider
    self.balanceChecker = balanceChecker
    self.gasPriceEstimator = gasPriceEstimator
    self.transactionSubmitter = transactionSubmitter
    self.walletLoader = walletLoader
    self.debugLogger = debugLogger
    self.transactionPersistence = transactionPersistence
    self.transactionPolling = transactionPolling
    self.transactionManager = transactionManager
    self.oneInchSwapService = oneInchSwapService
    self.networkConfig = networkConfig

    // Set up debug logging
    debugLogger.setupLogging()
  }

  // MARK: - Main Execution Flow

  func executeTestTransaction() async {
    isExecuting = true
    executionLog = ""

    await addLog("🚀 1inch Router V6 Real Transaction Test")
    await addLog("=====================================\n")

    do {
      // Step 1: Load wallet
      wallet = try await loadWallet()

      // Step 2: Create order
      let orderResult = try await createOrder()

      // Step 3: Sign order
      let signature = try await signOrder(orderResult.order)

      // Step 4: Validate and check balances
      try await performPreflightChecks(orderResult.order)

      // Step 5: Submit transaction
      _ = try await submitTransaction(
        order: orderResult.order,
        signature: signature
      )

      await addLog("🎉 Router V6 Debug Flow Complete! 🎊")

    } catch {
      await addLog("❌ Transaction failed: \(error.localizedDescription)")
    }

    isExecuting = false
  }

  func executeDynamicOrder(
    fromAmount: String,
    fromToken: String,
    toToken: String,
    limitPrice: String
  ) async -> Bool {
    isExecuting = true
    executionLog = ""

    await addLog("🚀 1inch Router V6 Dynamic Order Execution")
    await addLog("=====================================\n")
    await addLog("📊 Order Parameters:")
    await addLog("   From: \(fromAmount) \(fromToken)")
    await addLog("   To: \(toToken)")
    await addLog("   Limit Price: \(limitPrice)")
    await addLog("")

    do {
      // Step 1: Load wallet
      wallet = try await loadWallet()

      // Check if this is a USDC→WMATIC swap (use 1inch) or WMATIC→USDC limit order
      let isUSDCToWMATIC = fromToken == "USDC" && toToken == "WMATIC"
      
      if isUSDCToWMATIC {
        await addLog("🔄 Using 1inch Swap for USDC → WMATIC")
        let success = try await executeSwapTransaction(
          fromAmount: fromAmount,
          fromToken: fromToken,
          toToken: toToken
        )
        
        isExecuting = false
        return success
      } else {
        await addLog("📋 Using Router V6 Limit Order for WMATIC → USDC")
      }

      // Step 2: Create dynamic order
      let orderResult = try await createDynamicOrder(
        fromAmount: fromAmount,
        fromToken: fromToken,
        toToken: toToken,
        limitPrice: limitPrice
      )

      // Step 3: Sign order
      let signature = try await signOrder(orderResult.order)

      // Step 4: Validate and check balances
      try await performPreflightChecks(orderResult.order)

      // Step 5: Submit transaction
      _ = try await submitTransactionWithUserParams(
        order: orderResult.order,
        signature: signature,
        fromAmount: fromAmount,
        fromToken: fromToken,
        toToken: toToken,
        limitPrice: limitPrice
      )

      await addLog("🎉 Dynamic Order Placed Successfully! 🎊")
      isExecuting = false
      return true

    } catch {
      await addLog("❌ Order placement failed: \(error.localizedDescription)")
      isExecuting = false
      return false
    }
  }

  // MARK: - Private Execution Steps

  private func loadWallet() async throws -> WalletData {
    await addLog("📋 Step 1: Loading wallet...")

    guard let loadedWallet = await walletLoader.loadWallet() else {
      throw RouterV6Error.invalidOrderData
    }

    let displayInfo = walletLoader.getWalletDisplayInfo(loadedWallet)
    await addLog("✅ Wallet loaded: \(displayInfo.maskedAddress)")
    await addLog("🔐 Private key: \(maskPrivateKey(loadedWallet.privateKey))")
    await addLog("✅ Validation: \(displayInfo.isValid ? "PASSED" : "FAILED")\n")

    return loadedWallet
  }

  // MARK: - 1inch Swap Execution
  
  private func executeSwapTransaction(
    fromAmount: String,
    fromToken: String,
    toToken: String
  ) async throws -> Bool {
    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }
    
    await addLog("🔄 Step 2: Getting swap quote from 1inch...")
    
    // Convert tokens to contract addresses
    let srcTokenAddress: String
    let dstTokenAddress: String
    let amountInTokenUnits: String
    
    if fromToken == "USDC" {
      srcTokenAddress = networkConfig.usdc // Native USDC
      // Convert USDC amount (6 decimals) to smallest units
      if let amountDouble = Double(fromAmount) {
        let amountUnits = amountDouble * 1_000_000 // 6 decimals
        amountInTokenUnits = String(format: "%.0f", amountUnits)
      } else {
        throw RouterV6Error.invalidAmount
      }
    } else {
      throw RouterV6Error.unsupportedToken
    }
    
    if toToken == "WMATIC" {
      dstTokenAddress = networkConfig.wmatic
    } else {
      throw RouterV6Error.unsupportedToken
    }
    
    await addLog("   Source: \(fromAmount) \(fromToken) (\(srcTokenAddress))")
    await addLog("   Destination: \(toToken) (\(dstTokenAddress))")
    await addLog("   Amount in units: \(amountInTokenUnits)")
    
    // Get swap quote from 1inch
    let swapQuote = try await oneInchSwapService.getSwapQuote(
      srcToken: srcTokenAddress,
      dstToken: dstTokenAddress,
      amount: amountInTokenUnits,
      fromAddress: wallet.address
    )
    
    await addLog("✅ Step 3: Received swap quote from 1inch")
    await addLog("   Expected output: \(swapQuote.dstAmount) wei WMATIC")
    
    // Convert destination amount for display
    let dstAmountDouble = Double(swapQuote.dstAmount) ?? 0
    let dstAmountFormatted = dstAmountDouble / 1e18 // Convert from wei to WMATIC
    await addLog("   ≈ \(String(format: "%.6f", dstAmountFormatted)) WMATIC")
    await addLog("   Estimated gas: \(swapQuote.tx.gas.bigIntValue)")
    
    await addLog("🚀 Step 4: Submitting swap transaction...")
    
    // Execute the swap
    let txHash = try await oneInchSwapService.executeSwap(
      swapData: swapQuote,
      walletData: wallet,
      config: networkConfig
    )
    
    await addLog("✅ Swap transaction submitted!")
    await addLog("🔗 Transaction Hash: \(txHash)")
    
    if let transactionManager = transactionManager {
      // Create transaction record for the swap
      let transaction = Transaction(
        type: "1inch Swap",
        fromAmount: fromAmount,
        fromToken: fromToken,
        toAmount: String(format: "%.6f", dstAmountFormatted),
        toToken: toToken,
        limitPrice: "Market", // Swaps are at market price
        txHash: txHash
      )
      
      transactionManager.addTransaction(transaction)
      await addLog("📊 Transaction added to history")
    }
    
    await addLog("🎉 1inch Swap Complete! 🎊")
    return true
  }

  private func createOrder() async throws -> OrderCreationResult {
    await addLog("📋 Step 2: Generating Router V6 order parameters...")

    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }

    let orderResult = await orderFactory.createCompleteOrder(
      walletAddress: wallet.address,
      makerAsset: networkConfig.wmatic,
      takerAsset: networkConfig.usdc,
      makingAmount: BigUInt(10_000_000_000_000_000),  // 0.01 WMATIC
      takingAmount: BigUInt(10000),  // 0.01 USDC
      config: networkConfig,
      orderConfig: .default
    )

    if !orderResult.isValid {
      await addLog("⚠️ Order validation warnings:")
      for issue in orderResult.validation.issues {
        await addLog("   • \(issue)")
      }
    }

    await addLog("")
    return orderResult
  }

  private func createDynamicOrder(
    fromAmount: String,
    fromToken: String,
    toToken: String,
    limitPrice: String
  ) async throws -> OrderCreationResult {
    await addLog("📋 Step 2: Generating Dynamic Router V6 order...")

    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }

    // Convert string amounts to BigUInt
    guard let amountDouble = Double(fromAmount),
          let priceDouble = Double(limitPrice) else {
      throw RouterV6Error.invalidOrderData
    }

    // Calculate amounts in wei/smallest units
    let makingAmount: BigUInt
    let takingAmount: BigUInt
    let makerAsset: String
    let takerAsset: String

    if fromToken == "WMATIC" {
      // WMATIC has 18 decimals
      makingAmount = BigUInt(amountDouble * 1e18)
      makerAsset = networkConfig.wmatic
      
      if toToken == "USDC" {
        // USDC has 6 decimals
        let receiveAmount = amountDouble / priceDouble
        takingAmount = BigUInt(receiveAmount * 1e6)
        takerAsset = networkConfig.usdc
      } else {
        throw RouterV6Error.invalidOrderData
      }
    } else if fromToken == "USDC" {
      // USDC has 6 decimals
      makingAmount = BigUInt(amountDouble * 1e6)
      makerAsset = networkConfig.usdc
      
      if toToken == "WMATIC" {
        // WMATIC has 18 decimals
        let receiveAmount = amountDouble / priceDouble
        takingAmount = BigUInt(receiveAmount * 1e18)
        takerAsset = networkConfig.wmatic
      } else {
        throw RouterV6Error.invalidOrderData
      }
    } else {
      throw RouterV6Error.invalidOrderData
    }

    await addLog("💰 Making: \(fromAmount) \(fromToken) (\(makingAmount) units)")
    await addLog("🎯 Taking: \(toToken) (\(takingAmount) units)")
    await addLog("💱 Rate: \(limitPrice) \(fromToken)/\(toToken)")

    let orderResult = await orderFactory.createCompleteOrder(
      walletAddress: wallet.address,
      makerAsset: makerAsset,
      takerAsset: takerAsset,
      makingAmount: makingAmount,
      takingAmount: takingAmount,
      config: networkConfig,
      orderConfig: .default
    )

    if !orderResult.isValid {
      await addLog("⚠️ Order validation warnings:")
      for issue in orderResult.validation.issues {
        await addLog("   • \(issue)")
      }
    }

    await addLog("")
    return orderResult
  }

  private func signOrder(_ order: RouterV6OrderInfo) async throws -> String {
    await addLog("📋 Step 3: Creating EIP-712 domain...")

    let domain = domainProvider.createEIP712Domain()
    await addLog("🌐 Domain: \(domain.name) v\(domain.version)")
    await addLog("⛓️ Chain ID: \(domain.chainID)")
    await addLog("📄 Contract: \(domain.verifyingContract)\n")

    await addLog("📋 Step 4: Creating Router V6 order structure...")
    await addLog("📊 Making: 0.01 WMATIC (\(order.makingAmount) wei)")
    await addLog("🎯 Taking: 0.01 USDC (\(order.takingAmount) units)")

    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }

    let displayInfo = walletLoader.getWalletDisplayInfo(wallet)
    await addLog("👤 Maker: \(displayInfo.maskedAddress)")
    await addLog("🏠 Receiver: \(displayInfo.maskedAddress) (self-fill)\n")

    await addLog("📋 Step 5: Signing Router V6 order with EIP-712...")

    // Convert to EIP712SignerWeb3 format
    let web3Order = EIP712SignerWeb3.RouterV6Order(
      salt: order.salt,
      maker: order.maker,
      receiver: order.receiver,
      makerAsset: order.makerAsset,
      takerAsset: order.takerAsset,
      makingAmount: order.makingAmount,
      takingAmount: order.takingAmount,
      makerTraits: order.makerTraits
    )

    let web3Domain = EIP712SignerWeb3.EIP712Domain(
      name: domain.name,
      version: domain.version,
      chainId: BigUInt(domain.chainID),
      verifyingContract: domain.verifyingContract
    )

    let signatureData = try EIP712SignerWeb3.signRouterV6Order(
      order: web3Order,
      domain: web3Domain,
      privateKey: wallet.privateKey
    )

    let signature = "0x" + signatureData.map { String(format: "%02hhx", $0) }.joined()

    await addLog("🔐 EIP-712 signature generated (65 bytes)")
    await addLog("🔧 Converting to EIP-2098 compact format...")

    let compactSig = EIP712SignerWeb3.toCompactSignature(signature: signatureData)
    await addLog("✅ Compact signature ready:")
    await addLog(
      "   r:  0x\(compactSig.r.prefix(10).map { String(format: "%02hhx", $0) }.joined())...")
    await addLog(
      "   vs: 0x\(compactSig.vs.prefix(10).map { String(format: "%02hhx", $0) }.joined())...\n")

    return signature
  }

  private func performPreflightChecks(_ order: RouterV6OrderInfo) async throws {
    await addLog("📋 Step 6: Preparing fillOrder transaction...")

    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }

    // Estimate gas price
    let gasPrice = await gasPriceEstimator.estimateGasPrice()
    let fees = gasPriceEstimator.calculateTransactionFee(gasPrice: gasPrice, gasLimit: 300_000)

    await addLog("✅ Transaction validation passed")
    await addLog("📊 Contract: Router V6 (\(networkConfig.routerV6))")
    await addLog("🔧 Method: fillOrder(order, r, vs, amount, takerTraits)")
    await addLog("⛽ Gas Settings:")
    await addLog("   Limit: 300,000 units")
    await addLog(
      "   Price: \(gasPrice) wei (\(String(format: "%.1f", Double(gasPrice) / 1e9)) gwei)")
    await addLog("   Fee: \(String(format: "%.6f", fees.feeMatic)) MATIC")
    await addLog("🌐 Network: \(networkConfig.name) (Chain ID: \(networkConfig.chainID))\n")

    await addLog("📋 Step 7: Submitting to \(networkConfig.name)...")

    // Check balances
    let balanceResult = await balanceChecker.performComprehensiveCheck(
      order: order,
      walletAddress: wallet.address,
      routerAddress: networkConfig.routerV6,
      nodeURL: networkConfig.nodeURL
    )

    if !balanceResult.allChecksPassed {
      throw RouterV6Error.invalidOrderData
    }
  }

  private func submitTransaction(
    order: RouterV6OrderInfo,
    signature: String
  ) async throws -> TransactionResult {
    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }

    guard let signatureData = Data(hex: String(signature.dropFirst(2))) else {
      throw RouterV6Error.signingFailed
    }
    let compactSig = EIP712SignerWeb3.toCompactSignature(signature: signatureData)

    let result = try await transactionSubmitter.submitRouterV6Transaction(
      order: order,
      compactSignature: compactSig,
      walletData: wallet,
      config: networkConfig
    )

    // Create and save transaction for tracking
    await createAndTrackTransaction(order: order, result: result)

    return result
  }
  
  /// Submit transaction with user-provided parameters for better transaction tracking
  private func submitTransactionWithUserParams(
    order: RouterV6OrderInfo,
    signature: String,
    fromAmount: String,
    fromToken: String,
    toToken: String,
    limitPrice: String
  ) async throws -> TransactionResult {
    guard let wallet = wallet else {
      throw RouterV6Error.invalidOrderData
    }

    guard let signatureData = Data(hex: String(signature.dropFirst(2))) else {
      throw RouterV6Error.signingFailed
    }
    let compactSig = EIP712SignerWeb3.toCompactSignature(signature: signatureData)

    let result = try await transactionSubmitter.submitRouterV6Transaction(
      order: order,
      compactSignature: compactSig,
      walletData: wallet,
      config: networkConfig
    )

    // Create and save transaction with user parameters for accurate display
    await createAndTrackTransactionWithUserParams(
      fromAmount: fromAmount,
      fromToken: fromToken,
      toToken: toToken,
      limitPrice: limitPrice,
      result: result
    )

    return result
  }
  
  /// Create transaction record with user parameters and start polling for status updates
  private func createAndTrackTransactionWithUserParams(
    fromAmount: String,
    fromToken: String,
    toToken: String,
    limitPrice: String,
    result: TransactionResult
  ) async {
    do {
      // Calculate expected toAmount based on limit price
      let expectedToAmount: String
      if let fromDouble = Double(fromAmount), let limitDouble = Double(limitPrice) {
        // For limit orders: toAmount = fromAmount / limitPrice
        let calculatedAmount = fromDouble / limitDouble
        expectedToAmount = String(format: "%.6f", calculatedAmount)
      } else {
        expectedToAmount = "0"
      }
      
      // Create transaction with user-provided parameters for accurate display
      let transaction = Transaction(
        type: "Limit Order",
        fromAmount: fromAmount,
        fromToken: fromToken,
        toAmount: expectedToAmount,
        toToken: toToken,
        limitPrice: limitPrice,
        status: .pending,
        txHash: result.hash
      )
      
      // Save transaction
      try await transactionPersistence.saveTransaction(transaction)
      await addLog("💾 Transaction saved with ID: \(transaction.id)")
      
      // Notify TransactionManager immediately for UI update
      await MainActor.run {
        transactionManager?.addTransaction(transaction)
      }
      await addLog("📱 Transaction added to UI")
      
      // Start polling if we have a transaction hash
      if result.hash != nil {
        await transactionPolling.startPolling(for: transaction)
        await addLog("🔄 Started polling for transaction status")
      }
      
    } catch {
      await addLog("⚠️ Failed to save transaction: \(error.localizedDescription)")
    }
  }
  
  /// Create transaction record and start polling for status updates
  private func createAndTrackTransaction(order: RouterV6OrderInfo, result: TransactionResult) async {
    do {
      // Create transaction from order and result
      let transaction = Transaction(
        type: "Limit Order",
        fromAmount: formatTokenAmount(order.makingAmount, tokenSymbol: "WMATIC"),
        fromToken: "WMATIC",
        toAmount: formatTokenAmount(order.takingAmount, tokenSymbol: "USDC"),
        toToken: "USDC", 
        limitPrice: calculateLimitPrice(makingAmount: order.makingAmount, takingAmount: order.takingAmount),
        status: .pending,
        txHash: result.hash
      )
      
      // Save transaction
      try await transactionPersistence.saveTransaction(transaction)
      await addLog("💾 Transaction saved with ID: \(transaction.id)")
      
      // Notify TransactionManager immediately for UI update
      await MainActor.run {
        transactionManager?.addTransaction(transaction)
      }
      await addLog("📱 Transaction added to UI")
      
      // Start polling if we have a transaction hash
      if result.hash != nil {
        await transactionPolling.startPolling(for: transaction)
        await addLog("🔄 Started polling for transaction status")
      }
      
    } catch {
      await addLog("⚠️ Failed to save transaction: \(error.localizedDescription)")
    }
  }
  
  /// Format token amount for display
  private func formatTokenAmount(_ amount: BigUInt, tokenSymbol: String) -> String {
    let decimals = tokenSymbol == "USDC" ? 6 : 18
    let divisor = BigUInt(10).power(decimals)
    let wholePart = amount / divisor
    let fractionalPart = amount % divisor
    
    if fractionalPart == 0 {
      return "\(wholePart)"
    } else {
      let fractionalString = String(fractionalPart)
      let paddedFractional = String(repeating: "0", count: decimals - fractionalString.count) + fractionalString
      let trimmed = paddedFractional.trimmingCharacters(in: CharacterSet(charactersIn: "0"))
      return "\(wholePart).\(trimmed.isEmpty ? "0" : trimmed)"
    }
  }
  
  /// Calculate limit price from amounts
  private func calculateLimitPrice(makingAmount: BigUInt, takingAmount: BigUInt) -> String {
    // Price = takingAmount / makingAmount (adjusted for decimals)
    let makingDecimal = 18 // WMATIC decimals
    let takingDecimal = 6  // USDC decimals
    
    // Adjust for decimal differences
    let adjustedTaking = takingAmount * BigUInt(10).power(makingDecimal - takingDecimal)
    let price = adjustedTaking / makingAmount
    
    return "\(price)"
  }

  // MARK: - LoggerProtocol Implementation

  func addLog(_ message: String) async {
    let logMessage = message + "\n"
    executionLog += logMessage

    // Also write to debug log file
    await debugLogger.writeToLogFile(logMessage)
  }

  // MARK: - Helper Methods

  private func maskPrivateKey(_ privateKey: String) -> String {
    guard privateKey.count >= 10 else { return privateKey }
    let start = String(privateKey.prefix(6))
    return "\(start)..." + String(repeating: "*", count: 56) + "***"
  }
}

// MARK: - Dependency Protocols

/// Protocol for wallet loading operations
protocol WalletLoaderProtocol {
  func loadWallet() async -> WalletData?
  func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo
}

/// Protocol for debug logging operations
protocol DebugLoggerProtocol {
  func setupLogging()
  func writeToLogFile(_ message: String) async
}

// MARK: - Factory for RouterV6Manager

/// Factory for creating RouterV6Manager with different configurations
class RouterV6ManagerFactory {

  /// Create manager for production use on Polygon Mainnet
  @MainActor static func createProductionManager() -> RouterV6Manager {
    let networkConfig = NetworkConfig(
      name: "Polygon Mainnet",
      nodeURL: "https://polygon-bor-rpc.publicnode.com",
      routerV6: "0x111111125421cA6dc452d289314280a0f8842A65",
      wmatic: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
      usdc: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
      chainID: 137,
      domainName: "1inch Aggregation Router",
      domainVersion: "6"
    )

    let debugLogger = DebugLogger()

    let transactionPersistence = TransactionPersistenceManager()
    let transactionPolling = TransactionPollingService(
      persistenceManager: transactionPersistence
    )
    let transactionManager = TransactionManagerFactory.createProduction()
    
    // Create 1inch swap service with production configuration
    // API key loaded from bundle automatically
    let oneInchSwapService = OneInchSwapServiceFactory.createProduction(
      nodeURL: networkConfig.nodeURL,
      chainID: networkConfig.chainID
    )

    let manager = RouterV6Manager(
      orderFactory: OrderFactory.createProductionFactory(logger: nil),
      domainProvider: DomainProviderFactory.createPolygonMainnetProvider(),
      balanceChecker: BalanceCheckerFactory.createProductionChecker(),
      gasPriceEstimator: GasEstimatorFactory.createProductionEstimator(
        networkConfig: networkConfig),
      transactionSubmitter: TransactionSubmitterFactory.createProductionSubmitter(),
      walletLoader: WalletLoaderAdapter(),
      debugLogger: debugLogger,
      transactionPersistence: transactionPersistence,
      transactionPolling: transactionPolling,
      transactionManager: transactionManager,
      oneInchSwapService: oneInchSwapService,
      networkConfig: networkConfig
    )

    return manager
  }

  /// Create manager for testing
  @MainActor static func createTestManager() -> RouterV6Manager {
    let networkConfig = NetworkConfig(
      name: "Test Network",
      nodeURL: "http://localhost:8545",
      routerV6: "0x0000000000000000000000000000000000000000",
      wmatic: "0x0000000000000000000000000000000000000000",
      usdc: "0x0000000000000000000000000000000000000000",
      chainID: 1337,
      domainName: "Test Router",
      domainVersion: "6"
    )

    let mockTransactionPersistence = MockTransactionPersistenceManager()
    let mockTransactionPolling = MockTransactionPollingService()
    let mockTransactionManager = TransactionManagerFactory.createTest()
    let mockOneInchSwapService = OneInchSwapServiceFactory.createMock()

    let manager = RouterV6Manager(
      orderFactory: OrderFactory.createTestFactory(),
      domainProvider: DomainProviderFactory.createTestnetProvider(
        chainID: 1337, contractAddress: "0x0000000000000000000000000000000000000000"),
      balanceChecker: BalanceCheckerFactory.createTestChecker(),
      gasPriceEstimator: GasEstimatorFactory.createTestEstimator(fixedGasPrice: 20_000_000_000),
      transactionSubmitter: TransactionSubmitterFactory.createTestSubmitter(),
      walletLoader: MockWalletLoader(),
      debugLogger: MockDebugLogger(),
      transactionPersistence: mockTransactionPersistence,
      transactionPolling: mockTransactionPolling,
      transactionManager: mockTransactionManager,
      oneInchSwapService: mockOneInchSwapService,
      networkConfig: networkConfig
    )

    return manager
  }
}

// MARK: - Adapter Classes

/// Adapter to make existing WalletLoader compatible with protocol
class WalletLoaderAdapter: WalletLoaderProtocol {

  func loadWallet() async -> WalletData? {
    return await WalletLoader.shared.loadWallet()
  }

  func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo {
    return WalletLoader.shared.getWalletDisplayInfo(wallet)
  }
}

/// Debug logger implementation
class DebugLogger: DebugLoggerProtocol {

  private var logFileURL: URL?

  func setupLogging() {
    // Use project directory for easy access
    let projectDir = "./1Limit/logs"

    // Create logs directory if it doesn't exist
    try? FileManager.default.createDirectory(
      atPath: projectDir, withIntermediateDirectories: true, attributes: nil)

    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
    let timestamp = formatter.string(from: Date())

    let fileName = "1limit_debug_\(timestamp).log"
    logFileURL = URL(fileURLWithPath: projectDir).appendingPathComponent(fileName)

    if let logFileURL = logFileURL {
      let initialMessage =
        "🚀 1Limit Debug Log Started: \(Date())\n" + "📍 Log file: \(logFileURL.path)\n"
        + "💡 To tail: tail -f \(logFileURL.path)\n" + "=====================================\n\n"

      try? initialMessage.write(to: logFileURL, atomically: true, encoding: .utf8)
      print("📝 Debug log file created: \(logFileURL.path)")
      print("💡 To tail the log: tail -f \(logFileURL.path)")
    }
  }

  func writeToLogFile(_ message: String) async {
    guard let logFileURL = logFileURL else { return }

    if let fileHandle = try? FileHandle(forWritingTo: logFileURL) {
      fileHandle.seekToEndOfFile()
      if let data = message.data(using: .utf8) {
        fileHandle.write(data)
      }
      fileHandle.closeFile()
    } else {
      // Fallback: append to file
      if let existingContent = try? String(contentsOf: logFileURL, encoding: .utf8) {
        let newContent = existingContent + message
        try? newContent.write(to: logFileURL, atomically: true, encoding: .utf8)
      }
    }
  }
}

// MARK: - Mock Implementations for Testing

class MockWalletLoader: WalletLoaderProtocol {

  func loadWallet() async -> WalletData? {
    return WalletData(
      address: "0x1234567890123456789012345678901234567890",
      privateKey: "0x1234567890abcdef1234567890abcdef1234567890abcdef1234567890abcdef"
    )
  }

  func getWalletDisplayInfo(_ wallet: WalletData) -> WalletDisplayInfo {
    return WalletDisplayInfo(
      maskedAddress: "0x1234...7890",
      fullAddress: "0x1234567890123456789012345678901234567890",
      isValid: true
    )
  }
}

class MockDebugLogger: DebugLoggerProtocol {

  func setupLogging() {
    // Mock implementation - do nothing
  }

  func writeToLogFile(_ message: String) async {
    // Mock implementation - just print
    print(message, terminator: "")
  }
}

// MARK: - Router V6 Errors

enum RouterV6Error: LocalizedError {
  case invalidEIP712Type
  case missingEIP712Field
  case invalidEIP712Value
  case unsupportedEIP712Type
  case invalidAddress
  case invalidPrivateKey
  case invalidOrderData
  case signingFailed
  case contractCreationFailed
  case transactionCreationFailed
  case invalidURL
  case invalidAmount
  case unsupportedToken

  var errorDescription: String? {
    switch self {
    case .invalidEIP712Type:
      return "Invalid EIP-712 type"
    case .missingEIP712Field:
      return "Missing required EIP-712 field"
    case .invalidEIP712Value:
      return "Invalid EIP-712 value"
    case .unsupportedEIP712Type:
      return "Unsupported EIP-712 type"
    case .invalidAddress:
      return "Invalid Ethereum address"
    case .invalidPrivateKey:
      return "Invalid private key"
    case .invalidOrderData:
      return "Invalid order data"
    case .signingFailed:
      return "Failed to sign order"
    case .contractCreationFailed:
      return "Failed to create contract"
    case .transactionCreationFailed:
      return "Failed to create transaction"
    case .invalidURL:
      return "Invalid URL"
    case .invalidAmount:
      return "Invalid amount for swap"
    case .unsupportedToken:
      return "Unsupported token for swap"
    }
  }
}
