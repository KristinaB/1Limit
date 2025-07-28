//
//  NoWalletView.swift
//  1Limit
//
//  Empty wallet state view with navigation options
//

import SwiftUI

struct NoWalletView: View {
  @Binding var showingWalletCreation: Bool
  @Binding var showingImportWallet: Bool
  var onTestWalletSelected: () async -> Void
  
  var body: some View {
    AppCard {
      VStack(spacing: 24) {
        // Icon
        ZStack {
          Circle()
            .fill(
              LinearGradient(
                colors: [
                  Color.white.opacity(0.1),
                  Color.white.opacity(0.05),
                  Color.clear,
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
                    colors: [Color.borderGray.opacity(0.5), Color.borderGray.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  ),
                  lineWidth: 1
                )
            )
          
          Image(systemName: "wallet.pass")
            .font(.system(size: 44, weight: .medium))
            .foregroundColor(.secondaryText)
        }
        
        VStack(spacing: 12) {
          Text("NO WALLET")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primaryText)
            .tracking(2)
          
          Text("You need a wallet to start trading.\nChoose how to get started:")
            .secondaryText()
            .multilineTextAlignment(.center)
            .lineSpacing(4)
        }
        
        // Wallet options
        VStack(spacing: 12) {
          PrimaryButton("Create New Wallet", icon: "plus.circle.fill") {
            showingWalletCreation = true
          }
          
          SecondaryButton("Import Existing Wallet", icon: "square.and.arrow.down.fill") {
            showingImportWallet = true
          }
          
          Divider()
            .background(Color.borderGray.opacity(0.3))
            .padding(.vertical, 4)
          
          VStack(spacing: 8) {
            SecondaryButton("Use Test Wallet", icon: "doc.fill") {
              Task {
                await onTestWalletSelected()
              }
            }
            
            Text("For demo and testing purposes")
              .captionText()
              .foregroundColor(.warningOrange)
          }
        }
      }
      .padding(.vertical, 8)
    }
  }
}

#Preview {
  NoWalletView(
    showingWalletCreation: .constant(false),
    showingImportWallet: .constant(false),
    onTestWalletSelected: { }
  )
  .preferredColorScheme(.dark)
  .padding()
  .background(Color.appBackground)
}