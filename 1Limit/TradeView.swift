//
//  TradeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct TradeView: View {
  @State private var fromAmount = "0.01"
  @State private var limitPrice = ""
  @State private var fromToken = "WMATIC"
  @State private var toToken = "USDC"
  @State private var showingChart = false
  @State private var showOrderConfirmation = false
  @StateObject private var priceService = PriceService.shared
  @StateObject private var walletLoader = WalletLoader.shared
  @State private var currentWallet: WalletData?

  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea()

      if currentWallet == nil {
        // No wallet state
        VStack(spacing: 24) {
          Spacer()
          
          AppCard {
            VStack(spacing: 20) {
              Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 50))
                .foregroundColor(.warningOrange)
              
              Text("Wallet Required")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
              
              Text("You need to create, import, or use a test wallet before you can start trading.")
                .secondaryText()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
              
              Text("Please go to the Home tab to set up your wallet.")
                .captionText()
                .foregroundColor(.tertiaryText)
                .multilineTextAlignment(.center)
            }
            .padding(.vertical, 8)
          }
          
          Spacer()
        }
        .padding()
      } else {
        // Normal trading interface
        ScrollView {
          VStack(spacing: 24) {
            headerView

            orderFormView

            orderPreviewView

            createOrderButton
          }
          .padding()
        }
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
        // Load wallet state
        currentWallet = await walletLoader.loadWallet()
        
        // Only fetch prices if wallet exists
        if currentWallet != nil {
          await priceService.fetchPrices()
          updateLimitPriceToMarket()
        }
      }
    }
    .onChange(of: walletLoader.currentWalletMode) {
      Task {
        // Update wallet when mode changes
        currentWallet = await walletLoader.loadWallet()
      }
    }
  }

  // MARK: - Computed Properties

  private var calculatedReceiveAmount: String {
    guard let amount = Double(fromAmount), let price = Double(limitPrice), amount > 0, price > 0
    else {
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
        InputCard(title: "From") {
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
          }
        }

        // Amount input
        InputCard(title: "Amount") {
          VStack(spacing: 12) {
            AppTextField("0.00", text: $fromAmount, keyboardType: .decimalPad)
              .onChange(of: fromAmount) {
                updatePreview()
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
        InputCard(title: "To") {
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
          }
        }
      }
    }
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

      // Clear limit price so it gets updated to new market rate
      limitPrice = ""
      updateLimitPriceToMarket()
    }
  }

  private func updatePreview() {
    // This method is called when amount or limit price changes
    // The calculated receive amount is automatically updated via the computed property
  }

  private func updateLimitPriceToMarket() {
    // Only set if limit price is empty to avoid overriding user input
    guard limitPrice.isEmpty else { return }

    if let fromPrice = priceService.getPrice(for: fromToken),
      let toPrice = priceService.getPrice(for: toToken)
    {

      // Calculate market rate (fromToken per toToken)
      let marketRate = fromPrice.usdPrice / toPrice.usdPrice

      // Round to 3 decimal places for USDC pairs
      if toToken == "USDC" || fromToken == "USDC" {
        limitPrice = String(format: "%.3f", marketRate)
      } else {
        limitPrice = String(format: "%.6f", marketRate)
      }
    }
  }
}

