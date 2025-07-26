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
        VStack(spacing: 0) {
            // Filter picker
            Picker("Filter", selection: $selectedFilter) {
                ForEach(filters, id: \.self) { filter in
                    Text(filter).tag(filter)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding()
            
            // Transactions list
            if mockTransactions.isEmpty {
                ScrollView {
                    EmptyTransactionsView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            } else {
                List(filteredTransactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .navigationTitle("Transactions")
        .navigationBarTitleDisplayMode(.large)
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
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(transaction.type)
                            .font(.headline)
                        Spacer()
                        Text(transaction.status.rawValue)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(statusColor(for: transaction.status))
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    
                    Text("\(transaction.fromAmount) \(transaction.fromToken) → \(transaction.toAmount) \(transaction.toToken)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if transaction.txHash != nil {
                    Button("View") {
                        // TODO: Open transaction in explorer
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }
            }
        }
        .padding(.vertical, 4)
    }
    
    private func statusColor(for status: TransactionStatus) -> Color {
        switch status {
        case .pending:
            return .orange
        case .filled:
            return .green
        case .cancelled:
            return .red
        }
    }
}

struct EmptyTransactionsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.bullet")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Transactions Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Your limit orders will appear here once created")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
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