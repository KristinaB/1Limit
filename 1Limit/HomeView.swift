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
  
  // Wallet management state
  @StateObject private var walletLoader = WalletLoader.shared
  @StateObject private var balanceService = WalletBalanceService.shared
  @State private var currentWallet: WalletData?
  @State private var isLoadingWallet = false

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


          // Wallet balance display
          if let currentWallet = currentWallet {
            WalletBalanceCard(
              wallet: currentWallet,
              balanceSummary: balanceService.currentBalance,
              isLoading: balanceService.isLoading
            )
          }

          // Wallet management buttons
          VStack(spacing: 16) {
            HStack(spacing: 12) {
              SecondaryButton("Load Test Wallet", icon: "doc.fill") {
                Task {
                  await loadTestWallet()
                }
              }
              
              PrimaryButton("Create Wallet", icon: "plus.circle.fill") {
                showingWalletCreation = true
              }
            }
            
            if currentWallet != nil {
              SecondaryButton("Switch Wallet Mode", icon: "arrow.triangle.2.circlepath") {
                Task {
                  await switchWalletMode()
                }
              }
            }
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
    .onAppear {
      Task {
        await loadDefaultWallet()
      }
    }
  }
  
  // MARK: - Wallet Management Methods
  
  private func loadDefaultWallet() async {
    isLoadingWallet = true
    
    // Check if generated wallet exists, otherwise load test wallet
    if await walletLoader.hasGeneratedWallet() {
      currentWallet = await walletLoader.switchWalletMode(to: .generatedWallet)
    } else {
      currentWallet = await walletLoader.switchWalletMode(to: .testWallet)
    }
    
    if let wallet = currentWallet {
      await balanceService.fetchWalletBalance(for: wallet.address, forceRefresh: true)
      balanceService.startAutoRefresh(for: wallet.address)
    }
    
    isLoadingWallet = false
  }
  
  private func loadTestWallet() async {
    isLoadingWallet = true
    currentWallet = await walletLoader.switchWalletMode(to: .testWallet)
    
    if let wallet = currentWallet {
      await balanceService.fetchWalletBalance(for: wallet.address, forceRefresh: true)
      balanceService.startAutoRefresh(for: wallet.address)
    }
    
    isLoadingWallet = false
  }
  
  private func switchWalletMode() async {
    guard let currentWallet = currentWallet else { return }
    
    isLoadingWallet = true
    balanceService.stopAutoRefresh()
    
    let newMode: WalletMode = walletLoader.currentWalletMode == .testWallet ? .generatedWallet : .testWallet
    
    let hasGeneratedWallet = await walletLoader.hasGeneratedWallet()
    if newMode == .generatedWallet && !hasGeneratedWallet {
      print("⚠️ No generated wallet found, staying with test wallet")
      isLoadingWallet = false
      return
    }
    
    self.currentWallet = await walletLoader.switchWalletMode(to: newMode)
    
    if let wallet = self.currentWallet {
      await balanceService.fetchWalletBalance(for: wallet.address, forceRefresh: true)
      balanceService.startAutoRefresh(for: wallet.address)
    }
    
    isLoadingWallet = false
  }
}

// MARK: - Wallet Balance Card

struct WalletBalanceCard: View {
  let wallet: WalletData
  let balanceSummary: WalletBalanceSummary?
  let isLoading: Bool
  
  private var maskedAddress: String {
    guard wallet.address.count >= 10 else { return wallet.address }
    let start = String(wallet.address.prefix(6))
    let end = String(wallet.address.suffix(4))
    return "\(start)...\(end)"
  }
  
  var body: some View {
    AppCard {
      VStack(spacing: 16) {
        // Header with wallet address
        HStack {
          VStack(alignment: .leading, spacing: 4) {
            Text("Active Wallet")
              .font(.caption)
              .foregroundColor(.tertiaryText)
            
            Text(maskedAddress)
              .font(.system(.subheadline, design: .monospaced))
              .foregroundColor(.primaryText)
          }
          
          Spacer()
          
          // Wallet type indicator
          Text(WalletLoader.shared.currentWalletMode == .testWallet ? "TEST" : "YOURS")
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              RoundedRectangle(cornerRadius: 4)
                .fill(WalletLoader.shared.currentWalletMode == .testWallet ? 
                      Color.warningOrange.opacity(0.2) : Color.successGreen.opacity(0.2))
            )
            .foregroundColor(WalletLoader.shared.currentWalletMode == .testWallet ? 
                            Color.warningOrange : Color.successGreen)
        }
        
        Divider()
          .background(Color.borderGray.opacity(0.3))
        
        // Balance display
        if isLoading {
          HStack {
            ProgressView()
              .scaleEffect(0.8)
            Text("Loading balance...")
              .secondaryText()
          }
        } else if let summary = balanceSummary {
          VStack(spacing: 12) {
            // Total balance
            VStack(spacing: 4) {
              Text("Total Balance")
                .font(.caption)
                .foregroundColor(.tertiaryText)
              
              Text(summary.formattedTotalValue)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primaryText)
            }
            
            // Token balances
            if !summary.tokenBalances.isEmpty {
              VStack(spacing: 8) {
                ForEach(summary.tokenBalances, id: \.symbol) { tokenBalance in
                  HStack {
                    // Token symbol
                    HStack(spacing: 6) {
                      Circle()
                        .fill(LinearGradient(
                          colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
                          startPoint: .topLeading,
                          endPoint: .bottomTrailing
                        ))
                        .frame(width: 20, height: 20)
                        .overlay(
                          Text(String(tokenBalance.symbol.prefix(1)))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        )
                      
                      Text(tokenBalance.symbol)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                    }
                    
                    Spacer()
                    
                    // Balance and USD value
                    VStack(alignment: .trailing, spacing: 2) {
                      Text(tokenBalance.formattedBalance)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.primaryText)
                      
                      Text(tokenBalance.formattedUsdValue)
                        .font(.caption)
                        .foregroundColor(.tertiaryText)
                    }
                  }
                }
              }
            }
          }
        } else {
          Text("Balance unavailable")
            .secondaryText()
        }
      }
    }
  }
}

// WalletInfoRow replaced by InfoRow in design system

#Preview {
  HomeView(selectedTab: .constant(0))
}
