//
//  WalletCreationView.swift
//  1Limit
//
//  Wallet creation modal with sleek dark design 🦄✨
//

import SwiftUI

struct WalletCreationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showBackupPhrase = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.black
                    .ignoresSafeArea()
                
                VStack(spacing: 40) {
                    Spacer()
                    
                    // App icon and branding
                    VStack(spacing: 24) {
                        // App icon with gradient background
                        ZStack {
                            RoundedRectangle(cornerRadius: 20)
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.primaryGradientStart.opacity(0.8),
                                            Color.primaryGradientEnd.opacity(0.6),
                                            Color.borderGray.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Image(systemName: "chart.line.uptrend.xyaxis")
                                .font(.system(size: 36, weight: .medium))
                                .foregroundColor(.white)
                        }
                        
                        // Title and description
                        VStack(spacing: 8) {
                            Text("1Limit")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            Text("Secure blockchain trading with\nadvanced limit orders and portfolio\nmanagement")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                                .lineSpacing(2)
                        }
                    }
                    
                    Spacer()
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        // Create Wallet button
                        PrimaryButton("Create Wallet", icon: "wallet.pass.fill") {
                            showBackupPhrase = true
                        }
                        
                        // Restore Wallet button
                        SecondaryButton("Restore Wallet", icon: "arrow.down.circle") {
                            // TODO: Implement wallet restoration
                            print("Restore wallet tapped")
                        }
                    }
                    .padding(.horizontal, 32)
                    
                    Spacer()
                }
                .padding()
            }
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .fullScreenCover(isPresented: $showBackupPhrase) {
            BackupPhraseView()
        }
    }
}

#Preview {
    WalletCreationView()
}