struct OrderConfirmationView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var widgetSyncService: WidgetSyncService
  @StateObject private var orderService = OrderPlacementService()
  @StateObject private var priceValidation = PriceValidationService()
  @State private var validationResult: PriceValidationResult?
  @State private var isValidatingPrice = true
  @State private var showingValidationWarning = false

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
                          Color.white.opacity(0.1),
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

            // Price validation warning
            if isValidatingPrice {
              AppCard {
                HStack(spacing: 12) {
                  ProgressView()
                    .scaleEffect(0.8)
                  Text("Validating price against market rates...")
                    .secondaryText()
                }
              }
            } else if let result = validationResult, let warning = result.warningMessage {
              AppCard {
                VStack(spacing: 16) {
                  HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .foregroundColor(.orange)
                      .font(.title2)
                    Text("Price Warning")
                      .cardTitle()
                      .foregroundColor(.orange)
                    Spacer()
                  }

                  Text(warning)
                    .secondaryText()
                    .multilineTextAlignment(.leading)

                  VStack(spacing: 8) {
                    HStack {
                      Text("Market Price:")
                        .captionText()
                      Spacer()
                      Text(String(format: "%.6f %@/%@", result.marketPrice, toToken, fromToken))
                        .captionText()
                        .fontWeight(.medium)
                    }

                    HStack {
                      Text("Your Price:")
                        .captionText()
                      Spacer()
                      Text(String(format: "%.6f %@/%@", result.userPrice, toToken, fromToken))
                        .captionText()
                        .fontWeight(.medium)
                    }

                    HStack {
                      Text("Recommended Range:")
                        .captionText()
                      Spacer()
                      Text(
                        String(
                          format: "%.6f - %.6f", result.recommendedRange.lowerBound,
                          result.recommendedRange.upperBound)
                      )
                      .captionText()
                      .fontWeight(.medium)
                    }
                  }
                  .padding(.top, 8)
                }
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
                ("Network", "Polygon", nil),
              ]
            )

            // Confirmation buttons
            VStack(spacing: 12) {
              if orderService.isExecuting {
                SecondaryButton("Placing Order...", icon: "hourglass") {
                  // Disabled while executing
                }
                .disabled(true)
                .opacity(0.6)
              } else if isValidatingPrice {
                SecondaryButton("Validating...", icon: "hourglass") {
                  // Disabled while validating
                }
                .disabled(true)
                .opacity(0.6)
              } else if let result = validationResult, !result.isValid {
                VStack(spacing: 12) {
                  SecondaryButton("⚠️ Place Order Anyway", icon: "exclamationmark.triangle") {
                    Task {
                      await placeOrder()
                    }
                  }
                  .foregroundColor(.orange)

                  PrimaryButton("Adjust Price") {
                    // Dismiss to go back and adjust price
                    dismiss()
                  }
                }
              } else {
                PrimaryButton("Place Order") {
                  Task {
                    await placeOrder()
                  }
                }
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
    .onAppear {
      Task {
        await validatePrice()
      }
    }
  }

  private func validatePrice() async {
    guard let price = Double(limitPrice), price > 0 else {
      isValidatingPrice = false
      validationResult = PriceValidationResult(
        isValid: false,
        marketPrice: 0,
        userPrice: 0,
        percentageDifference: 1.0,
        warningMessage: "Invalid limit price. Please enter a valid price.",
        recommendedRange: 0...0
      )
      return
    }

    isValidatingPrice = true

    let result = await priceValidation.validateLimitPrice(
      fromToken: fromToken,
      toToken: toToken,
      userPrice: price
    )

    validationResult = result
    isValidatingPrice = false
  }

  private func placeOrder() async {
    do {
      let result = try await orderService.placeOrder(
        fromAmount: fromAmount,
        fromToken: fromToken,
        toToken: toToken,
        limitPrice: limitPrice
      )

      if result.success {
        // Sync with widget after successful order placement
        widgetSyncService.syncAfterTransactionUpdate()

        // Order placed successfully - dismiss and redirect to transactions
        dismiss()
        // TODO: Navigate to transactions tab with pending filter
      }
    } catch {
      // TODO: Show error to user
      print("Order placement failed: \(error)")
    }
  }
}

// MARK: - Order Placement Service

@MainActor
class OrderPlacementService: ObservableObject {
  @Published var isExecuting = false
  @Published var lastResult: OrderPlacementResult?

  private let routerManager = RouterV6ManagerFactory.createProductionManager()

  func placeOrder(
    fromAmount: String,
    fromToken: String,
    toToken: String,
    limitPrice: String
  ) async throws -> OrderPlacementResult {
    isExecuting = true
    defer { isExecuting = false }

    // Execute dynamic order with real form values
    let success = await routerManager.executeDynamicOrder(
      fromAmount: fromAmount,
      fromToken: fromToken,
      toToken: toToken,
      limitPrice: limitPrice
    )

    let result = OrderPlacementResult(
      success: success,
      transactionHash: success ? "0x1234...abcd" : nil,
      error: success
        ? nil
        : NSError(
          domain: "OrderPlacement", code: 1,
          userInfo: [NSLocalizedDescriptionKey: "Order placement failed"])
    )

    lastResult = result
    return result
  }
}

struct OrderPlacementResult {
  let success: Bool
  let transactionHash: String?
  let error: Error?
}

// OrderDetailRow replaced by InfoRow in design system

#Preview {
  TradeView()
}
