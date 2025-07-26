//
//  LoadFundsView.swift
//  1Limit
//
//  Load funds screen with QR code and wallet address 💰📱
//

import SwiftUI

struct LoadFundsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showPortfolio = false
    @State private var addressCopied = false
    
    // Sample wallet address
    private let walletAddress = "0x742d35Cc6634C0532925a3b8D2eF8d89e8F2F3C4"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 32) {
                        // Header
                        VStack(spacing: 16) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.primaryGradientStart)
                            
                            Text("Receive Ethereum")
                                .appTitle()
                            
                            Text("Send ETH or WMATIC to this address to fund your wallet")
                                .secondaryText()
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // QR Code section
                        AppCard {
                            VStack(spacing: 20) {
                                Text("QR Code")
                                    .cardTitle()
                                
                                // QR Code placeholder - would integrate with QR generation library
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.white)
                                        .frame(width: 200, height: 200)
                                    
                                    VStack(spacing: 8) {
                                        Image(systemName: "qrcode")
                                            .font(.system(size: 80))
                                            .foregroundColor(.black)
                                        Text("QR CODE")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                            .foregroundColor(.black)
                                    }
                                }
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
                                )
                            }
                        }
                        
                        // Wallet address section
                        AppCard {
                            VStack(spacing: 16) {
                                Text("Wallet Address")
                                    .cardTitle()
                                
                                // Address display
                                VStack(spacing: 12) {
                                    Text(walletAddress)
                                        .font(.system(.body, design: .monospaced))
                                        .foregroundColor(.secondaryText)
                                        .multilineTextAlignment(.center)
                                        .padding(12)
                                        .frame(maxWidth: .infinity)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.inputBackground)
                                        )
                                    
                                    SecondaryButton("Copy Address", icon: addressCopied ? "checkmark" : "doc.on.doc") {
                                        copyAddress()
                                    }
                                }
                            }
                        }
                        
                        // Continue button
                        PrimaryButton("Continue") {
                            showPortfolio = true
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Receive Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SmallButton("Done", style: .secondary) {
                        showPortfolio = true
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .fullScreenCover(isPresented: $showPortfolio) {
            PortfolioView()
        }
    }
    
    private func copyAddress() {
        UIPasteboard.general.string = walletAddress
        addressCopied = true
        
        // Reset the icon after 2 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            addressCopied = false
        }
    }
}

#Preview {
    LoadFundsView()
}