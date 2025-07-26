//
//  TextFields.swift
//  1Limit
//
//  Custom text fields with dark theme styling 🌙✨
//

import SwiftUI

// MARK: - App Text Field

struct AppTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isDisabled: Bool
    
    init(_ placeholder: String, text: Binding<String>, keyboardType: UIKeyboardType = .default, isDisabled: Bool = false) {
        self.placeholder = placeholder
        self._text = text
        self.keyboardType = keyboardType
        self.isDisabled = isDisabled
    }
    
    var body: some View {
        TextField(placeholder, text: $text)
            .keyboardType(keyboardType)
            .disabled(isDisabled)
            .padding(16)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.inputBackground)
                    
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            LinearGradient(
                                colors: [
                                    Color.borderGray.opacity(0.5),
                                    Color.borderGray.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                    
                    // Glass effect
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.03),
                                    Color.clear
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                }
            )
            .foregroundColor(isDisabled ? .tertiaryText : .primaryText)
            .font(.body)
    }
}

// MARK: - App Picker

struct AppPicker<SelectionValue: Hashable>: View {
    let title: String
    @Binding var selection: SelectionValue
    let options: [(SelectionValue, String)]
    
    init(_ title: String, selection: Binding<SelectionValue>, options: [(SelectionValue, String)]) {
        self.title = title
        self._selection = selection
        self.options = options
    }
    
    var body: some View {
        Picker(title, selection: $selection) {
            ForEach(options, id: \.0) { value, label in
                Text(label).tag(value)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.inputBackground)
                
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderGray.opacity(0.3), lineWidth: 1)
                
                // Glass effect
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.03),
                                Color.clear
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .foregroundColor(.primaryText)
        .fixedSize()
    }
}