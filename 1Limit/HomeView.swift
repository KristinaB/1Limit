//
//  HomeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct HomeView: View {
    @Binding var selectedTab: Int
    var onWalletStateChanged: ((Bool) -> Void)? = nil
    @State private var showingWalletCreation = false
    @State private var showingDebug = false
    @State private var showingReceiveFunds = false
    @State private var showingSendFunds = false
    @State private var showingImportWallet = false

    // Wallet management state
    @StateObject private var walletLoader = WalletLoader.shared
    @StateObject private var balanceService = WalletBalanceService.shared
    @State private var currentWallet: WalletData?
    @State private var isLoadingWallet = false

    // Computed properties for dynamic button
    private var walletButtonTitle: String {
        if currentWallet == nil {
            return "Test Wallet"
        }

        switch walletLoader.currentWalletMode {
        case .testWallet:
            return "App Wallet"
        case .generatedWallet:
            return "Test Wallet"
        case .mockWallet:
            return "Test Wallet"
        }
    }

    private var walletButtonIcon: String {
        if currentWallet == nil {
            return "doc.fill"
        }

        switch walletLoader.currentWalletMode {
        case .testWallet:
            return "person.crop.circle.fill"
        case .generatedWallet:
            return "doc.fill"
        case .mockWallet:
            return "doc.fill"
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // App branding
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
                                .frame(width: 100, height: 100)
                                .overlay(
                                    Circle()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    Color.primaryGradientStart,
                                                    Color.primaryGradientEnd,
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            lineWidth: 2
                                        )
                                )
                                .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                                .shadow(color: Color.black.opacity(0.3), radius: 2, x: 0, y: 1)

                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                        }

                        Text("1Limit")
                            .appTitle()

                        Text("Place Decentralized 1Inch Limit Orders")
                            .secondaryText()
                    }
                    .padding(.top, 20)

                    // Show different content based on wallet state
                    if currentWallet == nil {
                        // No wallet state
                        NoWalletView(
                            showingWalletCreation: $showingWalletCreation,
                            showingImportWallet: $showingImportWallet,
                            onTestWalletSelected: {
                                await loadTestWallet()
                            }
                        )
                    } else {
                        // Wallet exists - show balance and management options
                        WalletBalanceCard(
                            wallet: currentWallet!,
                            balanceSummary: balanceService.currentBalance,
                            isLoading: balanceService.isLoading
                        )

                        // Wallet management buttons
                        VStack(spacing: 16) {
                            HStack(spacing: 8) {
                                PrimaryButton("Add", icon: "plus.circle") {
                                    showingReceiveFunds = true
                                }

                                PrimaryButton("Send", icon: "arrow.up.circle") {
                                    showingSendFunds = true
                                }
                            }
                        }
                    }

                    // Help text
                    if currentWallet != nil {
                        Text("Use the Trade tab to create limit orders 🚀")
                            .captionText()
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    } else {
                        Text("Create or load a wallet to access trading features 🚀")
                            .captionText()
                            .multilineTextAlignment(.center)
                            .padding(.top, 20)
                    }

                    Spacer(minLength: 40)

                    // Debug button at bottom
                    SmallButton("Debug", style: .secondary) {
                        showingDebug = true
                    }
                    .padding(.bottom, 20)
                }
                .padding()
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .sheet(isPresented: $showingWalletCreation) {
            WalletSetupFlow(selectedTab: $selectedTab)
                .onDisappear {
                    Task {
                        await loadDefaultWallet()
                    }
                }
        }
        .sheet(isPresented: $showingDebug) {
            DebugView(onResetComplete: {
                Task {
                    // Reset wallet state to nil and notify parent
                    currentWallet = nil
                    onWalletStateChanged?(false)

                    // Reload wallet state
                    await loadDefaultWallet()
                }
            })
        }
        .sheet(isPresented: $showingReceiveFunds) {
            if let wallet = currentWallet {
                ReceiveFundsView(wallet: wallet)
            }
        }
        .sheet(isPresented: $showingSendFunds) {
            if let wallet = currentWallet {
                SendView(wallet: wallet)
            }
        }
        .sheet(isPresented: $showingImportWallet) {
            ImportWalletView(onComplete: {
                Task {
                    await loadDefaultWallet()
                }
            })
        }
        .onAppear {
            // Don't automatically load wallet on appear
            // Let user explicitly choose which wallet to use
            // This ensures proper "no wallet" initial state
        }
    }

    // MARK: - Wallet Management Methods

    private func loadDefaultWallet() async {
        isLoadingWallet = true

        // Check if generated wallet exists
        if await walletLoader.hasGeneratedWallet() {
            currentWallet = await walletLoader.switchWalletMode(to: .generatedWallet)

            if let wallet = currentWallet {
                await balanceService.fetchWalletBalance(for: wallet.address, forceRefresh: true)
                balanceService.startAutoRefresh(for: wallet.address)
            }
        } else {
            // No wallet - start with nil
            currentWallet = nil
        }

        // Notify parent about wallet state change
        onWalletStateChanged?(currentWallet != nil)

        isLoadingWallet = false
    }

    private func loadTestWallet() async {
        isLoadingWallet = true
        balanceService.stopAutoRefresh()

        currentWallet = await walletLoader.switchWalletMode(to: .testWallet)

        if let wallet = currentWallet {
            await balanceService.fetchWalletBalance(for: wallet.address, forceRefresh: true)
            balanceService.startAutoRefresh(for: wallet.address)
        }

        // Notify parent about wallet state change
        onWalletStateChanged?(currentWallet != nil)

        isLoadingWallet = false
    }
}

