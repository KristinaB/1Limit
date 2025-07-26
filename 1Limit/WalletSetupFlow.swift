//
//  WalletSetupFlow.swift
//  1Limit
//
//  Stack-based navigation flow for wallet setup wizard
//

import SwiftUI

struct WalletSetupFlow: View {
    @Binding var selectedTab: Int
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            BackupPhraseView(useStackNavigation: true, onComplete: {
                // Switch to Trade tab when complete
                dismiss()
                selectedTab = 1
            })
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    WalletSetupFlow(selectedTab: .constant(0))
}