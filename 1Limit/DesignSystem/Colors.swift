//
//  Colors.swift
//  1Limit
//
//  Centralized color palette for dark theme design 🎨✨
//

import SwiftUI

extension Color {
    // MARK: - App Colors
    
    /// App background colors
    static let appBackground = Color.black
    static let cardBackground = Color(red: 0.1, green: 0.1, blue: 0.1)
    static let inputBackground = Color(red: 0.15, green: 0.15, blue: 0.15)
    
    /// Text colors
    static let primaryText = Color.white
    static let secondaryText = Color(red: 0.7, green: 0.7, blue: 0.7)
    static let tertiaryText = Color(red: 0.5, green: 0.5, blue: 0.5)
    
    /// Button gradients
    static let primaryGradientStart = Color.blue
    static let primaryGradientEnd = Color.purple.opacity(0.8)
    
    /// Border colors
    static let borderGray = Color(red: 0.3, green: 0.3, blue: 0.3)
    static let borderLight = Color(red: 0.4, green: 0.4, blue: 0.4)
    
    /// Status colors
    static let successGreen = Color.green
    static let warningOrange = Color.orange
    static let errorRed = Color.red
    
    /// Chart colors
    static let bullishGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let bearishRed = Color(red: 0.8, green: 0.3, blue: 0.3)
}

// MARK: - Gradients

extension LinearGradient {
    /// Primary button gradient (blue to purple)
    static let primaryButton = LinearGradient(
        colors: [Color.primaryGradientStart, Color.primaryGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )
    
    /// Card background gradient
    static let cardBackground = LinearGradient(
        colors: [
            Color.cardBackground,
            Color.cardBackground.opacity(0.8)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}