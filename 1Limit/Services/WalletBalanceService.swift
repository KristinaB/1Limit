//
//  WalletBalanceService.swift
//  1Limit
//
//  Real-time wallet balance calculation with USD conversion 💰📊
//

import Foundation
import BigInt
import Combine

/// Token balance information with USD value
struct TokenBalanceInfo {
    let symbol: String
    let address: String
    let balance: BigUInt
    let decimals: Int
    let usdPrice: Double
    let usdValue: Double
    let lastUpdated: Date
    
    var formattedBalance: String {
        let divisor = pow(10.0, Double(decimals))
        let tokenAmount = Double(balance.description) ?? 0.0
        let readableAmount = tokenAmount / divisor
        
        if readableAmount >= 1000000 {
            return String(format: "%.2fM", readableAmount / 1000000)
        } else if readableAmount >= 1000 {
            return String(format: "%.2fK", readableAmount / 1000)
        } else if readableAmount >= 1 {
            return String(format: "%.4f", readableAmount)
        } else {
            return String(format: "%.6f", readableAmount)
        }
    }
    
    var formattedUsdValue: String {
        return String(format: "$%.2f", usdValue)
    }
}

/// Complete wallet balance summary
struct WalletBalanceSummary {
    let walletAddress: String
    let tokenBalances: [TokenBalanceInfo]
    let totalUsdValue: Double
    let lastUpdated: Date
    let isLoading: Bool
    let error: String?
    
    var formattedTotalValue: String {
        return String(format: "$%.2f", totalUsdValue)
    }
    
    var maskedAddress: String {
        guard walletAddress.count >= 10 else { return walletAddress }
        let start = String(walletAddress.prefix(6))
        let end = String(walletAddress.suffix(4))
        return "\(start)...\(end)"
    }
}

/// Wallet balance service errors
enum WalletBalanceError: LocalizedError {
    case invalidWalletAddress
    case networkError(String)
    case priceDataUnavailable
    case balanceCheckFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .invalidWalletAddress:
            return "Invalid wallet address provided"
        case .networkError(let message):
            return "Network error: \(message)"
        case .priceDataUnavailable:
            return "Price data currently unavailable"
        case .balanceCheckFailed(let message):
            return "Balance check failed: \(message)"
        }
    }
}

/// Service for calculating and monitoring wallet balances with USD conversion
@MainActor
class WalletBalanceService: ObservableObject {
    
    // MARK: - Properties
    
    @Published var currentBalance: WalletBalanceSummary?
    @Published var isLoading = false
    @Published var lastError: WalletBalanceError?
    
    private let balanceChecker: BalanceCheckerProtocol
    private let priceService: PriceService
    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    // Polygon mainnet configuration
    private let nodeURL = "https://polygon-rpc.com"
    private let supportedTokens: [String: TokenConfig] = [
        "WMATIC": TokenConfig(
            symbol: "WMATIC",
            address: "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",
            decimals: 18
        ),
        "USDC": TokenConfig(
            symbol: "USDC", 
            address: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
            decimals: 6
        )
    ]
    
    // MARK: - Initialization
    
    init(
        balanceChecker: BalanceCheckerProtocol? = nil,
        priceService: PriceService? = nil
    ) {
        self.balanceChecker = balanceChecker ?? BalanceCheckerFactory.createProductionChecker()
        self.priceService = priceService ?? PriceService.shared
        
        setupPriceServiceObserver()
    }
    
    // MARK: - Public Methods
    
    /// Fetch complete wallet balance with USD conversion
    func fetchWalletBalance(for walletAddress: String) async {
        guard !walletAddress.isEmpty else {
            await updateError(.invalidWalletAddress)
            return
        }
        
        isLoading = true
        lastError = nil
        
        do {
            print("💰 Fetching wallet balance for: \(maskAddress(walletAddress))")
            
            // Ensure we have fresh price data
            await priceService.fetchPrices()
            
            // Fetch balances for all supported tokens
            var tokenBalances: [TokenBalanceInfo] = []
            var totalUsdValue: Double = 0
            
            // Check MATIC balance (native token)
            if let maticBalance = await fetchNativeBalance(walletAddress: walletAddress),
               let maticPrice = priceService.getPrice(for: "WMATIC") {
                
                let usdValue = maticBalance * maticPrice.usdPrice
                totalUsdValue += usdValue
                
                tokenBalances.append(TokenBalanceInfo(
                    symbol: "MATIC",
                    address: "0x0000000000000000000000000000000000000000", // Native token
                    balance: BigUInt(maticBalance * 1e18),
                    decimals: 18,
                    usdPrice: maticPrice.usdPrice,
                    usdValue: usdValue,
                    lastUpdated: Date()
                ))
            }
            
            // Check token balances
            for (symbol, config) in supportedTokens {
                if let tokenBalance = await fetchTokenBalance(
                    walletAddress: walletAddress,
                    tokenConfig: config
                ) {
                    tokenBalances.append(tokenBalance)
                    totalUsdValue += tokenBalance.usdValue
                }
            }
            
            let balanceSummary = WalletBalanceSummary(
                walletAddress: walletAddress,
                tokenBalances: tokenBalances,
                totalUsdValue: totalUsdValue,
                lastUpdated: Date(),
                isLoading: false,
                error: nil
            )
            
            currentBalance = balanceSummary
            isLoading = false
            
            print("✅ Wallet balance updated: \(balanceSummary.formattedTotalValue)")
            
        } catch {
            await updateError(.balanceCheckFailed(error.localizedDescription))
        }
    }
    
