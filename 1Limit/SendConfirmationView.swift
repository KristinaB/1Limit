//
//  SendConfirmationView.swift
//  1Limit
//
//  Confirmation screen for sending funds
//

import SwiftUI

struct SendConfirmationView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var transferService = TokenTransferService()
    @State private var gasEstimate: String?
    @State private var gasCostUSD: String?
    @State private var isEstimatingGas = true
    @State private var isExecuting = false
    @State private var showingSuccess = false
    @State private var errorMessage: String?
    
    let sendTransaction: SendTransaction
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        headerSection
                        transactionDetailsSection
                        gasEstimationSection
                        erc20WarningSection
                        errorSection
                        actionButtonsSection
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Confirm Send")
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
                await estimateGasFees()
            }
        }
        .alert("Send Successful", isPresented: $showingSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("Your transaction has been submitted to the blockchain.")
        }
    }
    
    // MARK: - View Sections
    
    private var headerSection: some View {
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
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36, weight: .medium))
                        .foregroundColor(.white)
                }
                
                Text("Confirm Send")
                    .appTitle()
                
                Text("Please review the transaction details")
                    .secondaryText()
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var transactionDetailsSection: some View {
        InfoCard(
            title: "Transaction Details",
            items: [
                ("Token", sendTransaction.token.displayName, nil),
                ("Amount", "\(sendTransaction.amount) \(sendTransaction.token.symbol)", nil),
                ("From", formatAddress(sendTransaction.fromAddress), nil),
                ("To", formatAddress(sendTransaction.toAddress), nil),
                ("Network", "Polygon", nil),
            ]
        )
    }
    
    private var gasEstimationSection: some View {
        AppCard {
            VStack(spacing: 16) {
                Text("Network Fees")
                    .cardTitle()
                
                if isEstimatingGas {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Estimating gas fees...")
                            .secondaryText()
                    }
                } else if let gasEst = gasEstimate {
                    gasEstimateContent(gasEst)
                } else {
                    Text("Could not estimate gas fees")
                        .secondaryText()
                        .foregroundColor(.warningOrange)
                }
            }
        }
    }
    
    private func gasEstimateContent(_ gasEst: String) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("Gas Fee")
                    .secondaryText()
                Spacer()
                Text("\(gasEst) MATIC")
                    .bodyText()
            }
            
            if let gasCostUSD = gasCostUSD {
                HStack {
                    Text("Gas Fee USD")
                        .secondaryText()
                    Spacer()
                    Text(gasCostUSD)
                        .captionText()
                        .foregroundColor(.tertiaryText)
                }
            }
            
            if sendTransaction.token.isNative,
               let totalCost = sendTransaction.totalCostFormatted {
                Divider()
                    .background(Color.borderGray.opacity(0.3))
                
                HStack {
                    Text("Total Cost")
                        .bodyText()
                        .fontWeight(.semibold)
                    Spacer()
                    Text(totalCost)
                        .bodyText()
                        .fontWeight(.semibold)
                }
            }
        }
    }
    
    @ViewBuilder
    private var erc20WarningSection: some View {
        if !sendTransaction.token.isNative {
            AppCard {
                HStack {
                    Image(systemName: "info.circle.fill")
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("ERC-20 Token Transfer")
                            .bodyText()
                            .fontWeight(.semibold)
                        Text("Gas fees will be paid in MATIC, but you're transferring \(sendTransaction.token.symbol)")
                            .captionText()
                            .foregroundColor(.tertiaryText)
                    }
                    Spacer()
                }
            }
        }
    }
    
    @ViewBuilder
    private var errorSection: some View {
        if let error = errorMessage {
            AppCard {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.warningOrange)
                    Text(error)
                        .secondaryText()
                        .foregroundColor(.warningOrange)
                    Spacer()
                }
            }
        }
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            if isExecuting {
                SecondaryButton("Sending...", icon: "hourglass") {
                    // Disabled while executing
                }
                .disabled(true)
                .opacity(0.6)
            } else {
                PrimaryButton("Send Now", icon: "arrow.up.circle") {
                    Task {
                        await executeSend()
                    }
                }
                .disabled(isEstimatingGas || gasEstimate == nil)
            }
            
            SecondaryButton("Cancel") {
                dismiss()
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func formatAddress(_ address: String) -> String {
        guard address.count >= 10 else { return address }
        let start = String(address.prefix(6))
        let end = String(address.suffix(4))
        return "\(start)...\(end)"
    }
    
    private func estimateGasFees() async {
        isEstimatingGas = true
        errorMessage = nil
        
        do {
            let result = try await transferService.estimateGas(for: sendTransaction)
            await MainActor.run {
                gasEstimate = result.gasEstimate
                gasCostUSD = result.gasCostUSD
                isEstimatingGas = false
            }
        } catch {
            await MainActor.run {
                errorMessage = "Failed to estimate gas: \(error.localizedDescription)"
                isEstimatingGas = false
            }
        }
    }
    
    private func executeSend() async {
        isExecuting = true
        errorMessage = nil
        
        do {
            let updatedTransaction = SendTransaction(
                fromAddress: sendTransaction.fromAddress,
                toAddress: sendTransaction.toAddress,
                token: sendTransaction.token,
                amount: sendTransaction.amount,
                amountWei: sendTransaction.amountWei,
                gasEstimate: gasEstimate,
                gasCostUSD: gasCostUSD
            )
            
            let success = try await transferService.executeSend(updatedTransaction)
            
            await MainActor.run {
                isExecuting = false
                if success {
                    showingSuccess = true
                } else {
                    errorMessage = "Transaction failed. Please try again."
                }
            }
        } catch {
            await MainActor.run {
                isExecuting = false
                errorMessage = "Send failed: \(error.localizedDescription)"
            }
        }
    }
}

#Preview {
    SendConfirmationView(
        sendTransaction: SendTransaction(
            fromAddress: "0x742d35cc6635c0532925a3b8d0f8dff47e2b4c16",
            toAddress: "0x1234567890123456789012345678901234567890",
            token: TransferableToken.matic(
                balance: "1.0",
                balanceFormatted: "1.00",
                usdValue: "$0.85"
            ),
            amount: "0.1",
            amountWei: "100000000000000000",
            gasEstimate: nil,
            gasCostUSD: nil
        )
    )
}