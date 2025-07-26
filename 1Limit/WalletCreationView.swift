//
//  WalletCreationView.swift
//  1Limit
//
//  Wallet creation modal with sleek dark design 🦄✨
//

import SwiftUI

struct WalletCreationView: View {
    @Environment(\.dismiss) private var dismiss
    
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
                                            Color.blue.opacity(0.8),
                                            Color.purple.opacity(0.6),
                                            Color.gray.opacity(0.4)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 80, height: 80)
                            
                            Text("1")
                                .font(.system(size: 36, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("Limit")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                                .offset(x: 8, y: 20)
                        }
                        
                        // Title and description
                        VStack(spacing: 8) {
                            Text("Crypto Trade")
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
                        Button(action: {
                            // TODO: Implement wallet creation
                            print("Create new wallet tapped")
                        }) {
                            Text("Create Wallet")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.purple.opacity(0.8)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                        }
                        
                        // Restore Wallet button
                        Button(action: {
                            // TODO: Implement wallet restoration
                            print("Restore wallet tapped")
                        }) {
                            Text("Restore Wallet")
                                .font(.headline)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(
                                    RoundedRectangle(cornerRadius: 25)
                                        .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                )
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
    }
}

#Preview {
    WalletCreationView()
}