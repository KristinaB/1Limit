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
                    
                    // Currency pair display 🎀
                    Text("\(fromToken)/\(toToken)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color(.systemGray6))
                        .cornerRadius(6)
                }
                
                // Trading form
                VStack(spacing: 16) {
                    // From section
                    VStack(alignment: .leading, spacing: 8) {
                        Text("From")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        HStack {
                            TextField("0.00", text: $fromAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("From Token", selection: $fromToken) {
                                Text("WMATIC").tag("WMATIC")
                                Text("USDC").tag("USDC")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 100)
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
                        
                        HStack {
                            TextField("0.00", text: $toAmount)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Picker("To Token", selection: $toToken) {
                                Text("WMATIC").tag("WMATIC")
                                Text("USDC").tag("USDC")
                            }
                            .pickerStyle(MenuPickerStyle())
                            .frame(width: 100)
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
    }
    
    private func swapTokens() {
        withAnimation(.easeInOut(duration: 0.3)) {
            let tempToken = fromToken
            fromToken = toToken
            toToken = tempToken
            
            let tempAmount = fromAmount
            fromAmount = toAmount
            toAmount = tempAmount
        }
    }
    
    private func createLimitOrder() {
        // TODO: Integrate with 1inch Router V6 SDK
        print("Creating limit order: \(fromAmount) \(fromToken) -> \(toAmount) \(toToken)")
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