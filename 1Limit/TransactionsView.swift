//
//  TransactionsView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct TransactionsView: View {
    @State private var selectedFilter = "All"
    private let filters = ["All", "Pending", "Filled"]
    
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
                
                Text("\(transaction.fromAmount) \(transaction.fromToken) → \(transaction.toAmount) \(transaction.toToken)")
                    .secondaryText()
                
                HStack {
                    Text(transaction.date.formatted(date: .abbreviated, time: .shortened))
                        .captionText()
                    
                    Spacer()
                    
                    if transaction.txHash != nil {
                        SmallButton("View", style: .primary) {
                            showingDetails = true
                        }
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

struct TransactionDetailView: View {
    let transaction: MockTransaction
    @Environment(\.dismiss) private var dismiss
    
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
                                                        Color.white.opacity(0.1)
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
                                        
                                        Image(systemName: transaction.status == .filled ? "checkmark" : "clock")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(transaction.status.rawValue)
                                        .statusText(status: statusType(for: transaction.status))
                                }
                                
                                Text(transaction.type)
                                    .appTitle()
                                
                                Text("\\(transaction.fromAmount) \\(transaction.fromToken) → \\(transaction.toAmount) \\(transaction.toToken)")
                                    .secondaryText()
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Transaction details
                        InfoCard(
                            title: "Transaction Details",
                            items: [
                                ("From Amount", "\\(transaction.fromAmount) \\(transaction.fromToken)", nil),
                                ("To Amount", "\\(transaction.toAmount) \\(transaction.toToken)", nil),
                                ("Date", transaction.date.formatted(date: .abbreviated, time: .complete), nil),
                                ("Status", transaction.status.rawValue, nil)
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
                                            if let url = URL(string: "https://polygonscan.com/tx/\\(txHash)") {
                                                UIApplication.shared.open(url)
                                            }
                                        }
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
    MockTransaction(
        type: "Limit Order",
        fromAmount: "100.0",
        fromToken: "WMATIC",
        toAmount: "85.5",
        toToken: "USDC",
        status: .filled,
        date: Calendar.current.date(byAdding: .hour, value: -2, to: Date()) ?? Date(),
        txHash: "0x1234...abcd"
    ),
    MockTransaction(
        type: "Limit Order",
        fromAmount: "50.25",
        fromToken: "USDC",
        toAmount: "58.8",
        toToken: "WMATIC",
        status: .pending,
        date: Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date(),
        txHash: nil
    ),
    MockTransaction(
        type: "Limit Order",
        fromAmount: "200.0",
        fromToken: "WMATIC",
        toAmount: "170.2",
        toToken: "USDC",
        status: .filled,
        date: Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date(),
        txHash: "0x5678...efgh"
    ),
    MockTransaction(
        type: "Limit Order",
        fromAmount: "75.0",
        fromToken: "USDC",
        toAmount: "87.9",
        toToken: "WMATIC",
        status: .filled,
        date: Calendar.current.date(byAdding: .day, value: -2, to: Date()) ?? Date(),
        txHash: "0x9abc...ijkl"
    ),
    MockTransaction(
        type: "Limit Order",
        fromAmount: "25.5",
        fromToken: "WMATIC",
        toAmount: "21.7",
        toToken: "USDC",
        status: .pending,
        date: Calendar.current.date(byAdding: .minute, value: -15, to: Date()) ?? Date(),
        txHash: nil
    )
]

#Preview {
    TransactionsView()
}