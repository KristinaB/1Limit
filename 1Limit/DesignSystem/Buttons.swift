//
//  Buttons.swift
//  1Limit
//
//  Reusable button components with glass effects and gradients 🦄💎
//

import SwiftUI

// MARK: - Primary Button

struct PrimaryButton: View {
    let title: String
    let action: () -> Void
    let icon: String?
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.primaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Glass effect background with translucent white
                    RoundedRectangle(cornerRadius: 25)
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
                    
                    // Subtle blue glow overlay
                    RoundedRectangle(cornerRadius: 25)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.1),
                                    Color.purple.opacity(0.05),
                                    Color.clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    // Glass highlight on top edge
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.4),
                                    Color.white.opacity(0.1),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
                .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
                .shadow(color: Color.white.opacity(0.1), radius: 2, x: 0, y: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Secondary Button

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    let icon: String?
    
    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                }
                Text(title)
            }
            .font(.headline)
            .foregroundColor(.secondaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                ZStack {
                    // Background with subtle fill
                    RoundedRectangle(cornerRadius: 25)
                        .fill(Color.inputBackground)
                    
                    // Glass effect overlay
                    RoundedRectangle(cornerRadius: 25)
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
                    
                    // Grey border with inset shadow
                    RoundedRectangle(cornerRadius: 25)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.borderLight.opacity(0.6),
                                    Color.borderGray.opacity(0.3),
                                    Color.black.opacity(0.2)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            ),
                            lineWidth: 1
                        )
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Small Button

struct SmallButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    
    enum ButtonStyle {
        case primary, secondary
    }
    
    init(_ title: String, style: ButtonStyle = .primary, action: @escaping () -> Void) {
        self.title = title
        self.style = style
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(style == .primary ? .primaryText : .secondaryText)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    ZStack {
                        if style == .primary {
                            // Glass effect for primary buttons
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            Color.white.opacity(0.3),
                                            Color.white.opacity(0.2),
                                            Color.white.opacity(0.15)
                                        ],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    Color.blue.opacity(0.15),
                                                    Color.purple.opacity(0.08),
                                                    Color.clear
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                                .overlay(
                                    Capsule()
                                        .strokeBorder(
                                            LinearGradient(
                                                colors: [
                                                    Color.white.opacity(0.5),
                                                    Color.white.opacity(0.2),
                                                    Color.clear
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            ),
                                            lineWidth: 0.5
                                        )
                                )
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)
                                .shadow(color: Color.white.opacity(0.15), radius: 1, x: 0, y: 0.5)
                        } else {
                            Capsule()
                                .fill(Color.inputBackground)
                                .overlay(
                                    Capsule()
                                        .strokeBorder(Color.borderGray, lineWidth: 1)
                                )
                        }
                    }
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}