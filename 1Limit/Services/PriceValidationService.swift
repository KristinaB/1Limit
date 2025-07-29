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
    
    // Token addresses for Polygon (matching PriceService)
    private let tokenAddresses: [String: String] = [
        "WMATIC": "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
        "USDC": "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"
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
        // Normalize token names to match PriceService
        let normalizedFrom = normalizeTokenSymbol(fromToken)
        let normalizedTo = normalizeTokenSymbol(toToken)
        
        // Get token addresses
        guard let fromAddress = tokenAddresses[normalizedFrom],
              let toAddress = tokenAddresses[normalizedTo] else {
            throw PriceValidationError.unsupportedToken
        }
        
        // Special case: if both tokens are the same, rate is 1.0
        if normalizedFrom == normalizedTo {
            return 1.0
        }
        
        // Fetch prices from 1inch API
        let prices = try await fetchTokenPrices(tokens: [normalizedFrom: fromAddress, normalizedTo: toAddress])
        
        guard let fromPrice = prices[normalizedFrom],
              let toPrice = prices[normalizedTo],
              toPrice > 0 else {
            throw PriceValidationError.priceNotAvailable
        }
        
        // Calculate exchange rate (how much toToken per fromToken)
        return fromPrice / toPrice
    }
    
    private func normalizeTokenSymbol(_ token: String) -> String {
        switch token.uppercased() {
        case "MATIC", "WMATIC":
            return "WMATIC"
        case "USDC", "USDC.E", "USD COIN":
            return "USDC"
        default:
            return token.uppercased()
        }
    }
    
    private func fetchTokenPrices(tokens: [String: String]) async throws -> [String: Double] {
        guard let apiKey = loadAPIKey() else {
            throw PriceValidationError.noAPIKey
        }
        
        let baseURL = "https://api.1inch.dev/price/v1.1/137" // Polygon mainnet
        var tokenPrices: [String: Double] = [:]
        
        // Fetch each token price from 1inch API
        for (symbol, address) in tokens {
            do {
                var components = URLComponents(string: "\(baseURL)/\(address.lowercased())")!
                components.queryItems = [
                    URLQueryItem(name: "currency", value: "USD")
                ]
                
                guard let url = components.url else {
                    continue
                }
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await urlSession.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    continue
                }
                
                // Parse the JSON response: {"0x...": "0.9996755210754397"}
                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: String],
                      let priceString = jsonObject[address.lowercased()],
                      let usdPrice = Double(priceString) else {
                    continue
                }
                
                tokenPrices[symbol] = usdPrice
                
            } catch {
                print("⚠️ Failed to fetch price for \(symbol): \(error)")
            }
        }
        
        return tokenPrices
    }
    
    private func loadAPIKey() -> String? {
        // Try to load from app bundle
        if let path = Bundle.main.path(forResource: "api_keys", ofType: "txt") {
            if let content = try? String(contentsOfFile: path, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines),
               !content.isEmpty {
                return content
            }
        }
        return nil
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
    case noAPIKey
    
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
        case .noAPIKey:
            return "No API key found for 1inch service"
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