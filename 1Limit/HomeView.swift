//
//  HomeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct HomeView: View {
    @State private var showingWalletCreation = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // App branding
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.primaryGradientStart)
                        
                        Text("Welcome to 1Limit")
                            .appTitle()
                        
                        Text("Your 1inch Router V6 Wallet")
                            .secondaryText()
                    }
                    .padding(.top, 20)
                    
                    // Wallet info card
                    InfoCard(
                        title: "Wallet Status",
                        items: [
                            ("Network", "Polygon Mainnet", nil),
                            ("Router Version", "V6", nil),
                            ("Status", "Ready", .successGreen)
                        ]
                    )
                    
                    // Action buttons
                    VStack(spacing: 16) {
                        PrimaryButton("Create Wallet", icon: "plus.circle.fill") {
                            showingWalletCreation = true
                        }
                        
                        SecondaryButton("Import Wallet", icon: "square.and.arrow.down") {
                            // TODO: Implement wallet import
                            print("Import wallet tapped")
                        }
                    }
                    
                    // Help text
                    Text("Use the Trade tab to create limit orders 🚀")
                        .captionText()
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(Color.appBackground, for: .navigationBar)
        .sheet(isPresented: $showingWalletCreation) {
            WalletCreationView()
        }
    }
}

// WalletInfoRow replaced by InfoRow in design system

#Preview {
    HomeView()
}