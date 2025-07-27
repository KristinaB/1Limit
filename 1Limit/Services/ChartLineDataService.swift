//
//  ChartLineDataService.swift
//  1Limit
//
//  1inch Charts API integration for line chart data 📈✨
//

import Foundation

/// Line chart data point
struct LineChartData: Identifiable, Codable {
    let id = UUID()
    let timestamp: Date
    let price: Double
    
    /// Formatted price string
    var formattedPrice: String { 
        String(format: "%.6f", price) 
    }
}

/// Chart time periods for line charts
enum ChartPeriod: String, CaseIterable {
    case oneHour = "1H"
    case sixHours = "6H"
    case twelveHours = "12H"
    case twentyFourHours = "24H"
    case oneWeek = "1W"
    case oneMonth = "1M"
    
    var displayName: String {
        return rawValue
    }
}

/// 1inch Charts API service for line chart data 📊
@MainActor
class ChartLineDataService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var lineChartData: [LineChartData] = []
    @Published var isLoading = false
    @Published var lastError: Error?
    @Published var currentPeriod: ChartPeriod = .twentyFourHours
    
    private let baseURL = "https://api.1inch.dev/charts/v1.0/chart/line"
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
    
    static let shared = ChartLineDataService()
    private init() {}
    
    // MARK: - Public Methods
    
    /// Fetch line chart data for a currency pair
    func fetchLineChartData(fromToken: String, toToken: String, period: ChartPeriod = .twentyFourHours) async {
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
        currentPeriod = period
        
        do {
            let fetchedData = try await fetchLineData(
                fromAddress: fromAddress,
                toAddress: toAddress,
                period: period,
                apiKey: apiKey
            )
            
            // Update data on main thread
            await MainActor.run {
                self.lineChartData = fetchedData
                self.isLoading = false
            }
            
            print("📈 Successfully fetched \(fetchedData.count) line chart data points for \(fromToken)/\(toToken)")
            
        } catch {
            await MainActor.run {
                self.lastError = error
                self.isLoading = false
            }
            print("❌ Failed to fetch line chart data: \(error)")
        }
    }
    
    /// Get the latest price from chart data
    func getCurrentPrice() -> Double? {
        return lineChartData.last?.price
    }
    
    /// Get price change over the period
    func getPriceChange() -> (absolute: Double, percentage: Double)? {
        guard let first = lineChartData.first,
              let last = lineChartData.last else {
            return nil
        }
        
        let absolute = last.price - first.price
        let percentage = first.price != 0 ? (absolute / first.price) * 100 : 0
        
        return (absolute: absolute, percentage: percentage)
    }
    
    /// Get hourly data points (last 24 points)
    func getHourlyDataPoints(count: Int = 24) -> [LineChartData] {
        guard !lineChartData.isEmpty else { return [] }
        
        // If we have more data than needed, sample it
        if lineChartData.count > count {
            let step = lineChartData.count / count
            return stride(from: 0, to: lineChartData.count, by: step).compactMap { index in
                guard index < lineChartData.count else { return nil }
                return lineChartData[index]
            }
        }
        
        return lineChartData
    }
    
    // MARK: - Private Methods
    
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
    
    private func fetchLineData(
        fromAddress: String,
        toAddress: String,
        period: ChartPeriod,
        apiKey: String
    ) async throws -> [LineChartData] {
        
        // Build the API URL
        let urlString = "\(baseURL)/\(fromAddress.lowercased())/\(toAddress.lowercased())/\(period.rawValue)/\(chainId)"
        
        guard let url = URL(string: urlString) else {
            throw ChartDataError.invalidURL
        }
        
        // Create request with API key
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        print("📊 Fetching line chart data from: \(urlString)")
        
        // Make the API request
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw ChartDataError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            print("❌ Line chart API request failed with status: \(httpResponse.statusCode)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("Response: \(responseString)")
            }
            throw ChartDataError.apiError(httpResponse.statusCode)
        }
        
        // Parse the JSON response
        guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[Any]],
              !jsonArray.isEmpty else {
            throw ChartDataError.invalidJSON
        }
        
        // Convert to LineChartData objects
        var lineData: [LineChartData] = []
        
        for item in jsonArray {
            guard item.count >= 2,
                  let timestampValue = item[0] as? Double,
                  let priceValue = item[1] as? Double else {
                continue
            }
            
            let dataPoint = LineChartData(
                timestamp: Date(timeIntervalSince1970: timestampValue / 1000), // Convert from milliseconds
                price: priceValue
            )
            
            lineData.append(dataPoint)
        }
        
        // Sort by timestamp
        lineData.sort { $0.timestamp < $1.timestamp }
        
        print("📈 Parsed \(lineData.count) line chart data points")
        
        return lineData
    }
}

// MARK: - Widget Data Conversion

extension ChartLineDataService {
    
    /// Get line chart data for widget use
    func getLineDataForWidget() -> [LineChartData] {
        return lineChartData
    }
    
    /// Get smoothed data points for widget display
    func getSmoothedDataPoints(windowSize: Int = 3) -> [LineChartData] {
        guard lineChartData.count > windowSize else { return lineChartData }
        
        var smoothedData: [LineChartData] = []
        
        for i in 0..<lineChartData.count {
            let startIndex = max(0, i - windowSize / 2)
            let endIndex = min(lineChartData.count - 1, i + windowSize / 2)
            
            let sum = lineChartData[startIndex...endIndex].reduce(0.0) { $0 + $1.price }
            let average = sum / Double(endIndex - startIndex + 1)
            
            let smoothedPoint = LineChartData(
                timestamp: lineChartData[i].timestamp,
                price: average
            )
            
            smoothedData.append(smoothedPoint)
        }
        
        return smoothedData
    }
}