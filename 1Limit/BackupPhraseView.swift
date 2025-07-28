//
//  BackupPhraseView.swift
//  1Limit
//
//  Backup phrase screen with 12-word grid display 🔐✨
//

import SwiftUI

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

  private var recoveryWords: [String] {
    return generatedWallet?.mnemonic ?? []
  }

  var body: some View {
    let content = ZStack {
      Color.appBackground
        .ignoresSafeArea()

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
                        colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
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

            Text("Write down these 12 words in order. You'll need them to recover your wallet.")
              .secondaryText()
              .multilineTextAlignment(.center)
              .lineSpacing(4)
          }
          .padding(.top, 20)

          // 12-word grid or loading spinner
          AppCard {
            VStack(spacing: 16) {
              Text("Recovery Phrase")
                .cardTitle()

              if isGeneratingWallet {
                VStack(spacing: 20) {
                  ProgressView()
                    .scaleEffect(1.2)
                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))

                  Text("Generating secure wallet...")
                    .secondaryText()
                    .font(.subheadline)
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
                LazyVGrid(
                  columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                  spacing: 12
                ) {
                  ForEach(Array(recoveryWords.enumerated()), id: \.offset) { index, word in
                    WordCard(number: index + 1, word: word)
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
                SecurityWarningRow(text: "NOTE THAT THIS PROCESS WILL DELETE YOUR PREVIOUS WALLET")
                SecurityWarningRow(text: "Never share your recovery phrase with anyone")
                SecurityWarningRow(text: "Store it in a safe, offline location")
                SecurityWarningRow(text: "Anyone with these words can access your wallet")
                SecurityWarningRow(text: "1Limit will never ask for your recovery phrase")
              }
            }
          }

          Spacer(minLength: 40)
        }
        .padding()
      }
    }
    .navigationTitle("")
    .navigationBarTitleDisplayMode(.inline)
    .toolbarBackground(Color.appBackground, for: .navigationBar)
    .toolbar {
      ToolbarItem(placement: .navigationBarLeading) {
        SmallButton("Cancel", style: .secondary) {
          dismiss()
        }
      }
    }
    .navigationDestination(isPresented: $proceedToSetup) {
      SetupCompleteView(useStackNavigation: true, onComplete: onComplete)
    }
    .onAppear {
      Task {
        await generateWallet()
      }
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
