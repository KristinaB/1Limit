//
//  BackupPhraseView.swift
//  1Limit
//
//  Backup phrase screen with 12-word grid display 🔐✨
//

import SwiftUI
import UIKit

struct BackupPhraseView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var proceedToSetup = false
    var useStackNavigation: Bool = false
    var onComplete: (() -> Void)?

    // Wallet generation state
    @StateObject private var walletGenerator = WalletGenerator.shared
    @State private var generatedWallet: GeneratedWallet?
    @State private var isGeneratingWallet = false
    @State private var generationError: String?

    // Balance checking state
    @StateObject private var balanceService = WalletBalanceService()
    @State private var oldWalletAddress: String?
    @State private var showBalanceWarning = false
    @State private var oldWalletBalance: String = "$0.00"

    // Copy functionality state
    @State private var mnemonicCopied = false
    @State private var showCopyAlert = false

    private var recoveryWords: [String] {
        return generatedWallet?.mnemonic ?? []
    }

    var body: some View {
        let content = ZStack {
            Color.appBackground
                .ignoresSafeArea()

            if isGeneratingWallet && generatedWallet == nil {
                // Full-screen loader while generating wallet
                VStack(spacing: 32) {
                    Spacer()

                    VStack(spacing: 24) {
                        // Animated icon
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
                                            lineWidth: 3
                                        )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 12, x: 0, y: 6)
                                .shadow(color: Color.black.opacity(0.3), radius: 3, x: 0, y: 2)

                            Image(systemName: "key.fill")
                                .font(.system(size: 48, weight: .medium))
                                .foregroundColor(.white)
                        }

                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))

                            Text("Generating Your Secure Wallet")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)

                            Text("Creating a cryptographically secure 12-word recovery phrase...")
                                .secondaryText()
                                .multilineTextAlignment(.center)
                                .frame(maxWidth: 300)
                        }
                    }

                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // Normal content after wallet is generated
                ScrollView {
                    VStack(spacing: 24) {
                        // Header section
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

                                Image(systemName: "key.fill")
                                    .font(.system(size: 36, weight: .medium))
                                    .foregroundColor(.white)
                            }

                            Text("Save Your Recovery Phrase")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.primaryText)

                            Text(
                                "Write down these 12 words in order. You'll need them to recover your wallet."
                            )
                            .secondaryText()
                            .multilineTextAlignment(.center)
                            .lineSpacing(4)
                        }
                        .padding(.top, 20)

                        // 12-word grid or error state
                        AppCard {
                            VStack(spacing: 16) {
                                Text("Recovery Phrase")
                                    .cardTitle()

                                if isGeneratingWallet && generatedWallet == nil {
                                    // Loading spinner while generating wallet key
                                    VStack(spacing: 16) {
                                        ProgressView()
                                            .scaleEffect(1.2)
                                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryGradientStart))
                                        
                                        Text("Generating secure keys...")
                                            .font(.subheadline)
                                            .foregroundColor(.secondaryText)
                                    }
                                    .frame(minHeight: 200)
                                    .frame(maxWidth: .infinity)
                                } else if generationError != nil {
                                    VStack(spacing: 16) {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(.warningOrange)

                                        Text("Wallet generation failed")
                                            .foregroundColor(.warningOrange)
                                            .font(.subheadline)
                                            .fontWeight(.medium)

                                        if let error = generationError {
                                            Text(error)
                                                .secondaryText()
                                                .font(.caption)
                                                .multilineTextAlignment(.center)
                                        }
                                    }
                                    .frame(minHeight: 200)
                                    .frame(maxWidth: .infinity)
                                } else if generatedWallet != nil {
                                    VStack(spacing: 20) {
                                        // Recovery words grid
                                        LazyVGrid(
                                            columns: Array(
                                                repeating: GridItem(.flexible(), spacing: 12),
                                                count: 3),
                                            spacing: 12
                                        ) {
                                            ForEach(Array(recoveryWords.enumerated()), id: \.offset)
                                            { index, word in
                                                WordCard(number: index + 1, word: word)
                                            }
                                        }

                                        // Copy mnemonic button
                                        SecondaryButton(
                                            "Copy Recovery Phrase",
                                            icon: mnemonicCopied
                                                ? "checkmark.circle.fill" : "doc.on.doc.fill"
                                        ) {
                                            copyMnemonicToClipboard()
                                        }
                                        .disabled(recoveryWords.isEmpty)

                                        // New wallet address section
                                        VStack(spacing: 12) {
                                            HStack {
                                                Text("New Wallet Address:")
                                                    .font(.subheadline)
                                                    .fontWeight(.medium)
                                                    .foregroundColor(.secondaryText)
                                                Spacer()
                                            }

                                            HStack {
                                                Text(generatedWallet?.walletData.address ?? "")
                                                    .font(.system(.footnote, design: .monospaced))
                                                    .foregroundColor(.primaryText)
                                                    .lineLimit(1)
                                                    .truncationMode(.middle)
                                                Spacer()
                                            }
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.inputBackground)
                                                    .overlay(
                                                        RoundedRectangle(cornerRadius: 8)
                                                            .strokeBorder(
                                                                Color.primaryGradientStart.opacity(
                                                                    0.3), lineWidth: 1)
                                                    )
                                            )
                                        }
                                    }
                                }
                            }
                        }

                        // Continue button - only enabled when wallet is generated
                        if generatedWallet != nil {
                            PrimaryButton("I've Saved My Phrase - REPLACE WALLET") {
                                Task {
                                    await saveWalletAndProceed()
                                }
                            }
                            .padding(.top, 20)
                        } else if generationError != nil {
                            SecondaryButton("Try Again") {
                                Task {
                                    await generateWallet()
                                }
                            }
                            .padding(.top, 20)
                        }

                        // Security warning
                        AppCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.warningOrange)
                                    Text("Important Security Notice")
                                        .cardTitle()
                                }

                                VStack(alignment: .leading, spacing: 8) {
                                    SecurityWarningRow(
                                        text:
                                            "NOTE THAT THIS PROCESS WILL DELETE YOUR PREVIOUS WALLET"
                                    )
                                    SecurityWarningRow(
                                        text: "Never share your recovery phrase with anyone")
                                    SecurityWarningRow(text: "Store it in a safe, offline location")
                                    SecurityWarningRow(
                                        text: "Anyone with these words can access your wallet")
                                    SecurityWarningRow(
                                        text: "1Limit will never ask for your recovery phrase")
                                }
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }  // End of else block for normal content
        }
        .animation(.easeInOut(duration: 0.3), value: isGeneratingWallet)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                if !(isGeneratingWallet && generatedWallet == nil) {
                    SmallButton("Cancel", style: .secondary) {
                        dismiss()
                    }
                }
            }
        }
        .navigationDestination(isPresented: $proceedToSetup) {
            SetupCompleteView(useStackNavigation: true, onComplete: onComplete)
        }
        .onAppear {
            Task {
                await loadCurrentWalletAndCheckBalance()
                await generateWallet()
            }
        }
        .alert("Wallet Balance Warning", isPresented: $showBalanceWarning) {
            Button("Continue Anyway", role: .destructive) {
                // User chooses to proceed despite non-zero balance
            }
        } message: {
            VStack(alignment: .leading, spacing: 8) {
                Text("Your current wallet has a balance of \(oldWalletBalance).")
                Text("")
                Text(
                    "Creating a new wallet will replace your current wallet. Make sure you have backed up your current wallet or transferred your funds."
                )
            }
        }
        .alert("Recovery Phrase Copied!", isPresented: $showCopyAlert) {
            Button("OK") {}
        } message: {
            Text("Your 12-word recovery phrase has been copied to the clipboard. Store it safely!")
        }

        if useStackNavigation {
            return AnyView(
                content
                    .preferredColorScheme(.dark))
        } else {
            return AnyView(
                NavigationView {
                    content
                }
                .preferredColorScheme(.dark)
                .fullScreenCover(isPresented: $proceedToSetup) {
                    SetupCompleteView(onComplete: onComplete)
                })
        }
    }

    // MARK: - Wallet Loading and Balance Check Methods

    private func loadCurrentWalletAndCheckBalance() async {
        // Load the current wallet to get its address
        if let currentWallet = await WalletLoader.shared.loadWallet() {
            oldWalletAddress = currentWallet.address
            print("🔍 Current wallet address: \(currentWallet.address)")

            // Check the balance of the current wallet
            await balanceService.fetchWalletBalance(for: currentWallet.address)

            // Check if balance is non-zero
            if let balance = balanceService.currentBalance {
                await MainActor.run {
                    oldWalletBalance = balance.formattedTotalValue

                    // Show warning if balance is greater than $0.10 (to account for dust)
                    if balance.totalUsdValue > 0.10 {
                        showBalanceWarning = true
                    }
                }

                print("💰 Current wallet balance: \(balance.formattedTotalValue)")
            }
        } else {
            print("ℹ️ No current wallet found")
        }
    }

    // MARK: - Wallet Generation Methods

    private func generateWallet() async {
        guard generatedWallet == nil else { return }  // Don't regenerate if already done

        isGeneratingWallet = true
        generationError = nil

        do {
            print("🎲 Generating new wallet with mnemonic...")
            let wallet = try await walletGenerator.generateNewWallet()

            await MainActor.run {
                self.generatedWallet = wallet
                self.isGeneratingWallet = false
            }

            print("✅ Wallet generated successfully: \(wallet.walletData.address)")

        } catch {
            await MainActor.run {
                self.generationError = error.localizedDescription
                self.isGeneratingWallet = false
            }

            print("❌ Wallet generation failed: \(error)")
        }
    }

    private func saveWalletAndProceed() async {
        guard let wallet = generatedWallet else {
            print("❌ No wallet to save")
            return
        }

        do {
            print("🔒 Saving wallet securely...")
            try await walletGenerator.storeWalletSecurely(wallet, requireBiometric: false)

            await MainActor.run {
                self.proceedToSetup = true
            }

            print("✅ Wallet saved and proceeding to completion")

        } catch {
            await MainActor.run {
                self.generationError = "Failed to save wallet: \(error.localizedDescription)"
            }

            print("❌ Failed to save wallet: \(error)")
        }
    }

    // MARK: - Copy Functionality

    private func copyMnemonicToClipboard() {
        let mnemonicString = recoveryWords.joined(separator: " ")
        UIPasteboard.general.string = mnemonicString

        mnemonicCopied = true
        showCopyAlert = true

        // Reset the checkmark after 3 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            mnemonicCopied = false
        }

        print("📋 Mnemonic copied to clipboard: \(recoveryWords.count) words")
    }
}

struct WordCard: View {
    let number: Int
    let word: String

    var body: some View {
        VStack(spacing: 8) {
            Text("\(number)")
                .font(.caption)
                .foregroundColor(.tertiaryText)

            Text(word)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.primaryText)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.inputBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct SecurityWarningRow: View {
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(Color.warningOrange)
                .frame(width: 6, height: 6)
                .padding(.top, 6)

            Text(text)
                .secondaryText()
                .multilineTextAlignment(.leading)
        }
    }
}

#Preview {
    BackupPhraseView()
}
