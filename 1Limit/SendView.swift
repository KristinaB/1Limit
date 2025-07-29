//
//  SendView.swift
//  1Limit
//
//  Send funds screen with token selection and address input
//

import SwiftUI

struct SendView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var walletLoader = WalletLoader.shared
  @StateObject private var balanceService = WalletBalanceService.shared
  @StateObject private var addressValidator = AddressValidationService()

  // Form state
  @State private var toAddress = ""
  @State private var amount = ""
  @State private var selectedToken: TransferableToken?
  @State private var addressValidation: AddressValidationResult?

  // UI state
  @State private var showingTokenSelector = false
  @State private var showingConfirmation = false
  @State private var showingQRScanner = false
  @State private var isValidatingAddress = false

  // Available tokens
  @State private var availableTokens: [TransferableToken] = []

  let wallet: WalletData

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

                  Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 36, weight: .medium))
                    .foregroundColor(.white)
                }

                Text("Send Funds")
                  .appTitle()

                Text("Send MATIC or tokens to any address")
                  .secondaryText()
                  .multilineTextAlignment(.center)
              }
            }

            // Token selection
            InputCard(title: "Token") {
              VStack(spacing: 12) {
                Button(action: {
                  showingTokenSelector = true
                }) {
                  HStack {
                    if let token = selectedToken {
                      VStack(alignment: .leading, spacing: 4) {
                        Text(token.displayName)
                          .bodyText()
                        Text("Balance: \(token.balanceFormatted)")
                          .captionText()
                      }
                    } else {
                      Text("Select token to send")
                        .secondaryText()
                    }

                    Spacer()

                    Image(systemName: "chevron.down")
                      .font(.system(size: 14, weight: .medium))
                      .foregroundColor(.secondaryText)
                  }
                  .padding(.vertical, 4)
                }
                .buttonStyle(PlainButtonStyle())
              }
            }

            // Recipient address
            InputCard(title: "To Address") {
              VStack(spacing: 12) {
                HStack(spacing: 12) {
                  AppTextField("0x...", text: $toAddress, keyboardType: .default)
                    .onChange(of: toAddress) {
                      validateAddressDebounced()
                    }

                  SmallButton("Paste", style: .secondary) {
                    pasteFromClipboard()
                  }
                }

                // Address validation feedback
                if let validation = addressValidation {
                  HStack {
                    Image(
                      systemName: validation.isValid
                        ? "checkmark.circle.fill" : "exclamationmark.triangle.fill"
                    )
                    .foregroundColor(validation.isValid ? .successGreen : .warningOrange)

                    Text(
                      validation.isValid
                        ? "Valid address" : validation.errorMessage ?? "Invalid address"
                    )
                    .captionText()
                    .foregroundColor(validation.isValid ? .successGreen : .warningOrange)

                    Spacer()
                  }
                }
              }
            }

            // Amount input
            InputCard(title: "Amount") {
              VStack(spacing: 12) {
                AppTextField("0.00", text: $amount, keyboardType: .decimalPad)

                if let token = selectedToken {
                  HStack {
                    Text("Available: \(token.balanceFormatted) \(token.symbol)")
                      .captionText()

                    Spacer()

                    SmallButton("Max", style: .secondary) {
                      useMaxAmount()
                    }
                  }
                }
              }
            }

            // Send button
            PrimaryButton("Review Send", icon: "arrow.up.circle") {
              showingConfirmation = true
            }
            .disabled(!canProceedToConfirmation)
            .opacity(canProceedToConfirmation ? 1.0 : 0.6)

            Spacer(minLength: 40)
          }
          .padding()
        }
      }
      .navigationTitle("Send")
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
    .onAppear {
      loadAvailableTokens()
    }
    .sheet(isPresented: $showingTokenSelector) {
      TokenSelectorView(
        tokens: availableTokens,
        selectedToken: $selectedToken
      )
    }
    .sheet(isPresented: $showingConfirmation) {
      if let token = selectedToken,
        let validation = addressValidation,
        validation.isValid,
        let normalizedAddress = validation.normalizedAddress
      {
        SendConfirmationView(
          sendTransaction: SendTransaction(
            fromAddress: wallet.address,
            toAddress: normalizedAddress,
            token: token,
            amount: amount,
            amountWei: calculateAmountInWei(),
            gasEstimate: nil,  // Will be calculated in confirmation view
            gasCostUSD: nil
          )
        )
      }
    }
  }

  // MARK: - Helper Methods

  private var canProceedToConfirmation: Bool {
    guard let token = selectedToken,
      let validation = addressValidation,
      validation.isValid,
      !amount.isEmpty,
      let amountDouble = Double(amount),
      amountDouble > 0,
      let balanceDouble = Double(token.balance),
      amountDouble <= balanceDouble
    else {
      return false
    }
    return true
  }

  private func loadAvailableTokens() {
    guard let balance = balanceService.currentBalance else {
      // Load basic MATIC token
      availableTokens = [
        TransferableToken.matic(
          balance: "0",
          balanceFormatted: "0.00",
          usdValue: "$0.00"
        )
      ]
      selectedToken = availableTokens.first
      return
    }

    var tokens: [TransferableToken] = []

    // Find native MATIC from token balances
    let maticBalance = balance.tokenBalances.first { $0.symbol == "MATIC" }

    // Add native MATIC
    tokens.append(
      TransferableToken.matic(
        balance: maticBalance?.decimalBalance ?? "0",
        balanceFormatted: maticBalance?.formattedBalance ?? "0.00",
        usdValue: maticBalance?.formattedUsdValue ?? "$0.00"
      ))

    // Add ERC-20 tokens from balance
    for tokenBalance in balance.tokenBalances {
      let contractAddress: String
      switch tokenBalance.symbol {
      case "USDC":
        contractAddress = "0x3c499c542cEF5E3811e1192ce70d8cC03d5c3359"
      case "WMATIC":
        contractAddress = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"
      default:
        continue  // Skip unknown tokens
      }

      tokens.append(
        TransferableToken.erc20(
          symbol: tokenBalance.symbol,
          name: tokenBalance.symbol == "USDC" ? "USD Coin" : "Wrapped MATIC",
          contractAddress: contractAddress,
          decimals: tokenBalance.symbol == "USDC" ? 6 : 18,
          balance: tokenBalance.decimalBalance,
          balanceFormatted: tokenBalance.formattedBalance,
          usdValue: tokenBalance.formattedUsdValue
        ))
    }

    availableTokens = tokens
    selectedToken = tokens.first
  }

  private func validateAddressDebounced() {
    // Simple immediate validation for now
    // In production, you might want to debounce this
    isValidatingAddress = true

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      addressValidation = addressValidator.validateAddress(toAddress)
      isValidatingAddress = false
    }
  }

  private func pasteFromClipboard() {
    if let clipboardString = UIPasteboard.general.string {
      toAddress = clipboardString
      validateAddressDebounced()
    }
  }

  private func useMaxAmount() {
    guard let token = selectedToken else { return }

    if token.isNative {
      // For native MATIC, reserve some for gas
      if let balanceDouble = Double(token.balance) {
        let maxAmount = max(0, balanceDouble - 0.01)  // Reserve 0.01 MATIC for gas
        amount = String(format: "%.6f", maxAmount)
      }
    } else {
      // For ERC-20 tokens, can use full balance
      amount = token.balance
    }
  }

  private func calculateAmountInWei() -> String {
    guard let token = selectedToken,
      let amountDouble = Double(amount)
    else {
      return "0"
    }

    let multiplier = pow(10.0, Double(token.decimals))
    let amountInWei = amountDouble * multiplier
    return String(format: "%.0f", amountInWei)
  }
}

