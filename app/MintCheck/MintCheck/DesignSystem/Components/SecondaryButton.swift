//
//  SecondaryButton.swift
//  MintCheck
//
//  Secondary/outlined button component
//

import SwiftUI

struct SecondaryButton: View {
    let title: String
    let action: () -> Void
    var style: SecondaryButtonStyle = .outlined
    
    enum SecondaryButtonStyle {
        case outlined      // White background with border
        case filled        // White filled (for dark backgrounds)
        case text          // Text only (no background/border)
    }
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .buttonTextStyle()
                .foregroundColor(textColor)
                .frame(maxWidth: .infinity)
                .frame(height: LayoutConstants.buttonHeight)
                .background(backgroundColor)
                .cornerRadius(LayoutConstants.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .stroke(borderColor, lineWidth: style == .outlined ? 1 : 0)
                )
        }
    }
    
    private var textColor: Color {
        switch style {
        case .outlined, .filled:
            return .textPrimary
        case .text:
            return .textSecondary
        }
    }
    
    private var backgroundColor: Color {
        switch style {
        case .outlined:
            return .white
        case .filled:
            return .white.opacity(0.95)
        case .text:
            return .clear
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outlined:
            return .borderColor
        case .filled, .text:
            return .clear
        }
    }
}

// MARK: - Text Button (for "Skip" actions)
struct TextButton: View {
    let title: String
    let action: () -> Void
    var color: Color = .textSecondary
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(color)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SecondaryButton(title: "Create Account", action: {}, style: .filled)
        SecondaryButton(title: "Outlined Button", action: {}, style: .outlined)
        TextButton(title: "Skip this step", action: {})
    }
    .padding()
    .background(Color.deepBackground)
}
