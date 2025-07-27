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
                        Text("Filter Transactions")
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
                                                .fill(selectedFilter == filter ? 
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.3),
                                                            Color.white.opacity(0.15)
                                                        ],
                                                        startPoint: .top,
                                                        endPoint: .bottom
                                                    ) :
                                                    LinearGradient(
                                                        colors: [
                                                            Color.white.opacity(0.05),
                                                            Color.clear
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
    let transaction: Transaction
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
                                        
                                        Image(systemName: transaction.status == .confirmed ? "checkmark" : "clock")
                                            .font(.system(size: 24, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    Spacer()
                                    
                                    Text(transaction.status.rawValue)
                                        .statusText(status: statusType(for: transaction.status))
                                }
                                
                                Text(transaction.type)
                                    .appTitle()
                                
                                Text("\(transaction.fromAmount) \(transaction.fromToken) → \(transaction.toAmount) \(transaction.toToken)")
                                    .secondaryText()
                                    .multilineTextAlignment(.center)
                            }
                        }
                        
                        // Transaction details
                        InfoCard(
                            title: "Transaction Details",
                            items: [
                                ("From Amount", "\(transaction.fromAmount) \(transaction.fromToken)", nil),
                                ("To Amount", "\(transaction.toAmount) \(transaction.toToken)", nil),
                                ("Limit Price", transaction.limitPrice, nil),
                                ("Date", transaction.date.formatted(date: .abbreviated, time: .complete), nil),
                                ("Status", transaction.status.rawValue, nil)
                            ] + blockchainDetailsItems()
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
    
    /// Get blockchain-specific details for display
    private func blockchainDetailsItems() -> [(String, String, Color?)] {
        var items: [(String, String, Color?)] = []
        
        if let blockNumber = transaction.blockNumber {
            items.append(("Block Number", blockNumber, nil))
        }
        
        if let gasUsed = transaction.gasUsed {
            items.append(("Gas Used", gasUsed, nil))
        }
        
        if let gasPrice = transaction.gasPrice {
            items.append(("Gas Price", "\(gasPrice) wei", nil))
        }
        
        if let lastPolled = transaction.lastPolledAt {
            items.append(("Last Updated", lastPolled.formatted(date: .abbreviated, time: .shortened), nil))
        }
        
        return items
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

#Preview {
    TransactionsView()
}