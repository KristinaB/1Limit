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
                            .frame(width: 120, height: 120)
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
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 50, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
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
                    
                    SecondaryButton("Start Trading") {
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