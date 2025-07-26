//
//  Cards.swift
//  1Limit
//
//  Reusable card components with dark theme and glass effects 🌟✨
//

import SwiftUI

// MARK: - App Card

struct AppCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(
                ZStack {
                    // Main card background
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.cardBackground)
                    
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.05),
                                    Color.clear,
                                    Color.black.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Subtle border
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.borderLight.opacity(0.3),
                                    Color.borderGray.opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                }
            )
    }
}

// MARK: - Info Card

struct InfoCard: View {
    let title: String
    let items: [(String, String, Color?)]
    
    init(title: String, items: [(String, String, Color?)] = []) {
        self.title = title
        self.items = items
    }
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.primaryText)
                
                VStack(spacing: 12) {
                    ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                        InfoRow(title: item.0, value: item.1, color: item.2)
                    }
                }
            }
        }
    }
}

// MARK: - Info Row

struct InfoRow: View {
    let title: String
    let value: String
    let color: Color?
    
    init(title: String, value: String, color: Color? = nil) {
        self.title = title
        self.value = value
        self.color = color
    }
    
    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondaryText)
            
            Spacer()
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(color ?? .primaryText)
        }
    }
}

// MARK: - Input Card

struct InputCard<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 16) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.secondaryText)
                
                content
            }
        }
    }
}

// MARK: - List Item Card

struct ListItemCard<Content: View>: View {
    let content: Content
    
    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.cardBackground)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
                    
                    // Subtle glass effect
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.02),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
    }
}