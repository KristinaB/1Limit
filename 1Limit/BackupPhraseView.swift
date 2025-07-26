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
    
    // Sample 12-word recovery phrase
    private let recoveryWords = [
        "forest", "umbrella", "piano",
        "sunset", "bridge", "quantum", 
        "marble", "voyage", "thunder",
        "crystal", "wisdom", "galaxy"
    ]
    
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
                                                Color.white.opacity(0.1)
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
                        
                        // 12-word grid
                        AppCard {
                            VStack(spacing: 16) {
                                Text("Recovery Phrase")
                                    .cardTitle()
                                
                                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                    ForEach(Array(recoveryWords.enumerated()), id: \.offset) { index, word in
                                        WordCard(number: index + 1, word: word)
                                    }
                                }
                            }
                        }
                        
                        // Continue button
                        PrimaryButton("I've Saved My Phrase") {
                            proceedToSetup = true
                        }
                        .padding(.top, 20)
                        
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
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $proceedToSetup) {
            SetupCompleteView()
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