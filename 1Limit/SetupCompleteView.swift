//
//  SetupCompleteView.swift
//  1Limit
//
//  Success screen after wallet creation completion ✅🎉
//

import SwiftUI

struct SetupCompleteView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showLoadFunds = false
    
    var body: some View {
        ZStack {
            Color.appBackground
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Success icon
                VStack(spacing: 24) {
                    PrimaryButton("✓") {
                        // Icon button - no action needed
                    }
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .disabled(true)
                    
                    Text("You're All Set!")
                        .appTitle()
                    
                    Text("Your wallet has been created successfully. You can now load funds and start trading.")
                        .secondaryText()
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 20)
                }
                
                Spacer()
                
                // Action button
                VStack(spacing: 16) {
                    PrimaryButton("Load Funds") {
                        showLoadFunds = true
                    }
                    
                    SecondaryButton("Skip for Now") {
                        // Skip to main app - could navigate to ContentView
                        dismiss()
                    }
                }
                .padding(.horizontal, 20)
                
                Spacer(minLength: 40)
            }
        }
        .fullScreenCover(isPresented: $showLoadFunds) {
            LoadFundsView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    SetupCompleteView()
}