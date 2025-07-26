//
//  DebugView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct DebugView: View {
    @State private var isExecuting = false
    @State private var executionResult = ""
    @State private var showingResult = false
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
                        if isExecuting {
                            ProgressView()
                                .scaleEffect(0.8)
                                .foregroundColor(.white)
                        } else {
                            Image(systemName: "play.circle.fill")
                                .font(.title2)
                        }
                        
                        Text(isExecuting ? "Executing..." : "Execute Test Transaction")
                            .font(.headline)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(isExecuting ? Color.gray : Color.purple)
                    .cornerRadius(12)
                }
                .disabled(isExecuting)
                
                if !executionResult.isEmpty {
                    ScrollView {
                        Text(executionResult)
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
        isExecuting = true
        executionResult = ""
        
        Task {
            await performDebugExecution()
        }
    }
    
    @MainActor
    private func performDebugExecution() async {
        var result = "🚀 1inch Router V6 Debug Execution\n"
        result += "====================================\n\n"
        
        // Simulate the execution steps from the ported Go code
        result += "📋 Step 1: Generating order parameters...\n"
        await Task.sleep(1_000_000_000) // 1 second
        
        result += "🧂 Generated salt: 0x1234567890abcdef\n"
        result += "📦 Generated nonce: 0x9876543210\n"
        result += "🎛️ Calculated MakerTraits: 0xabcdef1234567890\n\n"
        
        result += "📋 Step 2: Creating EIP-712 domain...\n"
        await Task.sleep(1_000_000_000)
        
        result += "🌐 Domain name: 1inch Aggregation Router\n"
        result += "📊 Version: 6\n"
        result += "⛓️ Chain ID: 137 (Polygon)\n"
        result += "📄 Contract: 0x111111125421cA6dc452d289314280a0f8842A65\n\n"
        
        result += "📋 Step 3: Signing Router V6 order...\n"
        await Task.sleep(1_000_000_000)
        
        result += "🔐 EIP-712 signature generated\n"
        result += "🔧 Converting to EIP-2098 compact format\n"
        result += "✅ Signature ready for submission\n\n"
        
        result += "📋 Step 4: Preparing transaction...\n"
        await Task.sleep(1_000_000_000)
        
        result += "📊 Method: fillOrder(order, r, vs, amount, takerTraits)\n"
        result += "⛽ Gas limit: 300000\n"
        result += "💰 Gas price: Auto (20% boost)\n\n"
        
        result += "📋 Step 5: Submitting to network...\n"
        await Task.sleep(2_000_000_000)
        
        // Simulate success
        let mockTxHash = "0x" + String((0..<64).map { _ in "0123456789abcdef".randomElement()! })
        result += "✅ Transaction submitted successfully!\n"
        result += "🔗 TX Hash: \(mockTxHash)\n"
        result += "⏳ Status: Pending confirmation...\n\n"
        
        result += "🎉 Debug execution completed!\n"
        result += "💡 This was a simulation using the ported 1inch Router V6 SDK 🤖❤️🎉\n"
        
        executionResult = result
        isExecuting = false
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