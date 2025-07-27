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
  
  private var maskedAddress: String {
    guard wallet.address.count >= 10 else { return wallet.address }
    let start = String(wallet.address.prefix(6))
    let end = String(wallet.address.suffix(4))
    return "\(start)...\(end)"
  }
  
  var body: some View {
    NavigationView {
      ZStack {
        Color.appBackground
          .ignoresSafeArea()
        
        ScrollView {
          VStack(spacing: 32) {
            // Header
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
                
                Image(systemName: "arrow.down.circle.fill")
                  .font(.system(size: 36, weight: .medium))
                  .foregroundColor(.white)
              }
              
              Text("Receive Funds")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
              
              Text("Send tokens to this address on Polygon")
                .font(.subheadline)
                .foregroundColor(.secondaryText)
                .multilineTextAlignment(.center)
            }
            .padding(.top, 20)
            
            // QR Code Section
            AppCard {
              VStack(spacing: 20) {
                Text("Scan QR Code")
                  .font(.headline)
                  .foregroundColor(.primaryText)
                
                // QR Code placeholder (simple checkered pattern)
                ZStack {
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .frame(width: 200, height: 200)
                  
                  // Simple QR-like pattern
                  VStack(spacing: 4) {
                    ForEach(0..<8, id: \.self) { row in
                      HStack(spacing: 4) {
                        ForEach(0..<8, id: \.self) { col in
                          Rectangle()
                            .fill((row + col) % 2 == 0 ? Color.black : Color.clear)
                            .frame(width: 20, height: 20)
                        }
                      }
                    }
                  }
                  
                  // Overlay with wallet icon
                  Circle()
                    .fill(Color.primaryGradientStart)
                    .frame(width: 40, height: 40)
                    .overlay(
                      Image(systemName: "wallet.pass.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.white)
                    )
                }
                
                Text("Point your camera at this QR code")
                  .font(.caption)
                  .foregroundColor(.tertiaryText)
              }
              .padding(20)
            }
            
            // Address Section
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
                    Text(wallet.address)
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
                  
                  // Copy button
                  Button(action: copyAddress) {
                    HStack {
                      Image(systemName: "doc.on.doc.fill")
                        .font(.system(size: 16))
                      Text("Copy Address")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                      LinearGradient(
                        colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                        startPoint: .leading,
                        endPoint: .trailing
                      )
                    )
                    .cornerRadius(8)
                  }
                }
              }
              .padding(20)
            }
            
            // Warning Section
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
            
            Spacer(minLength: 20)
          }
          .padding()
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