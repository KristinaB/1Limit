//
//  ContentView.swift
//  1Limit
//
//  Created by KristinaB on 26/07/2025.
//

import SwiftUI

struct ContentView: View {
    @State private var showingDebug = false
    
    var body: some View {
        NavigationView {
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Debug") {
                        showingDebug = true
                    }
                    .foregroundColor(.purple)
                }
            }
            .sheet(isPresented: $showingDebug) {
                DebugView()
            }
        }
    }
}

#Preview {
    ContentView()
}