// MARK: - Token Selector View

struct TokenSelectorView: View {
  @Environment(\.dismiss) private var dismiss
  let tokens: [TransferableToken]
  @Binding var selectedToken: TransferableToken?

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

        ScrollView {
          LazyVStack(spacing: 12) {
            ForEach(tokens) { token in
              TokenRowView(
                token: token,
                isSelected: selectedToken?.id == token.id
              ) {
                selectedToken = token
                dismiss()
              }
            }
          }
          .padding()
        }
      }
      .navigationTitle("Select Token")
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

struct TokenRowView: View {
  let token: TransferableToken
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      AppCard {
        HStack(spacing: 16) {
          // Token icon
          ZStack {
            Circle()
              .fill(
                LinearGradient(
                  colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                  startPoint: .topLeading,
                  endPoint: .bottomTrailing
                )
              )
              .frame(width: 40, height: 40)

            Text(String(token.symbol.prefix(1)))
              .font(.headline)
              .fontWeight(.bold)
              .foregroundColor(.white)
          }

          // Token info
          VStack(alignment: .leading, spacing: 4) {
            Text(token.displayName)
              .bodyText()

            if let address = token.displayAddress {
              Text(address)
                .captionText()
                .foregroundColor(.tertiaryText)
            }
          }

          Spacer()

          // Balance
          VStack(alignment: .trailing, spacing: 4) {
            Text(token.balanceFormatted)
              .bodyText()

            if let usdValue = token.usdValue {
              Text(usdValue)
                .captionText()
                .foregroundColor(.tertiaryText)
            }
          }

          // Selection indicator
          if isSelected {
            Image(systemName: "checkmark.circle.fill")
              .foregroundColor(.successGreen)
              .font(.title2)
          }
        }
      }
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  SendView(
    wallet: WalletData(
      address: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
      privateKey: "test"
    ))
}
