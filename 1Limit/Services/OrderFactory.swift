//
//  OrderFactory.swift
//  1Limit
//
//  Factory for creating and orchestrating Router V6 orders with proper component composition
//

import Foundation
import BigInt

/// Concrete implementation of Router V6 order creation factory
class OrderFactory: OrderFactoryProtocol {
    
    // MARK: - Properties
    
    private let parameterGenerator: OrderParameterGeneratorProtocol
    private let traitsCalculator: MakerTraitsCalculatorProtocol
    private let orderValidator: OrderValidatorProtocol
    private let logger: LoggerProtocol?
    
    // MARK: - Initialization
    
    init(
        parameterGenerator: OrderParameterGeneratorProtocol,
        traitsCalculator: MakerTraitsCalculatorProtocol,
        orderValidator: OrderValidatorProtocol,
        logger: LoggerProtocol? = nil
    ) {
        self.parameterGenerator = parameterGenerator
        self.traitsCalculator = traitsCalculator
        self.orderValidator = orderValidator
        self.logger = logger
    }
    
    // MARK: - OrderFactoryProtocol Implementation
    
    func createRouterV6Order(
        walletAddress: String,
        salt: BigUInt,
        makerTraits: BigUInt,
        config: NetworkConfig
    ) -> RouterV6OrderInfo {
        return RouterV6OrderInfo(
            salt: salt,
            maker: walletAddress,
            receiver: walletAddress, // Self-fill for basic orders
            makerAsset: config.wmatic,
            takerAsset: config.usdc,
            makingAmount: BigUInt(10000000000000000), // 0.01 WMATIC
            takingAmount: BigUInt(10000), // 0.01 USDC
            makerTraits: makerTraits
        )
    }
    
    // MARK: - Extended Order Creation Methods
    
    /// Create a complete Router V6 order with auto-generated parameters
    func createCompleteOrder(
        walletAddress: String,
        makerAsset: String,
        takerAsset: String,
        makingAmount: BigUInt,
        takingAmount: BigUInt,
        config: NetworkConfig,
        orderConfig: OrderConfiguration = .default
    ) async -> OrderCreationResult {
        await logMessage("📋 Creating Router V6 order...")
        await logMessage("📊 Making: \(formatAmount(makingAmount, decimals: 18)) of \(makerAsset)")
        await logMessage("🎯 Taking: \(formatAmount(takingAmount, decimals: 6)) of \(takerAsset)")
        
        // Generate order parameters
        let salt = parameterGenerator.generateSDKStyleSalt()
        let nonce = parameterGenerator.generateRandomNonce()
        
        await logMessage("🧂 Generated SDK-style salt: \(salt) (96-bit like 1inch SDK)")
        await logMessage("📦 Generated nonce: \(nonce) (slot: \(nonce >> 8), bit: \(nonce & 0xff))")
        
        // Calculate maker traits
        let makerTraits = traitsCalculator.calculateMakerTraitsV6(
            nonce: nonce,
            expiry: orderConfig.expirySeconds
        )
        
        await logMessage("🎛️ Calculated MakerTraits: \(makerTraits) (nonce in bits 120-160)")
        
        // Create order
        let order = RouterV6OrderInfo(
            salt: salt,
            maker: walletAddress,
            receiver: orderConfig.customReceiver ?? walletAddress,
            makerAsset: makerAsset,
            takerAsset: takerAsset,
            makingAmount: makingAmount,
            takingAmount: takingAmount,
            makerTraits: makerTraits
        )
        
        // Validate order
        let validation = orderValidator.validateTransaction(order: order)
        
        if validation.isValid {
            await logMessage("✅ Order validation passed")
        } else {
            await logMessage("⚠️ Order validation issues:")
            for issue in validation.issues {
                await logMessage("   • \(issue)")
            }
        }
        
        return OrderCreationResult(
            order: order,
            validation: validation,
            parameters: OrderParameters(salt: salt, nonce: nonce, makerTraits: makerTraits)
        )
    }
    
