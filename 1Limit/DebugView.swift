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
                                Image(systemName: "hammer.fill")
                                    .font(.system(size: 50))
                                    .foregroundColor(.primaryGradientStart)
                                
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
    }
    
    private func executeTestTransaction() {
        Task {
            await routerManager.executeTestTransaction()
        }
    }
    
    private func copyLogToClipboard() {
        UIPasteboard.general.string = routerManager.executionLog
    }
}

// DebugInfoRow replaced by InfoCard in design system

#Preview {
    DebugView()
}