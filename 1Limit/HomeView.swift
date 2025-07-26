//
//  HomeView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Image(systemName: "house.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                Text("Welcome to 1Limit")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Your 1inch Router V6 Wallet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 12) {
                    WalletInfoRow(title: "Network", value: "Polygon Mainnet")
                    WalletInfoRow(title: "Router Version", value: "V6")
                    WalletInfoRow(title: "Status", value: "Ready", color: .green)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                Text("Use the Trade tab to create limit orders 🚀")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 40)
            }
            .padding()
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct WalletInfoRow: View {
    let title: String
    let value: String
    var color: Color = .primary
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color)
        }
    }
}

#Preview {
    HomeView()
}