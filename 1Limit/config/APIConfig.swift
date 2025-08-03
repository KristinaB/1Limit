import Foundation

class APIConfig {
    
    // MARK: - Configuration Options
    
    enum APIProvider: String, CaseIterable {
        case authenticated = "authenticated"
        case proxy = "proxy"
        
        var displayName: String {
            switch self {
            case .authenticated:
                return "1inch API (Authenticated)"
            case .proxy:
                return "1inch Proxy (No Auth)"
            }
        }
    }
    
    // MARK: - Singleton
    
    static let shared = APIConfig()
    
    private init() {}
    
    // MARK: - Configuration
    
    private var currentProvider: APIProvider = .proxy // Default to proxy for no auth required
    
    var provider: APIProvider {
        get { currentProvider }
        set { currentProvider = newValue }
    }
    
    // MARK: - Base URLs
    
    private let authenticatedBaseURL = "https://api.1inch.dev"
    private let proxyBaseURL = "https://1limit-1inch-api-proxy.vercel.app"
    
    var baseURL: String {
        switch currentProvider {
        case .authenticated:
            return authenticatedBaseURL
        case .proxy:
            return proxyBaseURL
        }
    }
    
    // MARK: - API Endpoints
    
    func priceEndpoint(chainID: Int = 137) -> String {
        switch currentProvider {
        case .authenticated:
            return "\(baseURL)/price/v1.1/\(chainID)"
        case .proxy:
            return "\(baseURL)/price/v1.1/\(chainID)"
        }
    }
    
    func swapEndpoint(chainID: Int = 137) -> String {
        switch currentProvider {
        case .authenticated:
            return "\(baseURL)/swap/v6.0/\(chainID)/swap"
        case .proxy:
            return "\(baseURL)/swap/v6.0/\(chainID)/swap"
        }
    }
    
    func chartLineEndpoint() -> String {
        switch currentProvider {
        case .authenticated:
            return "\(baseURL)/charts/v1.0/chart/line"
        case .proxy:
            return "\(baseURL)/charts/v1.0/chart/line"
        }
    }
    
    func chartCandleEndpoint() -> String {
        switch currentProvider {
        case .authenticated:
        return "\(baseURL)/charts/v1.0/chart/aggregated/candle"
        case .proxy:
            return "\(baseURL)/charts/v1.0/chart/aggregated/candle"
        }
    }
    
    // MARK: - Authentication
    
    var requiresAuthentication: Bool {
        switch currentProvider {
        case .authenticated:
            return true
        case .proxy:
            return false
        }
    }
    
    // MARK: - Debug Info
    
    func debugInfo() -> String {
        return """
        API Config:
        - Provider: \(provider.displayName)
        - Base URL: \(baseURL)
        - Requires Auth: \(requiresAuthentication)
        """
    }
}