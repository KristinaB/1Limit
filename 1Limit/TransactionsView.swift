//
//  TransactionsView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct TransactionsView: View {
    @State private var selectedFilter = "All"
    private let filters = ["All", "Pending", "Filled", "Cancelled"]
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Filter picker with dark styling
                AppCard {
                    VStack(spacing: 12) {
                        Text("Filter Transactions")
                            .cardTitle()
                        
                        HStack(spacing: 8) {
                            ForEach(filters, id: \.self) { filter in
                                SmallButton(filter, style: selectedFilter == filter ? .primary : .secondary) {
                                    selectedFilter = filter
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal)
                
                // Transactions list
                if mockTransactions.isEmpty {
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
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
    }
    
    private var filteredTransactions: [MockTransaction] {
        if selectedFilter == "All" {
            return mockTransactions
        }
        return mockTransactions.filter { $0.status.rawValue == selectedFilter }
    }
}

struct TransactionRow: View {
    let transaction: MockTransaction
    
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
                
                Text("\(transaction.fromAmount) \(transaction.fromToken) → \(transaction.toAmount) \(transaction.toToken)")
                    .secondaryText()
                
                HStack {
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .captionText()
                    
                    Spacer()
                    
                    if transaction.txHash != nil {
                        SmallButton("View", style: .primary) {
                            // TODO: Open transaction in explorer
                        }
                    }
                }
            }
        }
    }
    
    private func statusType(for status: TransactionStatus) -> StatusType {
        switch status {
        case .pending:
            return .pending
        case .filled:
            return .success
        case .cancelled:
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
                
                Text("Your limit orders will appear here once created.\nStart trading to see your transaction history.")
                    .secondaryText()
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Mock Data

struct MockTransaction: Identifiable {
    let id = UUID()
    let type: String
    let fromAmount: String
    let fromToken: String
    let toAmount: String
    let toToken: String
    let status: TransactionStatus
    let date: Date
    let txHash: String?
}

enum TransactionStatus: String {
    case pending = "Pending"
    case filled = "Filled"
    case cancelled = "Cancelled"
}

private let mockTransactions: [MockTransaction] = [
    // Empty for now - will be populated when orders are created
]

#Preview {
    TransactionsView()
}