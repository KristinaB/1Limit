//
//  ChartDataService.swift
//  1Limit
//
//  1inch Charts API integration for OHLC candlestick data 📈✨
//

import Foundation

/// OHLC candlestick data point
struct CandlestickData: Identifiable {
    let id = UUID()
    let timestamp: Date
    let open: Double
    let high: Double
    let low: Double
    let close: Double
    let volume: Double
    
    /// Price change from open to close
    var priceChange: Double {
        return close - open
    }
    
    /// Percentage change from open to close
    var percentageChange: Double {
        guard open != 0 else { return 0 }
        return (priceChange / open) * 100
    }
    
    /// Is this a bullish (green) candle?
    var isBullish: Bool {
        return close >= open
    }
    
    /// Formatted price strings
    var formattedOpen: String { String(format: "%.6f", open) }
    var formattedHigh: String { String(format: "%.6f", high) }
    var formattedLow: String { String(format: "%.6f", low) }
    var formattedClose: String { String(format: "%.6f", close) }
    var formattedVolume: String { String(format: "%.2f", volume) }
    var formattedChange: String { 
        let sign = priceChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.6f", priceChange))"
    }
    var formattedPercentChange: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.2f", percentageChange))%"
    }
}

/// Chart time intervals
enum ChartTimeframe: String, CaseIterable {
    case oneHour = "3600"       // 1 hour
    case fourHours = "14400"    // 4 hours  
    case oneDay = "86400"       // 1 day
    case oneWeek = "604800"     // 1 week
    
    var displayName: String {
        switch self {
        case .oneHour: return "1H"
        case .fourHours: return "4H"
        case .oneDay: return "1D"
        case .oneWeek: return "1W"
        }
    }
    
    var seconds: Int {
        return Int(rawValue) ?? 3600
    }
}

/// 1inch Charts API service for OHLC data 🦋
@MainActor
class ChartDataService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var candlestickData: [CandlestickData] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    @Published var currentTimeframe: ChartTimeframe = .oneHour
    
    private let baseURL = "https://api.1inch.dev/charts/v1.0/chart/aggregated/candle"
    private let chainId = "137" // Polygon mainnet
    
    private var apiKey: String? {
        loadAPIKey()
    }
    
    // Token addresses for chart pairs 🌸
    private let tokenAddresses: [String: String] = [
        "WMATIC": "0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270",
        "USDC": "0x3c499c542cef5e3811e1192ce70d8cc03d5c3359"
    ]
    
    // MARK: - Singleton
    
    static let shared = ChartDataService()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch OHLC data for a currency pair
    func fetchChartData(fromToken: String, toToken: String, timeframe: ChartTimeframe = .oneHour) async {
        guard let apiKey = apiKey else {
            print("❌ No API key found for 1inch charts service")
            return
        }
        
        guard let fromAddress = tokenAddresses[fromToken],
              let toAddress = tokenAddresses[toToken] else {
            print("❌ Unsupported token pair: \(fromToken)/\(toToken)")
            return
        }
        
        isLoading = true
        lastError = nil
        currentTimeframe = timeframe
        
        do {
            let fetchedData = try await fetchCandlestickData(
                fromAddress: fromAddress,
                toAddress: toAddress,
                timeframe: timeframe,
                apiKey: apiKey
            )
            
            // Update data on main thread
            await MainActor.run {
                self.candlestickData = fetchedData
                self.isLoading = false
            }
            
            print("📈 Successfully fetched \(fetchedData.count) candlestick data points for \(fromToken)/\(toToken)")
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
            print("❌ Failed to fetch chart data: \(error)")
        }
    }
    
    /// Get the latest price from chart data
    func getCurrentPrice() -> Double? {
        return candlestickData.last?.close
    }
    
    /// Get price change over the timeframe
    func getPriceChange() -> (absolute: Double, percentage: Double)? {
        guard let first = candlestickData.first,
              let last = candlestickData.last else {
            return nil
        }
        
        let absolute = last.close - first.open
        let percentage = first.open != 0 ? (absolute / first.open) * 100 : 0
        
        return (absolute: absolute, percentage: percentage)
    }
    
    // MARK: - Private Methods
    
    private func loadAPIKey() -> String? {
        // Try to load from project directory first
        let currentDir = FileManager.default.currentDirectoryPath
        let path = "\(currentDir)/tmp/.1inch_api_key"
        
        if let content = try? String(contentsOfFile: path).trimmingCharacters(in: .whitespacesAndNewlines),
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
    
    private func fetchCandlestickData(
        fromAddress: String,
        toAddress: String,
        timeframe: ChartTimeframe,
        apiKey: String
    ) async throws -> [CandlestickData] {
        
        // Build the API URL
        let urlString = "\(baseURL)/\(fromAddress.lowercased())/\(toAddress.lowercased())/\(timeframe.rawValue)/\(chainId)"
        
        guard let url = URL(string: urlString) else {
            throw ChartDataError.invalidURL
        }
        
        // Create request with API key
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("📊 Fetching OHLC data from: \(urlString)")
        
        // Make the API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChartDataError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Chart API request failed with status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw ChartDataError.apiError(httpResponse.statusCode)
        }
        
        // Parse the JSON response - API returns {"data": [...]}
        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let jsonArray = jsonObject["data"] as? [[String: Any]] else {
            throw ChartDataError.invalidJSON
        }
        
        // Convert to CandlestickData objects
        var candlesticks: [CandlestickData] = []
        
        for item in jsonArray {
            guard let timestampValue = item["time"] as? Double,
                  let openValue = item["open"] as? Double,
                  let highValue = item["high"] as? Double,
                  let lowValue = item["low"] as? Double,
                  let closeValue = item["close"] as? Double else {
                continue
            }
            
            // Volume might not be present in this API format, default to 0
            let volumeValue = item["volume"] as? Double ?? 0
            
            let candlestick = CandlestickData(
                timestamp: Date(timeIntervalSince1970: timestampValue),
                open: openValue,
                high: highValue,
                low: lowValue,
                close: closeValue,
                volume: volumeValue
            )
            
            candlesticks.append(candlestick)
        }
        
        // Sort by timestamp
        candlesticks.sort { $0.timestamp < $1.timestamp }
        
        print("📈 Parsed \(candlesticks.count) candlestick data points")
        
        return candlesticks
    }
}

// MARK: - Error Types

enum ChartDataError: LocalizedError {
    case invalidURL
    case invalidResponse
    case apiError(Int)
    case invalidJSON
    case noAPIKey
    case unsupportedPair
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid chart API URL"
        case .invalidResponse:
            return "Invalid response from chart API"
        case .apiError(let code):
            return "Chart API error with status code: \(code)"
        case .invalidJSON:
            return "Invalid JSON response from chart API"
        case .noAPIKey:
            return "No API key found for chart service"
        case .unsupportedPair:
            return "Unsupported token pair for charts"
        }
    }
}