//
//  HomeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct HomeView: View {
  @Binding var selectedTab: Int
  @State private var showingWalletCreation = false
  @State private var showingDebug = false

  var body: some View {
    ZStack {
      Color.appBackground
        .ignoresSafeArea()

      ScrollView {
        VStack(spacing: 24) {
          // App branding
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
                .frame(width: 100, height: 100)
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

              Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 48, weight: .medium))
                .foregroundColor(.white)
            }

            Text("1Limit")
              .appTitle()

            Text("Place Decentralized 1Inch Limit Orders with ease!")
              .secondaryText()
          }
          .padding(.top, 20)


          // Action buttons
          VStack(spacing: 16) {
//            PrimaryButton("Create Wallet", icon: "plus.circle.fill") {
//              showingWalletCreation = true
//            }
//
//            SecondaryButton("Import Wallet", icon: "square.and.arrow.down") {
//              // TODO: Implement wallet import
//              print("Import wallet tapped")
//            }
          }

          // Help text
          Text("Use the Trade tab to create limit orders 🚀")
            .captionText()
            .multilineTextAlignment(.center)
            .padding(.top, 20)

          Spacer(minLength: 40)

          // Debug button at bottom
          SmallButton("Debug", style: .secondary) {
            showingDebug = true
          }
          .padding(.bottom, 20)
        }
        .padding()
      }
    }
    .navigationTitle("Home")
    .navigationBarTitleDisplayMode(.large)
    .toolbarBackground(Color.appBackground, for: .navigationBar)
    .sheet(isPresented: $showingWalletCreation) {
      WalletSetupFlow(selectedTab: $selectedTab)
    }
    .sheet(isPresented: $showingDebug) {
      DebugView()
    }
  }
}

// WalletInfoRow replaced by InfoRow in design system

#Preview {
  HomeView(selectedTab: .constant(0))
}
