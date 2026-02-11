//
//  Colors.swift
//  MintCheck
//
//  Brand colors and design tokens
//

import SwiftUI

extension Color {
    // MARK: - Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - MintCheck Brand Colors
extension Color {
    // Primary Brand Color
    static let mintGreen = Color(hex: "#3EB489")
    static let mintGreenHover = Color(hex: "#2D9970")
    
    // Backgrounds
    static let deepBackground = Color(hex: "#F8F8F7")
    static let softBackground = Color(hex: "#FCFCFB")
    static let cardBackground = Color.white
    
    // Text Colors
    static let textPrimary = Color(hex: "#1A1A1A")
    static let textSecondary = Color(hex: "#666666")
    static let textMuted = Color(hex: "#999999")
    
    // Borders
    static let borderColor = Color(hex: "#E5E5E5")
    
    // Status Colors
    static let statusSafe = Color(hex: "#3EB489")
    static let statusSafeBg = Color(hex: "#E6F4EE")
    static let statusCaution = Color(hex: "#E3B341")
    static let statusCautionBg = Color(hex: "#FFF9E6")
    static let statusDanger = Color(hex: "#C94A4A")
    static let statusDangerBg = Color(hex: "#FFE6E6")
    static let statusInfo = Color(hex: "#4A90C9")
    static let statusInfoBg = Color(hex: "#E6F0FA")
    static let statusWarning = Color(hex: "#F59E0B")
    
    // Dark mode specific
    static let darkBackground = Color(hex: "#1A1A1A")
}

// MARK: - Status Color Helper
struct StatusColors {
    let primary: Color
    let background: Color
    
    static func forRecommendation(_ type: RecommendationType) -> StatusColors {
        switch type {
        case .safe:
            return StatusColors(primary: .statusSafe, background: .statusSafeBg)
        case .lowData:
            return StatusColors(primary: .statusInfo, background: .statusInfoBg)
        case .caution:
            return StatusColors(primary: .statusCaution, background: .statusCautionBg)
        case .notRecommended:
            return StatusColors(primary: .statusDanger, background: .statusDangerBg)
        }
    }
}
