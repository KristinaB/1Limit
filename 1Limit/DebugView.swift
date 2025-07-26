//
//  DebugView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct DebugView: View {
    @StateObject private var routerManager = RouterV6Manager()
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 8) {
                    Image(systemName: "hammer.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.purple)
                    
                    Text("Debug Console")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("Test 1inch Router V6 Integration")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                // Test parameters info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Test Parameters")
                        .font(.headline)
                    
                    DebugInfoRow(title: "Network", value: "Polygon Mainnet")
                    DebugInfoRow(title: "Router", value: "V6 (0x1111...)")
                    DebugInfoRow(title: "From", value: "0.01 WMATIC")
                    DebugInfoRow(title: "To", value: "0.01 USDC")
                    DebugInfoRow(title: "Type", value: "Limit Order")
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Spacer()
                
                // Execute button
                Button(action: executeTestTransaction) {
                    HStack {
                        if routerManager.isExecuting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        
                        Text(routerManager.isExecuting ? "Executing..." : "Execute Test Transaction")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(routerManager.isExecuting ? Color.gray : Color.purple)
                    .cornerRadius(12)
                }
                .disabled(routerManager.isExecuting)
                
                if !routerManager.executionLog.isEmpty {
                    ScrollView {
                        Text(routerManager.executionLog)
                            .font(.system(.caption, design: .monospaced))
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    }
                    .frame(maxHeight: 200)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Debug")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func executeTestTransaction() {
        Task {
            await routerManager.executeTestTransaction()
        }
    }
}

struct DebugInfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
    }
}

#Preview {
    DebugView()
}