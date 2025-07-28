//
//  TransactionsView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct TransactionsView: View {
  @StateObject private var transactionManager = TransactionManagerFactory.createProduction()
  @EnvironmentObject private var widgetSyncService: WidgetSyncService
  @State private var selectedFilter = "All"
  private let filters = ["All", "Pending", "Confirmed", "Failed"]

  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea()

      VStack(spacing: 20) {
        // Filter picker with dark styling
        AppCard {
          VStack(spacing: 12) {
            Text("Transaction History")
              .cardTitle()

            HStack(spacing: 2) {
              ForEach(filters, id: \.self) { filter in
                Button(action: {
                  selectedFilter = filter
                }) {
                  Text(filter)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(selectedFilter == filter ? .primaryText : .secondaryText)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 6)
                    .background(
                      Capsule()
                        .fill(
                          selectedFilter == filter
                            ? LinearGradient(
                              colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.15),
                              ],
                              startPoint: .top,
                              endPoint: .bottom
                            )
                            : LinearGradient(
                              colors: [
                                Color.white.opacity(0.05),
                                Color.clear,
                              ],
                              startPoint: .top,
                              endPoint: .bottom
                            )
                        )
                        .overlay(
                          Capsule()
                            .strokeBorder(
                              Color.borderGray.opacity(0.3),
                              lineWidth: 1
                            )
                        )
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
              }
            }
          }
        }
        .padding(.horizontal)

        // Transactions list
        if transactionManager.isLoading {
          Spacer()
          ProgressView("Loading transactions...")
            .foregroundColor(.secondaryText)
          Spacer()
        } else if filteredTransactions.isEmpty {
          Spacer()
          EmptyTransactionsView()
          Spacer()
        } else {
          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(filteredTransactions) { transaction in
                TransactionRow(transaction: transaction)
                  .padding(.horizontal)
              }
            }
            .padding(.vertical)
          }
        }

        // Error message
        if let errorMessage = transactionManager.errorMessage {
          Text(errorMessage)
            .foregroundColor(.red)
            .padding()
        }
      }
    }
    .navigationTitle("Transactions")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(Color.appBackground, for: .navigationBar)
    .refreshable {
      await transactionManager.refreshTransactions()
      widgetSyncService.syncToWidget()
    }
    .toolbar {
      ToolbarItem(placement: .navigationBarTrailing) {
        Button("Refresh") {
          Task {
            await transactionManager.refreshTransactions()
            widgetSyncService.syncToWidget()
          }
        }
      }
    }
  }

  private var filteredTransactions: [Transaction] {
    return transactionManager.getFilteredTransactions(by: selectedFilter)
  }
}

struct TransactionRow: View {
  let transaction: Transaction
  @State private var showingDetails = false

  var body: some View {
    ListItemCard {
      VStack(alignment: .leading, spacing: 12) {
        HStack {
          Text(transaction.type)
            .cardTitle()

          Spacer()

          Text(transaction.status.rawValue)
            .statusText(status: statusType(for: transaction.status))
        }

        VStack(alignment: .leading, spacing: 4) {
          Text(
            "\(transaction.fromAmount) \(transaction.fromToken) → \(transaction.toAmount) \(transaction.toToken)"
          )
          .secondaryText()

          if let fromUSD = transaction.formattedFromAmountUSD,
            let toUSD = transaction.formattedToAmountUSD
          {
            Text("\(fromUSD) → \(toUSD)")
              .captionText()
              .foregroundColor(.green)
          }
        }

        HStack {
          Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
            .captionText()

          Spacer()

          if transaction.txHash != nil {
            SmallButton("View", style: .primary) {
              showingDetails = true
            }
          }

          // Show polling indicator for pending transactions
          if transaction.status == .pending && transaction.needsPolling {
            ProgressView()
              .scaleEffect(0.7)
          }
        }
      }
    }
    .sheet(isPresented: $showingDetails) {
      TransactionDetailView(transaction: transaction)
    }
  }

  private func statusType(for status: TransactionStatus) -> StatusType {
    switch status {
    case .pending:
      return .pending
    case .confirmed:
      return .success
    case .failed, .cancelled:
      return .error
    }
  }
}

struct EmptyTransactionsView: View {
  var body: some View {
    AppCard {
      VStack(spacing: 20) {
        Image(systemName: "list.bullet.rectangle")
          .font(.system(size: 60))
          .foregroundColor(.secondaryText)

        Text("No Transactions Yet")
          .sectionTitle()

        Text(
          "Your limit orders will appear here once created.\nStart trading to see your transaction history."
        )
        .secondaryText()
        .multilineTextAlignment(.center)
        .lineSpacing(4)
      }
    }
    .padding(.horizontal)
  }
}

struct TransactionDetailView: View {
  let transaction: Transaction
  @Environment(\.dismiss) private var dismiss
  @State private var isMoreDetailsExpanded = false

  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()

        ScrollView {
          VStack(spacing: 24) {
            // Status header
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

                    Image(systemName: transaction.status == .confirmed ? "checkmark" : "clock")
                      .font(.system(size: 24, weight: .medium))
                      .foregroundColor(.white)
                  }

                  Spacer()

                  Text(transaction.status.rawValue)
                    .statusText(status: statusType(for: transaction.status))
                }

                // old text - to be removed
                // Text(transaction.type)
                //   .appTitle()

