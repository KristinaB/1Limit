//
//  PriceService.swift
//  1Limit
//
//  1inch API integration for real-time price data 💎✨
//

import Foundation

/// Real-time price data from 1inch API
struct TokenPrice {
    let symbol: String
    let usdPrice: Double
    let lastUpdated: Date
    
    var formattedPrice: String {
        if usdPrice < 0.01 {
            return String(format: "$%.6f", usdPrice)
        } else if usdPrice < 1.0 {
            return String(format: "$%.4f", usdPrice)
        } else {
            return String(format: "$%.2f", usdPrice)
        }
    }
}

/// Swap calculation result
struct SwapCalculation {
    let fromAmount: Double
    let fromToken: String
    let fromUsdValue: Double
    let toAmount: Double
    let toToken: String
    let toUsdValue: Double
    let exchangeRate: Double
    
    var formattedFromValue: String {
        return String(format: "$%.2f", fromUsdValue)
    }
    
    var formattedToValue: String {
        return String(format: "$%.2f", toUsdValue)
    }
    
    var formattedRate: String {
        return String(format: "1 %@ = %.4f %@", fromToken, exchangeRate, toToken)
    }
}

/// 1inch API service for fetching real-time prices 🦋
@MainActor
class PriceService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var prices: [String: TokenPrice] = [:]
    @Published var isLoading = false
    @Published var lastError: Error?
    
    private let baseURL = "https://api.1inch.dev/price/v1.1/137" // Polygon mainnet
    private var apiKey: String? {
        loadAPIKey()
    }
    
    // Token addresses for Polygon 🌸
    private let tokenAddresses: [String: String] = [
        "WMATIC": "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
        "USDC": "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"
    ]
    
    // MARK: - Public Methods
    
    /// Fetch prices for all supported tokens
    func fetchPrices() async {
        guard let apiKey = apiKey else {
            print("❌ No API key found for 1inch service")
            return
        }
        
        isLoading = true
        lastError = nil
        
        do {
            let fetchedPrices = try await fetchTokenPrices(apiKey: apiKey)
            
            // Update prices on main thread
            await MainActor.run {
                self.prices = fetchedPrices
                self.isLoading = false
            }
            
            print("✅ Successfully fetched \(fetchedPrices.count) token prices")
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
            print("❌ Failed to fetch prices: \(error)")
        }
    }
    
    /// Get price for specific token
    func getPrice(for token: String) -> TokenPrice? {
        return prices[token]
    }
    
    /// Calculate swap values and exchange rate
    func calculateSwap(
        fromAmount: Double,
        fromToken: String,
        toToken: String
    ) -> SwapCalculation? {
        guard let fromPrice = getPrice(for: fromToken),
              let toPrice = getPrice(for: toToken),
              fromAmount > 0 else {
            return nil
        }
        
        let fromUsdValue = fromAmount * fromPrice.usdPrice
        let toAmount = fromUsdValue / toPrice.usdPrice
        let exchangeRate = fromPrice.usdPrice / toPrice.usdPrice
        
        return SwapCalculation(
            fromAmount: fromAmount,
            fromToken: fromToken,
            fromUsdValue: fromUsdValue,
            toAmount: toAmount,
            toToken: toToken,
            toUsdValue: fromUsdValue, // Same USD value for perfect swap
            exchangeRate: exchangeRate
        )
    }
    
    // MARK: - Private Methods
    
    private func loadAPIKey() -> String? {
        // Try to load from bundle first (for development)
        if let path = Bundle.main.path(forResource: "api_keys", ofType: "txt"),
           let content = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
           !content.isEmpty {
            return content
        }
        
        // Try to load from config directory
        let configPath = "/Users/makevoid/apps/1Limit/config/api_keys.txt"
        if let content = try? String(contentsOfFile: configPath).trimmingCharacters(in: .whitespacesAndNewlines),
           !content.isEmpty {
            return content
        }
        
        return nil
    }
    
    private func fetchTokenPrices(apiKey: String) async throws -> [String: TokenPrice] {
        print("🌐 Fetching prices from 1inch API...")
        
        var tokenPrices: [String: TokenPrice] = [:]
        let now = Date()
        
        // Fetch each token price individually
        for (symbol, address) in tokenAddresses {
            do {
                let url = URL(string: "\(baseURL)/\(address.lowercased())")!
                
                var request = URLRequest(url: url)
                request.httpMethod = "GET"
                request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
                request.setValue("application/json", forHTTPHeaderField: "Accept")
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    print("⚠️ Failed to fetch price for \(symbol)")
                    continue
                }
                
                // Parse the JSON response: {"0x...": "4247330692545463675"}
                guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: String],
                      let priceString = jsonObject[address.lowercased()],
                      let priceWei = Double(priceString) else {
                    print("⚠️ Invalid price data for \(symbol)")
                    continue
                }
                
                // Convert price based on token decimals
                // USDC has 6 decimals, WMATIC has 18 decimals
                let usdPrice: Double
                if symbol == "USDC" {
                    // USDC: divide by 10^6 (6 decimals)
                    usdPrice = priceWei / pow(10, 6)
                } else {
                    // WMATIC: divide by 10^18 (18 decimals)  
                    usdPrice = priceWei / pow(10, 18)
                }
                
                tokenPrices[symbol] = TokenPrice(
                    symbol: symbol,
                    usdPrice: usdPrice,
                    lastUpdated: now
                )
                
                print("💰 \(symbol): \(String(format: "$%.4f", usdPrice))")
                
            } catch {
                print("❌ Error fetching price for \(symbol): \(error)")
            }
        }
        
        return tokenPrices
    }
}

// MARK: - Error Types

enum PriceServiceError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case invalidJSON
    case noAPIKey
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from API"
        case .apiError(let code):
            return "API error with status code: \(code)"
        case .invalidJSON:
            return "Invalid JSON response"
        case .noAPIKey:
            return "No API key found"
        }
    }
}

// MARK: - Shared Instance

extension PriceService {
    static let shared = PriceService()
}