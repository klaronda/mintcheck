//
//  Typography.swift
//  MintCheck
//
//  Typography styles and text modifiers
//

import SwiftUI

// MARK: - Font Sizes
struct FontSize {
    // Headings
    static let h1: CGFloat = 26
    static let h2: CGFloat = 22
    static let h3: CGFloat = 18
    static let h4: CGFloat = 17
    static let h5: CGFloat = 16
    
    // Body
    static let bodyLarge: CGFloat = 15
    static let bodyRegular: CGFloat = 14
    static let bodySmall: CGFloat = 13
    
    // Special
    static let button: CGFloat = 16
    static let caption: CGFloat = 11
}

// MARK: - Text Style Modifiers
extension View {
    func h1Style() -> some View {
        self
            .font(.system(size: FontSize.h1, weight: .semibold))
            .foregroundColor(.textPrimary)
    }
    
    func h2Style() -> some View {
        self
            .font(.system(size: FontSize.h2, weight: .semibold))
            .foregroundColor(.textPrimary)
    }
    
    func h3Style() -> some View {
        self
            .font(.system(size: FontSize.h3, weight: .semibold))
            .foregroundColor(.textPrimary)
    }
    
    func h4Style() -> some View {
        self
            .font(.system(size: FontSize.h4, weight: .semibold))
            .foregroundColor(.textPrimary)
    }
    
    func bodyLargeStyle() -> some View {
        self
            .font(.system(size: FontSize.bodyLarge))
            .foregroundColor(.textPrimary)
    }
    
    func bodyRegularStyle() -> some View {
        self
            .font(.system(size: FontSize.bodyRegular))
            .foregroundColor(.textSecondary)
    }
    
    func bodySmallStyle() -> some View {
        self
            .font(.system(size: FontSize.bodySmall))
            .foregroundColor(.textSecondary)
    }
    
    func buttonTextStyle() -> some View {
        self
            .font(.system(size: FontSize.button, weight: .semibold))
    }
}

// MARK: - Layout Constants
struct LayoutConstants {
    // Border radius
    static let borderRadius: CGFloat = 4
    static let borderRadiusLarge: CGFloat = 8
    
    // Button heights
    static let buttonHeight: CGFloat = 48
    static let buttonHeightSmall: CGFloat = 44
    
    // Max widths
    static let maxWidthMobile: CGFloat = 448  // 28rem
    static let maxWidthWide: CGFloat = 672    // 42rem
    
    // Padding
    static let padding2: CGFloat = 8
    static let padding3: CGFloat = 12
    static let padding4: CGFloat = 16
    static let padding5: CGFloat = 20
    static let padding6: CGFloat = 24
    static let padding8: CGFloat = 32
    
    // Spacing
    static let spacingXS: CGFloat = 4
    static let spacingSM: CGFloat = 8
    static let spacingMD: CGFloat = 16
    static let spacingLG: CGFloat = 24
    static let spacingXL: CGFloat = 32
}