                Text("Transaction")

                Text(
                  "\(transaction.fromAmount) \(transaction.fromToken) → \(transaction.toAmount) \(transaction.toToken)"
                )
                .secondaryText()
                .multilineTextAlignment(.center)
              }
            }

            // Transaction details
            InfoCard(
              title: "Transaction Details",
              items: [
                ("From Amount", "\(transaction.fromAmount) \(transaction.fromToken)", nil),
                ("From Value USD", transaction.formattedFromAmountUSD ?? "Calculating...", nil),
                ("To Amount", "\(transaction.toAmount) \(transaction.toToken)", nil),
                ("To Value USD", transaction.formattedToAmountUSD ?? "Calculating...", nil),
                ("Limit Price", transaction.limitPrice, nil),
                ("Limit Price USD", transaction.formattedLimitPriceUSD ?? "Calculating...", nil),
                ("Date", formatDate(transaction.date), nil),
                ("Status", transaction.status.rawValue, nil),
              ]
            )

            // Transaction ID and explorer link
            if let txHash = transaction.txHash {
              AppCard {
                VStack(spacing: 16) {
                  Text("Blockchain Details")
                    .cardTitle()

                  VStack(spacing: 12) {
                    HStack {
                      Text("Transaction ID")
                        .secondaryText()
                      Spacer()
                    }

                    Text(txHash)
                      .font(.system(.body, design: .monospaced))
                      .foregroundColor(.primaryText)
                      .padding(12)
                      .frame(maxWidth: .infinity)
                      .background(
                        RoundedRectangle(cornerRadius: 8)
                          .fill(Color.inputBackground)
                      )

                    PrimaryButton("View on PolygonScan", icon: "safari") {
                      if let url = URL(string: "https://polygonscan.com/tx/\(txHash)") {
                        UIApplication.shared.open(url)
                      }
                    }
                  }
                }
              }
            }

            // More Details Accordion
            if hasMoreDetails() {
              AppCard {
                VStack(spacing: 0) {
                  Button(action: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                      isMoreDetailsExpanded.toggle()
                    }
                  }) {
                    HStack {
                      Text("More Details")
                        .cardTitle()

                      Spacer()

                      Image(systemName: isMoreDetailsExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondaryText)
                    }
                    .padding(.vertical, 4)
                  }
                  .buttonStyle(PlainButtonStyle())

                  if isMoreDetailsExpanded {
                    VStack(spacing: 20) {
                      Divider()
                        .background(Color.borderGray.opacity(0.3))
                        .padding(.vertical, 8)

                      VStack(spacing: 16) {
                        if let blockNumber = transaction.blockNumber {
                          DetailRow(label: "Block Number", value: blockNumber)
                        }

                        if let gasUsed = transaction.gasUsed {
                          DetailRow(label: "Gas Used", value: gasUsed)
                        }

                        if let gasPrice = transaction.gasPrice {
                          DetailRow(label: "Gas Price", value: formatGasPrice(gasPrice))
                        }

                        if let gasFeeUSD = transaction.formattedGasFeeUSD {
                          DetailRow(label: "Gas Fee USD", value: gasFeeUSD)
                        }

                        if let totalCostUSD = transaction.formattedTotalCostUSD {
                          VStack(alignment: .leading, spacing: 4) {
                            DetailRow(
                              label: "Total Cost USD", value: totalCostUSD, valueColor: .orange)
                            Text("Total cost includes the amount sent plus gas fees")
                              .captionText()
                              .foregroundColor(.secondaryText)
                          }
                        }

                        if let lastPolled = transaction.lastPolledAt {
                          DetailRow(label: "Last Updated", value: formatDate(lastPolled))
                        }
                      }
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                  }
                }
              }
            }

            Spacer(minLength: 40)
          }
          .padding()
        }
      }
      .navigationTitle("Transaction")
      .navigationBarTitleDisplayMode(.inline)
      .toolbarBackground(Color.appBackground, for: .navigationBar)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          SmallButton("Done", style: .secondary) {
            dismiss()
          }
        }
      }
    }
    .preferredColorScheme(.dark)
  }

  /// Check if there are more details to display
  private func hasMoreDetails() -> Bool {
    return transaction.blockNumber != nil || transaction.gasUsed != nil
      || transaction.gasPrice != nil || transaction.gasFeeUSD != nil
      || transaction.totalCostUSD != nil || transaction.lastPolledAt != nil
  }

  /// Format date without seconds and timezone
  private func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: date)
  }

  /// Convert gas price from wei to gwei
  private func formatGasPrice(_ weiString: String) -> String {
    guard let weiValue = Double(weiString) else {
      return "\(weiString) wei"
    }
    let gweiValue = weiValue / 1_000_000_000
    return String(format: "%.2f gwei", gweiValue)
  }

  private func statusType(for status: TransactionStatus) -> StatusType {
    switch status {
    case .pending:
      return .pending
    case .confirmed:
      return .success
    case .failed, .cancelled:
      return .error
    }
  }
}

struct DetailRow: View {
  let label: String
  let value: String
  var valueColor: Color = .primaryText

  var body: some View {
    HStack {
      Text(label)
        .secondaryText()

      Spacer()

      Text(value)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(valueColor)
    }
  }
}

#Preview {
  TransactionsView()
}