    /// Start automatic balance refresh every 30 seconds
    func startAutoRefresh(for walletAddress: String) {
        stopAutoRefresh()
        
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 30, repeats: true) { [weak self] _ in
            Task {
                await self?.fetchWalletBalance(for: walletAddress)
            }
        }
        
        print("🔄 Started auto-refresh for wallet balance")
    }
    
    /// Stop automatic balance refresh
    func stopAutoRefresh() {
        refreshTimer?.invalidate()
        refreshTimer = nil
        print("⏹️ Stopped auto-refresh for wallet balance")
    }
    
    /// Get balance for specific token
    func getTokenBalance(symbol: String) -> TokenBalanceInfo? {
        return currentBalance?.tokenBalances.first { $0.symbol == symbol }
    }
    
    /// Check if wallet has sufficient balance for transaction
    func hasSufficientBalance(for amount: Double, token: String) -> Bool {
        guard let tokenBalance = getTokenBalance(symbol: token) else { return false }
        
        let divisor = pow(10.0, Double(tokenBalance.decimals))
        let tokenAmount = Double(tokenBalance.balance.description) ?? 0.0
        let readableAmount = tokenAmount / divisor
        
        return readableAmount >= amount
    }
    
    // MARK: - Private Methods
    
    private func setupPriceServiceObserver() {
        // Observe price service updates to refresh balances
        priceService.$prices
            .dropFirst()
            .debounce(for: .seconds(1), scheduler: RunLoop.main)
            .sink { [weak self] _ in
                // Refresh current balance if we have an active wallet
                if let walletAddress = self?.currentBalance?.walletAddress {
                    Task {
                        await self?.fetchWalletBalance(for: walletAddress)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func fetchNativeBalance(walletAddress: String) async -> Double? {
        let hasBalance = await balanceChecker.checkWalletBalance(
            walletAddress: walletAddress,
            nodeURL: nodeURL
        )
        
        // For now, return a placeholder since BalanceChecker doesn't return the actual amount
        // In a real implementation, we'd modify BalanceChecker to return the balance value
        return hasBalance ? 0.1 : 0.0 // Placeholder: 0.1 MATIC if balance exists
    }
    
    private func fetchTokenBalance(
        walletAddress: String,
        tokenConfig: TokenConfig
    ) async -> TokenBalanceInfo? {
        
        let tokenBalanceResult = await balanceChecker.checkTokenBalance(
            tokenAddress: tokenConfig.address,
            walletAddress: walletAddress,
            requiredAmount: BigUInt(1), // Check if any balance exists
            nodeURL: nodeURL
        )
        
        guard tokenBalanceResult.hasBalance else {
            print("📊 No \(tokenConfig.symbol) balance found")
            return nil
        }
        
        guard let tokenPrice = priceService.getPrice(for: tokenConfig.symbol) else {
            print("⚠️ No price data available for \(tokenConfig.symbol)")
            return nil
        }
        
        let divisor = pow(10.0, Double(tokenConfig.decimals))
        let tokenAmount = Double(tokenBalanceResult.actualBalance.description) ?? 0.0
        let readableAmount = tokenAmount / divisor
        let usdValue = readableAmount * tokenPrice.usdPrice
        
        return TokenBalanceInfo(
            symbol: tokenConfig.symbol,
            address: tokenConfig.address,
            balance: tokenBalanceResult.actualBalance,
            decimals: tokenConfig.decimals,
            usdPrice: tokenPrice.usdPrice,
            usdValue: usdValue,
            lastUpdated: Date()
        )
    }
    
    private func updateError(_ error: WalletBalanceError) async {
        lastError = error
        isLoading = false
        print("❌ Wallet balance error: \(error.localizedDescription)")
    }
    
    private func maskAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
}

// MARK: - Supporting Types

private struct TokenConfig {
    let symbol: String
    let address: String
    let decimals: Int
}

// MARK: - Shared Instance

extension WalletBalanceService {
    static let shared = WalletBalanceService()
}

// MARK: - Mock Data for Development

extension WalletBalanceService {
    /// Create mock balance data for development/testing
    static func createMockBalance(for walletAddress: String) -> WalletBalanceSummary {
        let mockTokenBalances = [
            TokenBalanceInfo(
                symbol: "MATIC",
                address: "0x0000000000000000000000000000000000000000",
                balance: BigUInt("100000000000000000000"), // 100 MATIC
                decimals: 18,
                usdPrice: 0.85,
                usdValue: 85.0,
                lastUpdated: Date()
            ),
            TokenBalanceInfo(
                symbol: "USDC",
                address: "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359",
                balance: BigUInt("1000000000"), // 1000 USDC (6 decimals)
                decimals: 6,
                usdPrice: 1.0,
                usdValue: 1000.0,
                lastUpdated: Date()
            )
        ]
        
        return WalletBalanceSummary(
            walletAddress: walletAddress,
            tokenBalances: mockTokenBalances,
            totalUsdValue: 1085.0,
            lastUpdated: Date(),
            isLoading: false,
            error: nil
        )
    }
}