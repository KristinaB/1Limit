//
//  LoadFundsView.swift
//  1Limit
//
//  Load funds screen with QR code and wallet address 💰📱
//

import SwiftUI

struct LoadFundsView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingCopiedAlert = false
    var useStackNavigation: Bool = false
    var onComplete: (() -> Void)?
    
    // Sample wallet address
    private let walletAddress = "0x742d35Cc6634C0532925a3b8D2eF8d89e8F2F3C4"
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    FundsContentView(
                        title: "Load Funds",
                        walletAddress: walletAddress,
                        buttonTitle: "Continue to Trade",
                        buttonAction: {
                            if useStackNavigation {
                                onComplete?()
                            } else {
                                dismiss()
                                onComplete?()
                            }
                        },
                        onCopyAddress: copyAddress
                    )
                }
            }
            .navigationTitle("Load Funds")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    SmallButton("Done", style: .secondary) {
                        if useStackNavigation {
                            onComplete?()
                        } else {
                            dismiss()
                            onComplete?()
                        }
                    }
                }
            }
            .alert("Address Copied!", isPresented: $showingCopiedAlert) {
                Button("OK") { }
            } message: {
                Text("The wallet address has been copied to your clipboard.")
            }
        }
        .preferredColorScheme(.dark)
    }
    
    private func copyAddress() {
        UIPasteboard.general.string = walletAddress
        showingCopiedAlert = true
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
    }
}

#Preview {
    LoadFundsView()
}