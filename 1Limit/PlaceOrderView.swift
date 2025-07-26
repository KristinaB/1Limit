//
//  PlaceOrderView.swift
//  1Limit
//
//  Detailed order placement screen with price adjusters 📝💰
//

import SwiftUI

struct PlaceOrderView: View {
    @Environment(\.dismiss) private var dismiss
    let orderType: OrderType
    
    @State private var buyingCurrency = "Ethereum (ETH)"
    @State private var spendingCurrency = "USD Coin (USDC)"
    @State private var limitPrice = "1670.00"
    @State private var amount = "1.0"
    @State private var showOrderConfirmation = false
    
    // Mock available balance
    private let availableBalance = "2,450.00 USDC"
    
    var calculatedTotal: String {
        if let price = Double(limitPrice), let qty = Double(amount) {
            return String(format: "%.2f", price * qty)
        }
        return "0.00"
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Currency selection section
                        currencySelectionSection
                        
                        // Limit price section
                        limitPriceSection
                        
                        // Amount section
                        amountSection
                        
                        // Order summary
                        orderSummarySection
                        
                        // Confirm button
                        PrimaryButton("Confirm \(orderType.displayName) Order") {
                            showOrderConfirmation = true
                        }
                        .padding(.top, 20)
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("\(orderType.displayName) Order")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SmallButton("Cancel", style: .secondary) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showOrderConfirmation) {
            OrderConfirmationModal(
                orderType: orderType,
                amount: amount,
                price: limitPrice,
                pair: "\(buyingCurrency.split(separator: " ").last ?? "")/\(spendingCurrency.split(separator: " ").last ?? "")"
            )
        }
    }
    
    private var currencySelectionSection: some View {
        VStack(spacing: 16) {
            // Buying currency
            InputCard(title: orderType == .buy ? "Buying" : "Selling") {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.orange)
                                .frame(width: 32, height: 32)
                            Text("Ξ")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(buyingCurrency)
                            .bodyText()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondaryText)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            
            // Spending currency
            InputCard(title: orderType == .buy ? "Spending" : "Receiving") {
                HStack {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 32, height: 32)
                            Text("$")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        
                        Text(spendingCurrency)
                            .bodyText()
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondaryText)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.inputBackground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
                        )
                )
            }
        }
    }
    
    private var limitPriceSection: some View {
        InputCard(title: "Limit Price") {
            VStack(spacing: 16) {
                AppTextField("0.00", text: $limitPrice, keyboardType: .decimalPad)
                
                // Price adjusters
                HStack(spacing: 8) {
                    ForEach(["-5%", "-1%", "+1%", "+5%", "+20%"], id: \.self) { adjustment in
                        SmallButton(adjustment, style: .secondary) {
                            adjustPrice(adjustment)
                        }
                    }
                }
            }
        }
    }
    
    private var amountSection: some View {
        InputCard(title: "Amount") {
            AppTextField("0.00", text: $amount, keyboardType: .decimalPad)
        }
    }
    
    private var orderSummarySection: some View {
        AppCard {
            VStack(spacing: 12) {
                Text("Order Summary")
                    .cardTitle()
                
                VStack(spacing: 8) {
                    InfoRow(title: "Total Cost", value: "\(calculatedTotal) USDC")
                    InfoRow(title: "Available", value: availableBalance)
                }
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.inputBackground.opacity(0.5))
        )
    }
    
    private func adjustPrice(_ adjustment: String) {
        guard let currentPrice = Double(limitPrice) else { return }
        
        let percentage: Double
        switch adjustment {
        case "-5%": percentage = -0.05
        case "-1%": percentage = -0.01
        case "+1%": percentage = 0.01
        case "+5%": percentage = 0.05
        case "+20%": percentage = 0.20
        default: return
        }
        
        let newPrice = currentPrice * (1 + percentage)
        limitPrice = String(format: "%.2f", newPrice)
    }
}

struct OrderConfirmationModal: View {
    @Environment(\.dismiss) private var dismiss
    let orderType: OrderType
    let amount: String
    let price: String
    let pair: String
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.5)
                .ignoresSafeArea()
            
            AppCard {
                VStack(spacing: 24) {
                    // Success icon
                    ZStack {
                        Circle()
                            .fill(Color.successGreen)
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 30, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    Text("Order Placed!")
                        .sectionTitle()
                    
                    Text("Your \(orderType.rawValue) order for \(amount) \(pair.split(separator: "/").first ?? "") at $\(price) has been placed successfully.")
                        .secondaryText()
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                    
                    PrimaryButton("Close") {
                        dismiss()
                    }
                }
            }
            .padding(40)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    PlaceOrderView(orderType: .buy)
}