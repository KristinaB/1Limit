//
//  PriceValidationService.swift
//  1Limit
//
//  Price validation service for limit orders using real market data
//

import Foundation

/// Price validation result
struct PriceValidationResult {
    let isValid: Bool
    let marketPrice: Double
    let userPrice: Double
    let percentageDifference: Double
    let warningMessage: String?
    let recommendedRange: ClosedRange<Double>
}

/// Protocol for price validation operations
protocol PriceValidationProtocol {
    func validateLimitPrice(
        fromToken: String,
        toToken: String,
        userPrice: Double
    ) async -> PriceValidationResult
}

/// Price validation service using market APIs
@MainActor
class PriceValidationService: ObservableObject, PriceValidationProtocol {
    
    // MARK: - Configuration
    
    private let allowedPriceDeviation: Double = 0.30 // 30% deviation allowed
    private let urlSession: URLSession
    
    // Token price mapping (CoinGecko IDs)
    private let tokenPriceIds: [String: String] = [
        "WMATIC": "wmatic",
        "MATIC": "matic-network",
        "USDC": "usd-coin",
        "USDT": "tether",
        "DAI": "dai"
    ]
    
    // MARK: - Initialization
    
    init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }
    
    // MARK: - Price Validation
    
    func validateLimitPrice(
        fromToken: String,
        toToken: String,
        userPrice: Double
    ) async -> PriceValidationResult {
        
        do {
            // Get current market prices
            let marketRate = try await getCurrentMarketRate(from: fromToken, to: toToken)
            
            // Calculate percentage difference
            let percentageDiff = abs(userPrice - marketRate) / marketRate
            
            // Determine if price is within acceptable range
            let isWithinRange = percentageDiff <= allowedPriceDeviation
            
            // Calculate recommended price range
            let lowerBound = marketRate * (1 - allowedPriceDeviation)
            let upperBound = marketRate * (1 + allowedPriceDeviation)
            let recommendedRange = lowerBound...upperBound
            
            // Generate warning message if needed
            let warningMessage = generateWarningMessage(
                fromToken: fromToken,
                toToken: toToken,
                marketRate: marketRate,
                userPrice: userPrice,
                percentageDiff: percentageDiff,
                isWithinRange: isWithinRange
            )
            
            return PriceValidationResult(
                isValid: isWithinRange,
                marketPrice: marketRate,
                userPrice: userPrice,
                percentageDifference: percentageDiff,
                warningMessage: warningMessage,
                recommendedRange: recommendedRange
            )
            
        } catch {
            print("⚠️ Price validation error: \(error)")
            
            // Return conservative result if API fails
            return PriceValidationResult(
                isValid: false,
                marketPrice: 0,
                userPrice: userPrice,
                percentageDifference: 1.0,
                warningMessage: "Unable to validate price against current market rates. Please verify your limit price manually.",
                recommendedRange: 0...0
            )
        }
    }
    
    // MARK: - Market Data Fetching
    
    private func getCurrentMarketRate(from fromToken: String, to toToken: String) async throws -> Double {
        // Get prices for both tokens
        let fromTokenId = tokenPriceIds[fromToken.uppercased()]
        let toTokenId = tokenPriceIds[toToken.uppercased()]
        
        guard let fromId = fromTokenId, let toId = toTokenId else {
            throw PriceValidationError.unsupportedToken
        }
        
        // Special case: if both tokens are the same, rate is 1.0
        if fromId == toId {
            return 1.0
        }
        
        // Fetch prices from CoinGecko API
        let prices = try await fetchTokenPrices(tokenIds: [fromId, toId])
        
        guard let fromPrice = prices[fromId],
              let toPrice = prices[toId],
              toPrice > 0 else {
            throw PriceValidationError.priceNotAvailable
        }
        
        // Calculate exchange rate (how much toToken per fromToken)
        return fromPrice / toPrice
    }
    
    private func fetchTokenPrices(tokenIds: [String]) async throws -> [String: Double] {
        let idsString = tokenIds.joined(separator: ",")
        let urlString = "https://api.coingecko.com/api/v3/simple/price?ids=\(idsString)&vs_currencies=usd"
        
        guard let url = URL(string: urlString) else {
            throw PriceValidationError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw PriceValidationError.apiError
        }
        
        let priceData = try JSONDecoder().decode([String: [String: Double]].self, from: data)
        
        // Extract USD prices
        var prices: [String: Double] = [:]
        for (tokenId, priceInfo) in priceData {
            if let usdPrice = priceInfo["usd"] {
                prices[tokenId] = usdPrice
            }
        }
        
        return prices
    }
    
    // MARK: - Warning Message Generation
    
    private func generateWarningMessage(
        fromToken: String,
        toToken: String,
        marketRate: Double,
        userPrice: Double,
        percentageDiff: Double,
        isWithinRange: Bool
    ) -> String? {
        
        if isWithinRange {
            return nil // No warning needed
        }
        
        let percentageDisplay = String(format: "%.1f%%", percentageDiff * 100)
        let marketPriceFormatted = String(format: "%.6f", marketRate)
        let allowedPercentage = String(format: "%.0f%%", allowedPriceDeviation * 100)
        
        if userPrice > marketRate {
            // User price is above market
            return "⚠️ Your limit price is \(percentageDisplay) above current market rate (\(marketPriceFormatted) \(toToken) per \(fromToken)). Orders more than \(allowedPercentage) from market price may fail to execute. Consider adjusting your price."
        } else {
            // User price is below market  
            return "⚠️ Your limit price is \(percentageDisplay) below current market rate (\(marketPriceFormatted) \(toToken) per \(fromToken)). Orders more than \(allowedPercentage) from market price may fail to execute. Consider adjusting your price."
        }
    }
}

// MARK: - Error Types

enum PriceValidationError: Error, LocalizedError {
    case unsupportedToken
    case priceNotAvailable
    case invalidURL
    case apiError
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .unsupportedToken:
            return "Token not supported for price validation"
        case .priceNotAvailable:
            return "Price data not available"
        case .invalidURL:
            return "Invalid API URL"
        case .apiError:
            return "API request failed"
        case .networkError:
            return "Network connection error"
        }
    }
}

// MARK: - Mock Implementation for Testing

class MockPriceValidationService: PriceValidationProtocol {
    var mockResult: PriceValidationResult?
    var shouldThrowError = false
    
    func validateLimitPrice(
        fromToken: String,
        toToken: String,
        userPrice: Double
    ) async -> PriceValidationResult {
        
        if shouldThrowError {
            return PriceValidationResult(
                isValid: false,
                marketPrice: 0,
                userPrice: userPrice,
                percentageDifference: 1.0,
                warningMessage: "Mock validation error",
                recommendedRange: 0...0
            )
        }
        
        return mockResult ?? PriceValidationResult(
            isValid: true,
            marketPrice: userPrice,
            userPrice: userPrice,
            percentageDifference: 0.0,
            warningMessage: nil,
            recommendedRange: userPrice...userPrice
        )
    }
}