// MARK: - Wallet Balance Card

struct WalletBalanceCard: View {
    let wallet: WalletData
    let balanceSummary: WalletBalanceSummary?
    let isLoading: Bool

    private var maskedAddress: String {
        guard wallet.address.count >= 10 else { return wallet.address }
        let start = String(wallet.address.prefix(6))
        let end = String(wallet.address.suffix(4))
        return "\(start)...\(end)"
    }

    var body: some View {
        AppCard {
            VStack(spacing: 16) {
                // Header with wallet address
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Wallet")
                            .font(.caption)
                            .foregroundColor(.tertiaryText)

                        Text(maskedAddress)
                            .font(.system(.subheadline, design: .monospaced))
                            .foregroundColor(.primaryText)
                    }

                    Spacer()

                    // Wallet type indicator
                    Text(WalletLoader.shared.currentWalletMode == .testWallet ? "TEST" : "YOURS")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    WalletLoader.shared.currentWalletMode == .testWallet
                                        ? Color.warningOrange.opacity(0.2)
                                        : Color.successGreen.opacity(0.2))
                        )
                        .foregroundColor(
                            WalletLoader.shared.currentWalletMode == .testWallet
                                ? Color.warningOrange : Color.successGreen)
                }

                Divider()
                    .background(Color.borderGray.opacity(0.3))

                // Balance display
                if isLoading {
                    HStack {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading balance...")
                            .secondaryText()
                    }
                } else if let summary = balanceSummary {
                    VStack(spacing: 12) {
                        // Total balance
                        VStack(spacing: 4) {
                            Text("Total Balance")
                                .font(.caption)
                                .foregroundColor(.tertiaryText)

                            Text(summary.formattedTotalValue)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primaryText)
                        }

                        // Token balances
                        if !summary.tokenBalances.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(summary.tokenBalances, id: \.symbol) { tokenBalance in
                                    HStack {
                                        // Token symbol
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            Color.primaryGradientStart,
                                                            Color.primaryGradientEnd,
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 20, height: 20)
                                                .overlay(
                                                    Text(String(tokenBalance.symbol.prefix(1)))
                                                        .font(.caption2)
                                                        .fontWeight(.bold)
                                                        .foregroundColor(.white)
                                                )

                                            Text(tokenBalance.symbol)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primaryText)
                                        }

                                        Spacer()

                                        // Balance and USD value
                                        VStack(alignment: .trailing, spacing: 2) {
                                            Text(tokenBalance.formattedBalance)
                                                .font(.subheadline)
                                                .fontWeight(.medium)
                                                .foregroundColor(.primaryText)

                                            Text(tokenBalance.formattedUsdValue)
                                                .font(.caption)
                                                .foregroundColor(.tertiaryText)
                                        }
                                    }
                                }
                            }
                        }
                    }
                } else {
                    Text("Balance unavailable")
                        .secondaryText()
                }
            }
        }
    }
}

// WalletInfoRow replaced by InfoRow in design system

#Preview {
    HomeView(selectedTab: .constant(0))
}
