//
//  DebugView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct DebugView: View {
    @StateObject private var routerManager = RouterV6ManagerFactory.createProductionManager()
    @Environment(\.dismiss) private var dismiss
    @State private var showingResetAlert = false
    var onResetComplete: (() -> Void)? = nil
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        AppCard {
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
                                    
                                    Image(systemName: "hammer.fill")
                                        .font(.system(size: 36, weight: .medium))
                                        .foregroundColor(.white)
                                }
                                
                                Text("Debug Console")
                                    .appTitle()
                                
                                Text("Test 1inch Router V6 Integration")
                                    .secondaryText()
                            }
                        }
                        
                        // Test parameters info
                        InfoCard(
                            title: "Test Parameters",
                            items: [
                                ("Network", "Polygon Mainnet", nil),
                                ("Router", "V6 (0x1111...)", nil),
                                ("From", "0.01 WMATIC", nil),
                                ("To", "0.01 USDC", nil),
                                ("Type", "Limit Order", nil)
                            ]
                        )
                
                        // Execute button
                        if routerManager.isExecuting {
                            SecondaryButton("Executing...", icon: "hourglass") {
                                // Disabled while executing
                            }
                            .disabled(true)
                            .opacity(0.6)
                        } else {
                            PrimaryButton("Execute Test Transaction", icon: "play.circle.fill") {
                                executeTestTransaction()
                            }
                        }
                        
                        // Reset Application Button
                        SecondaryButton("Reset Application", icon: "trash.circle.fill") {
                            showingResetAlert = true
                        }
                
                        if !routerManager.executionLog.isEmpty {
                            AppCard {
                                VStack(spacing: 16) {
                                    HStack {
                                        Text("Debug Log")
                                            .cardTitle()
                                        Spacer()
                                        SmallButton("Copy", style: .secondary) {
                                            copyLogToClipboard()
                                        }
                                    }
                                    
                                    ScrollView {
                                        Text(routerManager.executionLog)
                                            .font(.system(.caption, design: .monospaced))
                                            .foregroundColor(.primaryText)
                                            .textSelection(.enabled)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .padding(12)
                                            .background(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .fill(Color.inputBackground)
                                            )
                                    }
                                    .frame(maxHeight: 200)
                                }
                            }
                        }
                        
                        Spacer(minLength: 40)
                    }
                    .padding()
                }
            }
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    SmallButton("Done", style: .secondary) {
                        dismiss()
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .alert("Reset Application", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Reset", role: .destructive) {
                resetApplication()
            }
        } message: {
            Text("This will clear all app data including wallets, transactions, and settings. You will be returned to the Home screen.")
        }
    }
    
    private func executeTestTransaction() {
        Task {
            await routerManager.executeTestTransaction()
        }
    }
    
    private func resetApplication() {
        Task {
            await performReset()
            
            // Dismiss debug view and call reset completion callback
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                dismiss()
                onResetComplete?()
            }
        }
    }
    
    @MainActor
    private func performReset() async {
        print("🔄 Starting application reset...")
        
        // Clear stored wallet
        do {
            try await WalletGenerator.shared.clearStoredWallet()
            print("✅ Cleared stored wallet")
        } catch {
            print("❌ Error clearing wallet: \(error)")
        }
        
        // Clear all transactions
        do {
            let transactionManager = TransactionManagerFactory.createProduction()
            await transactionManager.clearAllTransactions()
            print("✅ Cleared all transactions")
        } catch {
            print("❌ Error clearing transactions: \(error)")
        }
        
        // Clear UserDefaults
        if let bundleID = Bundle.main.bundleIdentifier {
            UserDefaults.standard.removePersistentDomain(forName: bundleID)
            UserDefaults.standard.synchronize()
            print("✅ Cleared UserDefaults")
        }
        
        // Clear Documents directory files
        let fileManager = FileManager.default
        if let documentsPath = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first {
            do {
                let files = try fileManager.contentsOfDirectory(at: documentsPath, includingPropertiesForKeys: nil)
                for file in files {
                    try fileManager.removeItem(at: file)
                }
                print("✅ Cleared Documents directory")
            } catch {
                print("❌ Error clearing Documents directory: \(error)")
            }
        }
        
        print("🎉 Application reset complete!")
    }
    
    private func copyLogToClipboard() {
        UIPasteboard.general.string = routerManager.executionLog
    }
}

// DebugInfoRow replaced by InfoCard in design system

#Preview {
    DebugView()
}