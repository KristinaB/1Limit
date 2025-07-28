//
//  ReceiveFundsView.swift
//  1Limit
//
//  View for receiving funds with QR code and address copying 💰📱
//

import SwiftUI

struct ReceiveFundsView: View {
  let wallet: WalletData
  @Environment(\.dismiss) private var dismiss
  @State private var showingCopiedAlert = false
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()
        
        ScrollView {
          FundsContentView(
            title: "Receive Funds",
            walletAddress: wallet.address,
            buttonTitle: "Done",
            buttonAction: { dismiss() },
            onCopyAddress: copyAddress
          )
        }
      }
      .navigationTitle("Receive Funds")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button("Done") {
            dismiss()
          }
          .foregroundColor(.primaryGradientStart)
        }
      }
      .alert("Address Copied!", isPresented: $showingCopiedAlert) {
        Button("OK") { }
      } message: {
        Text("The wallet address has been copied to your clipboard.")
      }
    }
  }
  
  private func copyAddress() {
    UIPasteboard.general.string = wallet.address
    showingCopiedAlert = true
    
    // Haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
  }
}

#Preview {
  ReceiveFundsView(wallet: WalletData(
    address: "0x3f847d4390b5a2783ea4aed6887474de8ffffa95",
    privateKey: "0x0000000000000000000000000000000000000000000000000000000000000001"
  ))
}