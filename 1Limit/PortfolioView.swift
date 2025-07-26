//
//  PortfolioView.swift
//  1Limit
//
//  Main portfolio dashboard with balance, chart, and orders 📊💎
//

import SwiftUI

struct PortfolioView: View {
    @State private var showPlaceOrder = false
    @State private var orderType: OrderType = .buy
    
    // Mock portfolio data
    @State private var totalBalance = "2.47 ETH"
    @State private var usdValue = "$4,127.82 USD"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Balance header with gradient
                        balanceHeader
                        
                        // Price chart placeholder
                        priceChartSection
                        
                        // Buy/Sell buttons
                        tradingButtons
                        
                        // Open orders section
                        openOrdersSection
                        
                        Spacer(minLength: 40)
                    }
                }
            }
            .navigationTitle("Portfolio")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SmallButton("⚙️", style: .secondary) {
                        // Settings action
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showPlaceOrder) {
            PlaceOrderView(orderType: orderType)
        }
    }
    
    private var balanceHeader: some View {
        AppCard {
            VStack(spacing: 16) {
                Text("Total Balance")
                    .secondaryText()
                
                Text(totalBalance)
                    .font(.system(size: 36, weight: .bold, design: .default))
                    .foregroundColor(.primaryText)
                
                Text(usdValue)
                    .font(.title3)
                    .foregroundColor(.secondaryText)
            }
            .padding(.vertical, 8)
        }
        .background(
            LinearGradient(
                colors: [Color.primaryGradientStart.opacity(0.3), Color.primaryGradientEnd.opacity(0.3)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(16)
        .padding(.horizontal)
    }
    
    private var priceChartSection: some View {
        AppCard {
            VStack(spacing: 16) {
                Text("Price Chart (24h)")
                    .cardTitle()
                
                // Chart placeholder
                Rectangle()
                    .fill(Color.inputBackground)
                    .frame(height: 180)
                    .overlay(
                        VStack {
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 40))
                                .foregroundColor(.secondaryText)
                            Text("Chart Coming Soon")
                                .secondaryText()
                        }
                    )
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    private var tradingButtons: some View {
        HStack(spacing: 16) {
            // Buy button
            Button(action: {
                orderType = .buy
                showPlaceOrder = true
            }) {
                Text("Buy")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.successGreen)
                    .cornerRadius(12)
            }
            
            // Sell button  
            Button(action: {
                orderType = .sell
                showPlaceOrder = true
            }) {
                Text("Sell")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.errorRed)
                    .cornerRadius(12)
            }
        }
        .padding(.horizontal)
    }
    
    private var openOrdersSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Open Orders")
                .sectionTitle()
                .padding(.horizontal)
            
            VStack(spacing: 12) {
                // Sample orders
                OrderCard(
                    pair: "ETH/USDC",
                    type: .buy,
                    amount: "0.5 ETH",
                    price: "$1,650.00",
                    total: "$825.00"
                )
                
                OrderCard(
                    pair: "BTC/USDC", 
                    type: .sell,
                    amount: "0.01 BTC",
                    price: "$42,000.00",
                    total: "$420.00"
                )
            }
            .padding(.horizontal)
        }
    }
}

struct OrderCard: View {
    let pair: String
    let type: OrderType
    let amount: String
    let price: String
    let total: String
    
    var body: some View {
        ListItemCard {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text(pair)
                        .cardTitle()
                    
                    Spacer()
                    
                    Text(type.rawValue.uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(type == .buy ? Color.successGreen : Color.errorRed)
                        .cornerRadius(8)
                }
                
                Text("Amount: \(amount) • Price: \(price) • Total: \(total)")
                    .secondaryText()
            }
        }
    }
}

enum OrderType: String, CaseIterable {
    case buy = "buy"
    case sell = "sell"
    
    var displayName: String {
        return rawValue.capitalized
    }
}

#Preview {
    PortfolioView()
}