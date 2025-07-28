//
//  FundsComponents.swift
//  1Limit
//
//  Shared components for funds-related views (Receive/Load Funds) 💰📱
//  Uses a single FundsContentView for maximum code reuse
//

import SwiftUI

// MARK: - Private Supporting Components

private struct FundsHeaderView: View {
  let title: String
  let subtitle: String
  let iconName: String
  
  var body: some View {
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
        
        Image(systemName: iconName)
          .font(.system(size: 36, weight: .medium))
          .foregroundColor(.white)
      }
      
      Text(title)
        .font(.title2)
        .fontWeight(.bold)
        .foregroundColor(.primaryText)
      
      Text(subtitle)
        .font(.subheadline)
        .foregroundColor(.secondaryText)
        .multilineTextAlignment(.center)
    }
    .padding(.top, 20)
  }
}

private struct QRCodeSectionView: View {
  let walletAddress: String
  
  var body: some View {
    AppCard {
      VStack(spacing: 20) {
        Text("Scan QR Code")
          .font(.headline)
          .foregroundColor(.primaryText)
        
        // Custom QR Code with app design colors
        QRCodeView(
          text: "ethereum:\(walletAddress)?chainId=137",
          size: CGSize(width: 200, height: 200)
        )
        .background(
          RoundedRectangle(cornerRadius: 12)
            .fill(Color.white)
            .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        
        Text("Point your camera at this QR code")
          .font(.caption)
          .foregroundColor(.tertiaryText)
      }
      .padding(20)
    }
  }
}

private struct WalletAddressSectionView: View {
  let walletAddress: String
  let onCopyAddress: () -> Void
  @State private var addressCopied = false
  
  var body: some View {
    AppCard {
      VStack(spacing: 16) {
        HStack {
          Text("Wallet Address")
            .font(.headline)
            .foregroundColor(.primaryText)
          
          Spacer()
          
          // Network badge
          Text("Polygon")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(Color.purple.opacity(0.2))
            )
            .foregroundColor(.purple)
        }
        
        // Address display
        VStack(spacing: 12) {
          // Full address
          HStack {
            Text(walletAddress)
              .font(.system(.footnote, design: .monospaced))
              .foregroundColor(.secondaryText)
              .lineLimit(1)
              .truncationMode(.middle)
            
            Spacer()
          }
          .padding(12)
          .background(
            RoundedRectangle(cornerRadius: 8)
              .fill(Color.cardBackground.opacity(0.5))
          )
          
          // Copy button - using design system SecondaryButton style
          SecondaryButton(
            "Copy Address", 
            icon: addressCopied ? "checkmark" : "doc.on.doc.fill",
            action: handleCopyAddress
          )
        }
      }
      .padding(20)
    }
  }
  
  private func handleCopyAddress() {
    onCopyAddress()
    addressCopied = true
    
    // Reset the icon after 2 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
      addressCopied = false
    }
  }
}

private struct NetworkWarningView: View {
  var body: some View {
    AppCard {
      VStack(spacing: 12) {
        HStack {
          Image(systemName: "exclamationmark.triangle.fill")
            .font(.system(size: 20))
            .foregroundColor(.warningOrange)
          
          Text("Important")
            .font(.headline)
            .foregroundColor(.primaryText)
          
          Spacer()
        }
        
        VStack(alignment: .leading, spacing: 8) {
          Text("• Only send Polygon tokens to this address")
          Text("• Supported tokens: MATIC, WMATIC, USDC")
          Text("• Sending tokens from other networks will result in permanent loss")
          Text("• Always verify the address before sending")
        }
        .font(.subheadline)
        .foregroundColor(.secondaryText)
      }
      .padding(20)
    }
  }
}

// MARK: - Public Shared Component

/// Shared content view for both ReceiveFundsView and LoadFundsView
/// Provides consistent UI with only button text/action differences
struct FundsContentView: View {
  let title: String
  let walletAddress: String
  let buttonTitle: String
  let buttonAction: () -> Void
  let onCopyAddress: () -> Void
  
  var body: some View {
    VStack(spacing: 32) {
      // Header
      FundsHeaderView(
        title: title,
        subtitle: "Send tokens to this address on Polygon",
        iconName: "arrow.down.circle.fill"
      )
      
      // QR Code section
      QRCodeSectionView(walletAddress: walletAddress)
      
      // Wallet address section
      WalletAddressSectionView(
        walletAddress: walletAddress,
        onCopyAddress: onCopyAddress
      )
      
      // Network warning section
      NetworkWarningView()
      
      // Action button
      PrimaryButton(buttonTitle, action: buttonAction)
      
      Spacer(minLength: 20)
    }
    .padding()
  }
}