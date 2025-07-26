//
//  TradeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct TradeView: View {
  @State private var fromAmount = ""
  @State private var limitPrice = ""
  @State private var fromToken = "WMATIC"
  @State private var toToken = "USDC"
  @State private var showingChart = false
  @State private var showOrderConfirmation = false
  @StateObject private var priceService = PriceService.shared

  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 24) {
          headerView
          
          orderFormView
          
          orderPreviewView
          
          orderDetailsView
          
          createOrderButton
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
    .sheet(isPresented: $showOrderConfirmation) {
      OrderConfirmationView(
        fromAmount: fromAmount,
        fromToken: fromToken,
        toToken: toToken,
        limitPrice: limitPrice,
        receiveAmount: calculatedReceiveAmount
      )
    }
    .onAppear {
      Task {
        await priceService.fetchPrices()
      }
    }
  }

  // MARK: - Computed Properties
  
  private var calculatedReceiveAmount: String {
    guard let amount = Double(fromAmount), let price = Double(limitPrice), amount > 0, price > 0 else { 
      return "0.00" 
    }
    let receiveAmount = amount / price
    return String(format: "%.6f", receiveAmount)
  }
  
  private var headerView: some View {
    AppCard {
      VStack(spacing: 16) {
        HStack {
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [
                    Color.white.opacity(0.25),
                    Color.white.opacity(0.15),
                    Color.white.opacity(0.1),
                  ],
                  startPoint: .top,
                  endPoint: .bottom
                )
              )
              .frame(width: 60, height: 60)
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

            Image(systemName: "arrow.left.arrow.right")
              .font(.system(size: 24, weight: .medium))
              .foregroundColor(.white)
          }

          Spacer()

          SmallButton("Chart", style: .primary) {
            showingChart = true
          }
        }

        Text("Create Limit Order")
          .sectionTitle()

        // Currency pair with prices
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
  }
  
  private var orderFormView: some View {
    VStack(spacing: 16) {
      // Currency selection with swap button
      VStack(spacing: 12) {
        // Spending currency
        InputCard(title: "Spending") {
          VStack(spacing: 12) {
            HStack(spacing: 12) {
              AppPicker(
                "From Token", selection: $fromToken,
                options: [
                  ("WMATIC", "WMATIC"),
                  ("USDC", "USDC"),
                ]
              )
            }
            
            // USD price display
            if let fromPrice = priceService.getPrice(for: fromToken) {
              HStack {
                Text("\(fromToken): \(fromPrice.formattedPrice)")
                  .captionText()
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
                    Color.white.opacity(0.1),
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
        
        // Buying currency
        InputCard(title: "Buying") {
          VStack(spacing: 12) {
            HStack(spacing: 12) {
              AppPicker(
                "To Token", selection: $toToken,
                options: [
                  ("WMATIC", "WMATIC"),
                  ("USDC", "USDC"),
                ]
              )
            }
            
            // USD price display
            if let toPrice = priceService.getPrice(for: toToken) {
              HStack {
                Text("\(toToken): \(toPrice.formattedPrice)")
                  .captionText()
                Spacer()
              }
            }
          }
        }
      }
      
      // Amount input
      InputCard(title: "Amount") {
        VStack(spacing: 12) {
          AppTextField("0.00", text: $fromAmount, keyboardType: .decimalPad)
            .onChange(of: fromAmount) {
              updatePreview()
            }
          
          // USD value display
          if let fromPrice = priceService.getPrice(for: fromToken), 
             let amount = Double(fromAmount), amount > 0 {
            HStack {
              Text("~\(String(format: "%.2f", fromPrice.usdPrice * amount)) USD")
                .priceText(color: .secondaryText)
              Spacer()
            }
          }
        }
      }
      
      // Limit price input
      InputCard(title: "Limit Price") {
        VStack(spacing: 12) {
          AppTextField("0.00", text: $limitPrice, keyboardType: .decimalPad)
            .onChange(of: limitPrice) {
              updatePreview()
            }
          
          Text("Price per \(toToken) in \(fromToken)")
            .captionText()
        }
      }
    }
  }
  
  @ViewBuilder
  private var orderPreviewView: some View {
    if !fromAmount.isEmpty && !limitPrice.isEmpty {
      AppCard {
        VStack(spacing: 12) {
          Text("Order Preview")
            .cardTitle()
          
          VStack(spacing: 8) {
            HStack {
              Text("You will spend")
                .secondaryText()
              Spacer()
              Text("\(fromAmount) \(fromToken)")
                .bodyText()
            }
            
            HStack {
              Text("You will receive")
                .secondaryText()
              Spacer()
              Text("\(calculatedReceiveAmount) \(toToken)")
                .bodyText()
            }
            
            HStack {
              Text("Limit price")
                .secondaryText()
              Spacer()
              Text("\(limitPrice) \(fromToken)/\(toToken)")
                .bodyText()
            }
          }
        }
      }
    }
  }
  
  private var orderDetailsView: some View {
    InfoCard(
      title: "Order Details",
      items: [
        ("Order Type", "Limit Order", nil),
        ("Router Version", "V6", nil),
        ("Network", "Polygon", nil),
        ("Expiry", "30 minutes", nil)
      ]
    )
  }
  
  private var createOrderButton: some View {
    PrimaryButton("Create Limit Order", icon: "plus.circle") {
      showOrderConfirmation = true
    }
    .disabled(fromAmount.isEmpty || limitPrice.isEmpty)
    .opacity(fromAmount.isEmpty || limitPrice.isEmpty ? 0.6 : 1.0)
  }

  private func swapTokens() {
    withAnimation(.easeInOut(duration: 0.3)) {
      let tempToken = fromToken
      fromToken = toToken
      toToken = tempToken
    }
  }

  private func updatePreview() {
    // This method is called when amount or limit price changes
    // The calculated receive amount is automatically updated via the computed property
  }
}

struct OrderConfirmationView: View {
  @Environment(\.dismiss) private var dismiss
  let fromAmount: String
  let fromToken: String
  let toToken: String
  let limitPrice: String
  let receiveAmount: String
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()
        
        ScrollView {
          VStack(spacing: 24) {
            // Header
            AppCard {
              VStack(spacing: 16) {
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
                    .frame(width: 80, height: 80)
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
                  
                  Image(systemName: "exclamationmark.triangle")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                }
                
                Text("Confirm Your Order")
                  .appTitle()
                
                Text("Please review your order details carefully before submitting.")
                  .secondaryText()
                  .multilineTextAlignment(.center)
              }
            }
            
            // Order summary
            InfoCard(
              title: "Order Summary",
              items: [
                ("Spending", "\(fromAmount) \(fromToken)", nil),
                ("Receiving", "\(receiveAmount) \(toToken)", nil),
                ("Limit Price", "\(limitPrice) \(fromToken)/\(toToken)", nil),
                ("Order Type", "Limit Order", nil),
                ("Network", "Polygon", nil)
              ]
            )
            
            // Confirmation buttons
            VStack(spacing: 12) {
              PrimaryButton("Place Order") {
                // TODO: Implement order submission
                dismiss()
              }
              
              SecondaryButton("Cancel") {
                dismiss()
              }
            }
            
            Spacer(minLength: 40)
          }
          .padding()
        }
      }
      .navigationTitle("Confirm Order")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.appBackground, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          SmallButton("Cancel", style: .secondary) {
            dismiss()
          }
        }
      }
    }
    .preferredColorScheme(.dark)
  }
}

// OrderDetailRow replaced by InfoRow in design system

#Preview {
  TradeView()
}
