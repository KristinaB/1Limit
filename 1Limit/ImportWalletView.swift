//
//  ImportWalletView.swift
//  1Limit
//
//  Import wallet from 12-word mnemonic phrase 📥🔐
//

import SwiftUI
import UIKit

struct ImportWalletView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var mnemonicWords: [String] = Array(repeating: "", count: 12)
  @State private var isImporting = false
  @State private var importError: String?
  @State private var showSuccessAlert = false
  @State private var mnemonicInput = ""
  @State private var useTextArea = false
  
  let onComplete: () -> Void
  
  var body: some View {
    NavigationView {
      ZStack {
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
                
                Image(systemName: "square.and.arrow.down.fill")
                  .font(.system(size: 36, weight: .medium))
                  .foregroundColor(.white)
              }
              
              Text("Import Wallet")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primaryText)
              
              Text("Enter your 12-word recovery phrase to import your wallet.")
                .secondaryText()
                .multilineTextAlignment(.center)
                .lineSpacing(4)
            }
            .padding(.top, 20)
            
            // Input method toggle
            AppCard {
              VStack(spacing: 16) {
                Text("Input Method")
                  .cardTitle()
                
                HStack(spacing: 12) {
                  Button {
                    useTextArea = false
                    mnemonicInput = mnemonicWords.joined(separator: " ")
                  } label: {
                    HStack {
                      Image(systemName: useTextArea ? "square" : "checkmark.square.fill")
                      Text("Word Grid")
                    }
                    .foregroundColor(useTextArea ? .secondaryText : .primaryText)
                  }
                  
                  Spacer()
                  
                  Button {
                    useTextArea = true
                    // Sync from individual words to text area
                    mnemonicInput = mnemonicWords.filter { !$0.isEmpty }.joined(separator: " ")
                  } label: {
                    HStack {
                      Image(systemName: !useTextArea ? "square" : "checkmark.square.fill")
                      Text("Text Area")
                    }
                    .foregroundColor(!useTextArea ? .secondaryText : .primaryText)
                  }
                }
              }
            }
            
            // Input area
            AppCard {
              VStack(spacing: 16) {
                Text("Recovery Phrase")
                  .cardTitle()
                
                if isImporting {
                  VStack(spacing: 20) {
                    ProgressView()
                      .scaleEffect(1.2)
                      .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                    
                    Text("Importing wallet...")
                      .secondaryText()
                      .font(.subheadline)
                  }
                  .frame(minHeight: 200)
                  .frame(maxWidth: .infinity)
                  
                } else if importError != nil {
                  VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                      .font(.system(size: 32))
                      .foregroundColor(.warningOrange)
                    
                    Text("Import failed")
                      .foregroundColor(.warningOrange)
                      .font(.subheadline)
                      .fontWeight(.medium)
                    
                    if let error = importError {
                      Text(error)
                        .secondaryText()
                        .font(.caption)
                        .multilineTextAlignment(.center)
                    }
                  }
                  .frame(minHeight: 200)
                  .frame(maxWidth: .infinity)
                  
                } else if useTextArea {
                  // Text area input
                  VStack(spacing: 16) {
                    TextEditor(text: $mnemonicInput)
                      .frame(minHeight: 120)
                      .padding(12)
                      .background(
                        RoundedRectangle(cornerRadius: 8)
                          .fill(Color.inputBackground)
                          .overlay(
                            RoundedRectangle(cornerRadius: 8)
                              .strokeBorder(Color.primaryGradientStart.opacity(0.3), lineWidth: 1)
                          )
                      )
                      .onChange(of: mnemonicInput) { newValue in
                        // Sync text area to individual words
                        let words = newValue.lowercased()
                          .components(separatedBy: CharacterSet.whitespacesAndNewlines)
                          .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                          .filter { !$0.isEmpty }
                        
                        for i in 0..<12 {
                          mnemonicWords[i] = i < words.count ? words[i] : ""
                        }
                      }
                    
                    Text("Paste or type your 12 words separated by spaces")
                      .font(.caption)
                      .foregroundColor(.tertiaryText)
                      .multilineTextAlignment(.center)
                    
                    // Paste button
                    SecondaryButton("Paste from Clipboard", icon: "doc.on.clipboard") {
                      if let clipboardText = UIPasteboard.general.string {
                        mnemonicInput = clipboardText
                      }
                    }
                  }
                  
                } else {
                  // Grid input
                  VStack(spacing: 20) {
                    LazyVGrid(
                      columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3),
                      spacing: 12
                    ) {
                      ForEach(0..<12, id: \.self) { index in
                        MnemonicWordInput(
                          number: index + 1,
                          word: $mnemonicWords[index]
                        )
                      }
                    }
                    
                    // Clear and paste buttons
                    HStack(spacing: 12) {
                      SecondaryButton("Clear All", icon: "trash") {
                        mnemonicWords = Array(repeating: "", count: 12)
                        mnemonicInput = ""
                      }
                      
                      SecondaryButton("Paste from Clipboard", icon: "doc.on.clipboard") {
                        if let clipboardText = UIPasteboard.general.string {
                          let words = clipboardText.lowercased()
                            .components(separatedBy: CharacterSet.whitespacesAndNewlines)
                            .map { $0.trimmingCharacters(in: .punctuationCharacters) }
                            .filter { !$0.isEmpty }
                          
                          for i in 0..<12 {
                            mnemonicWords[i] = i < words.count ? words[i] : ""
                          }
                          
                          mnemonicInput = mnemonicWords.joined(separator: " ")
                        }
                      }
                    }
                  }
                }
              }
            }
            
            // Import button
            if !isImporting {
              PrimaryButton("Import Wallet - REPLACE CURRENT") {
                Task {
                  await importWallet()
                }
              }
              .disabled(!isValidMnemonic)
              .padding(.top, 20)
            } else if importError != nil {
              SecondaryButton("Try Again") {
                importError = nil
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
                  SecurityWarningRow(text: "This will REPLACE your current wallet permanently")
                  SecurityWarningRow(text: "Make sure you have backed up your current wallet")
                  SecurityWarningRow(text: "Only import wallets you own and trust")
                  SecurityWarningRow(text: "Never share your recovery phrase with anyone")
                  SecurityWarningRow(text: "Double-check all 12 words are spelled correctly")
                }
              }
            }
            
            Spacer(minLength: 40)
          }
          .padding()
        }
      }
      .navigationTitle("Import Wallet")
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
    .alert("Wallet Imported Successfully!", isPresented: $showSuccessAlert) {
      Button("Done") {
        dismiss()
        onComplete()
      }
    } message: {
      Text("Your wallet has been imported and is now active. You can start trading!")
    }
    .preferredColorScheme(.dark)
  }
  
  // MARK: - Computed Properties
  
  private var isValidMnemonic: Bool {
    let words = mnemonicWords.filter { !$0.isEmpty }
    return words.count == 12 && words.allSatisfy { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
  }
  
  // MARK: - Import Functionality
  
  private func importWallet() async {
    guard isValidMnemonic else { return }
    
    isImporting = true
    importError = nil
    
    do {
      let mnemonic = mnemonicWords.filter { !$0.isEmpty }
      print("🔄 Importing wallet from mnemonic: \(mnemonic.count) words")
      
      // Create wallet from mnemonic using WalletGenerator
      let generator = WalletGenerator.shared
      let importedWallet = try await generator.importWalletFromMnemonic(mnemonic)
      
      // Store the imported wallet securely
      try await generator.storeWalletSecurely(importedWallet, requireBiometric: false)
      
      await MainActor.run {
        self.isImporting = false
        self.showSuccessAlert = true
      }
      
      print("✅ Wallet imported successfully: \(importedWallet.walletData.address)")
      
    } catch {
      await MainActor.run {
        self.importError = error.localizedDescription
        self.isImporting = false
      }
      
      print("❌ Wallet import failed: \(error)")
    }
  }
}

// MARK: - Supporting Views

struct MnemonicWordInput: View {
  let number: Int
  @Binding var word: String
  
  var body: some View {
    VStack(spacing: 8) {
      Text("\(number)")
        .font(.caption)
        .foregroundColor(.tertiaryText)
      
      TextField("word", text: $word)
        .font(.subheadline)
        .fontWeight(.medium)
        .foregroundColor(.primaryText)
        .multilineTextAlignment(.center)
        .textInputAutocapitalization(.never)
        .autocorrectionDisabled()
        .onSubmit {
          // Move focus to next field if needed
        }
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 12)
    .padding(.horizontal, 8)
    .background(
      RoundedRectangle(cornerRadius: 8)
        .fill(Color.inputBackground)
        .overlay(
          RoundedRectangle(cornerRadius: 8)
            .strokeBorder(
              word.isEmpty ? Color.borderGray.opacity(0.3) : Color.primaryGradientStart.opacity(0.5), 
              lineWidth: 1
            )
        )
    )
  }
}

#Preview {
  ImportWalletView(onComplete: {})
}