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
        ScrollView {
            VStack(spacing: 24) {
                // Header with chart button 📈
                VStack(spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.left.arrow.right")
                            .font(.system(size: 40))
                            .foregroundColor(.blue)
                        
                        Spacer()
                        
                        Button(action: { showingChart = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                Text("Chart")
                            }
                            .font(.subheadline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.purple)
                            .cornerRadius(8)
                        }
                    }
                    
                    Text("Create Limit Order")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Currency pair with prices 🎀
                    VStack(spacing: 4) {
                        Text("\(fromToken)/\(toToken)")
                            .font(.caption)
                            .fontWeight(.medium)
                        
                        if priceService.isLoading {
                            HStack(spacing: 4) {
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Loading prices...")
                                    .font(.caption2)
                            }
                            .foregroundColor(.secondary)
                        } else {
                            HStack(spacing: 8) {
                                if let fromPrice = priceService.getPrice(for: fromToken) {
                                    Text("\(fromToken): \(fromPrice.formattedPrice)")
                                }
                                Text("•")
                                if let toPrice = priceService.getPrice(for: toToken) {
                                    Text("\(toToken): \(toPrice.formattedPrice)")
                                }
                            }
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
                
                // Trading form
                VStack(spacing: 16) {
                    // From section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                TextField("0.00", text: $fromAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .onChange(of: fromAmount) { _ in
                                        updateToAmount()
                                    }
                                
                                Picker("From Token", selection: $fromToken) {
                                    Text("WMATIC").tag("WMATIC")
                                    Text("USDC").tag("USDC")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 100)
                                .onChange(of: fromToken) { _ in
                                    updateToAmount()
                                }
                            }
                            
                            // USD value display 💰
                            if let calculation = currentSwapCalculation, !fromAmount.isEmpty {
                                Text("~\(calculation.formattedFromValue) USD")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Swap button
                    Button(action: swapTokens) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .padding(.vertical, 8)
                    
                    // To section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("To")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        VStack(spacing: 8) {
                            HStack {
                                TextField("0.00", text: $toAmount)
                                    .keyboardType(.decimalPad)
                                    .textFieldStyle(RoundedBorderTextFieldStyle())
                                    .disabled(true) // Auto-calculated
                                
                                Picker("To Token", selection: $toToken) {
                                    Text("WMATIC").tag("WMATIC")
                                    Text("USDC").tag("USDC")
                                }
                                .pickerStyle(MenuPickerStyle())
                                .frame(width: 100)
                                .onChange(of: toToken) { _ in
                                    updateToAmount()
                                }
                            }
                            
                            // USD value and exchange rate 💰
                            if let calculation = currentSwapCalculation, !fromAmount.isEmpty {
                                VStack(spacing: 2) {
                                    Text("~\(calculation.formattedToValue) USD")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Text(calculation.formattedRate)
                                        .font(.caption2)
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(16)
                
                // Order details
                VStack(alignment: .leading, spacing: 12) {
                    Text("Order Details")
                        .font(.headline)
                    
                    OrderDetailRow(title: "Order Type", value: "Limit Order")
                    OrderDetailRow(title: "Router Version", value: "V6")
                    OrderDetailRow(title: "Network", value: "Polygon")
                    OrderDetailRow(title: "Expiry", value: "30 minutes")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Create order button
                Button(action: createLimitOrder) {
                    Text("Create Limit Order")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .disabled(fromAmount.isEmpty || toAmount.isEmpty)
                .padding(.top, 20)
            }
            .padding()
        }
        .navigationTitle("Trade")
        .navigationBarTitleDisplayMode(.large)
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

struct OrderDetailRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    TradeView()
}