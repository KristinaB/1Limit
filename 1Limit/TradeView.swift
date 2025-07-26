//
//  TradeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct TradeView: View {
    @State private var fromAmount = ""
    @State private var toAmount = ""
    @State private var fromToken = "WMATIC"
    @State private var toToken = "USDC"
    @State private var showingChart = false
    @StateObject private var priceService = PriceService.shared
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header with chart button 📈
                    AppCard {
                        VStack(spacing: 16) {
                            HStack {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: 40))
                                    .foregroundColor(.primaryGradientStart)
                                
                                Spacer()
                                
                                SmallButton("Chart", style: .primary) {
                                    showingChart = true
                                }
                            }
                            
                            Text("Create Limit Order")
                                .sectionTitle()
                            
                            // Currency pair with prices 🎀
                            VStack(spacing: 8) {
                                Text("\(fromToken)/\(toToken)")
                                    .cardTitle()
                                
                                if priceService.isLoading {
                                    HStack(spacing: 4) {
                                        ProgressView()
                                            .scaleEffect(0.7)
                                        Text("Loading prices...")
                                            .captionText()
                                    }
                                } else {
                                    HStack(spacing: 8) {
                                        if let fromPrice = priceService.getPrice(for: fromToken) {
                                            Text("\(fromToken): \(fromPrice.formattedPrice)")
                                                .captionText()
                                        }
                                        Text("•")
                                            .captionText()
                                        if let toPrice = priceService.getPrice(for: toToken) {
                                            Text("\(toToken): \(toPrice.formattedPrice)")
                                                .captionText()
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.inputBackground)
                            )
                        }
                    }
                
                // Trading form
                VStack(spacing: 16) {
                    // From section
                    InputCard(title: "From") {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                AppTextField("0.00", text: $fromAmount, keyboardType: .decimalPad)
                                    .onChange(of: fromAmount) { _ in
                                        updateToAmount()
                                    }
                                
                                AppPicker("From Token", selection: $fromToken, options: [
                                    ("WMATIC", "WMATIC"),
                                    ("USDC", "USDC")
                                ])
                                .onChange(of: fromToken) { _ in
                                    updateToAmount()
                                }
                            }
                            
                            // USD value display 💰
                            if let calculation = currentSwapCalculation, !fromAmount.isEmpty {
                                HStack {
                                    Text("~\(calculation.formattedFromValue) USD")
                                        .priceText(color: .secondaryText)
                                    Spacer()
                                }
                            }
                        }
                    }
                    
                    // Swap button
                    Button(action: swapTokens) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.25),
                                            Color.white.opacity(0.15),
                                            Color.white.opacity(0.1)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)
                            
                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // To section
                    InputCard(title: "To") {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                AppTextField("0.00", text: $toAmount, keyboardType: .decimalPad, isDisabled: true)
                                
                                AppPicker("To Token", selection: $toToken, options: [
                                    ("WMATIC", "WMATIC"),
                                    ("USDC", "USDC")
                                ])
                                .onChange(of: toToken) { _ in
                                    updateToAmount()
                                }
                            }
                            
                            // USD value and exchange rate 💰
                            if let calculation = currentSwapCalculation, !fromAmount.isEmpty {
                                VStack(spacing: 4) {
                                    HStack {
                                        Text("~\(calculation.formattedToValue) USD")
                                            .priceText(color: .secondaryText)
                                        Spacer()
                                    }
                                    HStack {
                                        Text(calculation.formattedRate)
                                            .captionText()
                                        Spacer()
                                    }
                                }
                            }
                        }
                    }
                }
                
                // Order details
                InfoCard(
                    title: "Order Details",
                    items: [
                        ("Order Type", "Limit Order", nil),
                        ("Router Version", "V6", nil),
                        ("Network", "Polygon", nil),
                        ("Expiry", "30 minutes", nil)
                    ]
                )
                
                // Create order button
                PrimaryButton("Create Limit Order", icon: "plus.circle") {
                    createLimitOrder()
                }
                .disabled(fromAmount.isEmpty || toAmount.isEmpty)
                .opacity(fromAmount.isEmpty || toAmount.isEmpty ? 0.6 : 1.0)
            }
                .padding()
            }
        }
        .navigationTitle("Trade")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .sheet(isPresented: $showingChart) {
            ChartView(currencyPair: "\(fromToken)/\(toToken)")
        }
        .onAppear {
            Task {
                await priceService.fetchPrices()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var currentSwapCalculation: SwapCalculation? {
        guard let amount = Double(fromAmount), amount > 0 else { return nil }
        return priceService.calculateSwap(
            fromAmount: amount,
            fromToken: fromToken,
            toToken: toToken
        )
    }
    
    private func swapTokens() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let tempToken = fromToken
            fromToken = toToken
            toToken = tempToken
            
            // Keep the from amount, recalculate to amount
            updateToAmount()
        }
    }
    
    private func updateToAmount() {
        if let calculation = currentSwapCalculation {
            toAmount = String(format: "%.6f", calculation.toAmount)
        } else {
            toAmount = ""
        }
    }
    
    private func createLimitOrder() {
        // TODO: Integrate with 1inch Router V6 SDK
        if let calculation = currentSwapCalculation {
            print("Creating limit order:")
            print("  From: \(calculation.fromAmount) \(calculation.fromToken) (~\(calculation.formattedFromValue))")
            print("  To: \(calculation.toAmount) \(calculation.toToken) (~\(calculation.formattedToValue))")
            print("  Rate: \(calculation.formattedRate)")
        } else {
            print("Creating limit order: \(fromAmount) \(fromToken) -> \(toAmount) \(toToken)")
        }
    }
}

// OrderDetailRow replaced by InfoRow in design system

#Preview {
    TradeView()
}