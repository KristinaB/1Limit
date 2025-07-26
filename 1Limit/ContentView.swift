//
//  ContentView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct ContentView: View {
    
    var body: some View {
        NavigationView {
            ZStack {
                // Dark background
                Color.appBackground
                    .ignoresSafeArea()
                
                TabView {
                    HomeView()
                        .tabItem {
                            Image(systemName: "house.fill")
                            Text("Home")
                        }
                    
                    TradeView()
                        .tabItem {
                            Image(systemName: "arrow.left.arrow.right")
                            Text("Trade")
                        }
                    
                    TransactionsView()
                        .tabItem {
                            Image(systemName: "list.bullet")
                            Text("Transactions")
                        }
                }
                .background(Color.appBackground)
            }
            .toolbarBackground(Color.appBackground, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
}
