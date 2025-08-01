//
//  ContentView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @StateObject private var walletLoader = WalletLoader.shared
    @State private var hasWallet = false
    @State private var hasCheckedInitialState = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.appBackground
                    .ignoresSafeArea()
                
                TabView(selection: $selectedTab) {
                    HomeView(selectedTab: $selectedTab, onWalletStateChanged: { walletExists in
                        hasWallet = walletExists
                        // If wallet was removed and we're on Trade/Transactions tab, switch to Home
                        if !walletExists && selectedTab > 0 {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedTab = 0
                            }
                        }
                    })
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                        .tag(0)
                    
                    // Only show Trade tab when wallet exists
                    if hasWallet {
                        TradeView()
                            .tabItem {
                                Image(systemName: "arrow.left.arrow.right")
                                Text("Trade")
                            }
                            .tag(1)
                        
                        TransactionsView()
                            .tabItem {
                                Image(systemName: "list.bullet")
                                Text("Transactions")
                            }
                            .tag(2)
                    }
                }
                .background(Color.appBackground)
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
        .onAppear {
            Task {
                await checkWalletState()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func checkWalletState() async {
        guard !hasCheckedInitialState else { return }
        hasCheckedInitialState = true
        
        // Start with no wallet - tabs should only appear after user explicitly loads one
        // This ensures proper "no wallet" state on app launch
        hasWallet = false
        
        // Ensure we start on Home tab
        if selectedTab > 0 {
            selectedTab = 0
        }
    }
}

#Preview {
    ContentView()
}