    /// Create order with custom parameters (for advanced users)
    func createCustomOrder(
        walletAddress: String,
        orderRequest: CustomOrderRequest,
        config: NetworkConfig
    ) async -> OrderCreationResult {
        await logMessage("📋 Creating custom Router V6 order...")
        
        // Use provided parameters or generate defaults
        let salt = orderRequest.customSalt ?? parameterGenerator.generateSDKStyleSalt()
        let nonce = orderRequest.customNonce ?? parameterGenerator.generateRandomNonce()
        
        // Calculate maker traits with custom configuration
        let traitsConfig = orderRequest.traitsConfiguration ?? .default
        let customCalculator = MakerTraitsCalculator(configuration: traitsConfig)
        let makerTraits = customCalculator.calculateMakerTraitsV6(
            nonce: nonce,
            expiry: orderRequest.expirySeconds
        )
        
        let order = RouterV6OrderInfo(
            salt: salt,
            maker: walletAddress,
            receiver: orderRequest.receiver ?? walletAddress,
            makerAsset: orderRequest.makerAsset,
            takerAsset: orderRequest.takerAsset,
            makingAmount: orderRequest.makingAmount,
            takingAmount: orderRequest.takingAmount,
            makerTraits: makerTraits
        )
        
        // Validate with custom rules if provided
        let validator = orderRequest.customValidator ?? orderValidator
        let validation = validator.validateTransaction(order: order)
        
        return OrderCreationResult(
            order: order,
            validation: validation,
            parameters: OrderParameters(salt: salt, nonce: nonce, makerTraits: makerTraits)
        )
    }
    
    /// Create batch of orders for market making
    func createOrderBatch(
        walletAddress: String,
        requests: [BatchOrderRequest],
        config: NetworkConfig
    ) async -> [OrderCreationResult] {
        await logMessage("📋 Creating batch of \(requests.count) Router V6 orders...")
        
        var results: [OrderCreationResult] = []
        
        for (index, request) in requests.enumerated() {
            await logMessage("Processing order \(index + 1)/\(requests.count)...")
            
            let result = await createCompleteOrder(
                walletAddress: walletAddress,
                makerAsset: request.makerAsset,
                takerAsset: request.takerAsset,
                makingAmount: request.makingAmount,
                takingAmount: request.takingAmount,
                config: config,
                orderConfig: request.orderConfig
            )
            
            results.append(result)
        }
        
        let validOrders = results.filter { $0.validation.isValid }.count
        await logMessage("✅ Created \(validOrders)/\(requests.count) valid orders")
        
        return results
    }
    
    // MARK: - Private Helper Methods
    
    private func formatAmount(_ amount: BigUInt, decimals: Int) -> String {
        let divisor = pow(10.0, Double(decimals))
        let value = Double(amount.description) ?? 0
        return String(format: "%.6f", value / divisor)
    }
    
    private func logMessage(_ message: String) async {
        await logger?.addLog(message)
    }
}

// MARK: - Configuration Structures

/// Configuration for order creation
struct OrderConfiguration {
    let expirySeconds: UInt32
    let customReceiver: String?
    let allowPartialFills: Bool
    let allowMultipleFills: Bool
    
    /// Default configuration for standard orders
    static let `default` = OrderConfiguration(
        expirySeconds: 1800, // 30 minutes
        customReceiver: nil,
        allowPartialFills: false,
        allowMultipleFills: false
    )
    
    /// Configuration for market making orders
    static let marketMaking = OrderConfiguration(
        expirySeconds: 3600, // 1 hour
        customReceiver: nil,
        allowPartialFills: true,
        allowMultipleFills: true
    )
    
    /// Configuration for long-term orders
    static let longTerm = OrderConfiguration(
        expirySeconds: 86400, // 24 hours
        customReceiver: nil,
        allowPartialFills: true,
        allowMultipleFills: false
    )
}

/// Request for custom order creation
struct CustomOrderRequest {
    let makerAsset: String
    let takerAsset: String
    let makingAmount: BigUInt
    let takingAmount: BigUInt
    let receiver: String?
    let expirySeconds: UInt32
    let customSalt: BigUInt?
    let customNonce: UInt64?
    let traitsConfiguration: MakerTraitsConfiguration?
    let customValidator: OrderValidatorProtocol?
}

/// Request for batch order creation
struct BatchOrderRequest {
    let makerAsset: String
    let takerAsset: String
    let makingAmount: BigUInt
    let takingAmount: BigUInt
    let orderConfig: OrderConfiguration
}

