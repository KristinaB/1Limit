//
//  Typography.swift
//  1Limit
//
//  Consistent typography styles for dark theme 📝✨
//

import SwiftUI

// MARK: - Text Extensions

extension Text {
    /// Large title with primary color
    func appTitle() -> some View {
        self
            .font(.largeTitle)
            .fontWeight(.bold)
            .foregroundColor(.primaryText)
    }
    
    /// Section title
    func sectionTitle() -> some View {
        self
            .font(.title2)
            .fontWeight(.semibold)
            .foregroundColor(.primaryText)
    }
    
    /// Card title
    func cardTitle() -> some View {
        self
            .font(.headline)
            .foregroundColor(.primaryText)
    }
    
    /// Body text
    func bodyText() -> some View {
        self
            .font(.body)
            .foregroundColor(.primaryText)
    }
    
    /// Secondary text
    func secondaryText() -> some View {
        self
            .font(.subheadline)
            .foregroundColor(.secondaryText)
    }
    
    /// Caption text
    func captionText() -> some View {
        self
            .font(.caption)
            .foregroundColor(.tertiaryText)
    }
    
    /// Price text with formatting
    func priceText(color: Color = .primaryText) -> some View {
        self
            .font(.headline)
            .fontWeight(.medium)
            .foregroundColor(color)
    }
    
    /// Status text
    func statusText(status: StatusType) -> some View {
        self
            .font(.caption)
            .fontWeight(.medium)
            .foregroundColor(status.color)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(status.color.opacity(0.2))
            )
    }
}

// MARK: - Status Types

enum StatusType {
    case success, warning, error, pending, neutral
    
    var color: Color {
        switch self {
        case .success:
            return .successGreen
        case .warning:
            return .warningOrange
        case .error:
            return .errorRed
        case .pending:
            return .primaryGradientStart
        case .neutral:
            return .secondaryText
        }
    }
}