/// Parameters generated during order creation
struct OrderParameters {
    let salt: BigUInt
    let nonce: UInt64
    let makerTraits: BigUInt
    
    var description: String {
        return """
        Order Parameters:
          Salt: \(salt) (96-bit)
          Nonce: \(nonce) (slot: \(nonce >> 8), bit: \(nonce & 0xff))
          MakerTraits: \(makerTraits)
        """
    }
}

/// Result of order creation process
struct OrderCreationResult {
    let order: RouterV6OrderInfo
    let validation: ValidationResult
    let parameters: OrderParameters
    
    var isValid: Bool {
        return validation.isValid
    }
    
    var description: String {
        var result = "📊 Order Creation Result:\n"
        result += "  Status: \(isValid ? "✅ Valid" : "❌ Invalid")\n"
        result += "  Salt: \(parameters.salt)\n"
        result += "  Nonce: \(parameters.nonce)\n"
        result += "  Making: \(order.makingAmount) of \(order.makerAsset)\n"
        result += "  Taking: \(order.takingAmount) of \(order.takerAsset)\n"
        
        if !validation.isValid {
            result += "  Issues:\n"
            for issue in validation.issues {
                result += "    • \(issue)\n"
            }
        }
        
        return result
    }
}

// MARK: - Order Factory Builder

/// Builder pattern for creating order factories with different configurations
class OrderFactoryBuilder {
    
    private var parameterGenerator: OrderParameterGeneratorProtocol?
    private var traitsCalculator: MakerTraitsCalculatorProtocol?
    private var orderValidator: OrderValidatorProtocol?
    private var logger: LoggerProtocol?
    
    /// Set parameter generator strategy
    func withParameterGenerator(_ strategy: ParameterGenerationStrategy) -> OrderFactoryBuilder {
        self.parameterGenerator = ParameterGeneratorFactory.createGenerator(strategy: strategy)
        return self
    }
    
    /// Set traits calculator configuration
    func withTraitsCalculator(_ configuration: MakerTraitsConfiguration) -> OrderFactoryBuilder {
        self.traitsCalculator = MakerTraitsCalculator(configuration: configuration)
        return self
    }
    
    /// Set order validator strategy
    func withOrderValidator(_ strategy: ValidationStrategy) -> OrderFactoryBuilder {
        self.orderValidator = ValidatorFactory.createValidator(strategy: strategy)
        return self
    }
    
    /// Set logger
    func withLogger(_ logger: LoggerProtocol) -> OrderFactoryBuilder {
        self.logger = logger
        return self
    }
    
    /// Build the order factory
    func build() -> OrderFactory {
        return OrderFactory(
            parameterGenerator: parameterGenerator ?? ParameterGeneratorFactory.createGenerator(strategy: .production),
            traitsCalculator: traitsCalculator ?? MakerTraitsCalculator(),
            orderValidator: orderValidator ?? ValidatorFactory.createValidator(strategy: .standard),
            logger: logger
        )
    }
}

// MARK: - Predefined Factory Configurations

extension OrderFactory {
    
    /// Create factory for production use
    static func createProductionFactory(logger: LoggerProtocol? = nil) -> OrderFactory {
        return OrderFactoryBuilder()
            .withParameterGenerator(.production)
            .withTraitsCalculator(.default)
            .withOrderValidator(.standard)
            .withLogger(logger ?? NoOpLogger())
            .build()
    }
    
    /// Create factory for market making
    static func createMarketMakingFactory(logger: LoggerProtocol? = nil) -> OrderFactory {
        return OrderFactoryBuilder()
            .withParameterGenerator(.production)
            .withTraitsCalculator(.advanced)
            .withOrderValidator(.strict)
            .withLogger(logger ?? NoOpLogger())
            .build()
    }
    
    /// Create factory for testing
    static func createTestFactory() -> OrderFactory {
        return OrderFactoryBuilder()
            .withParameterGenerator(.testing)
            .withTraitsCalculator(.default)
            .withOrderValidator(.basic)
            .build()
    }
}

// MARK: - No-Op Logger

/// Logger implementation that does nothing (for when no logging is needed)
class NoOpLogger: LoggerProtocol {
    func addLog(_ message: String) async {
        // Do nothing
    }
}