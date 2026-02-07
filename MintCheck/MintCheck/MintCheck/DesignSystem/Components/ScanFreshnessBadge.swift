//
//  ScanFreshnessBadge.swift
//  MintCheck
//
//  Displays scan age to help sellers show credibility
//

import SwiftUI

// MARK: - Scan Freshness Model

enum ScanFreshness: Equatable {
    case current(daysOld: Int)      // 1-10 days (was "fresh")
    case expiresSoon(daysOld: Int)  // 11-14 days (was "aging")
    case expired(daysOld: Int)      // 15+ days (was "outdated")
    case unknown
    
    var label: String {
        switch self {
        case .current: return "Current"
        case .expiresSoon: return "Expires Soon"
        case .expired: return "Expired"
        case .unknown: return "Unknown"
        }
    }
    
    var daysOld: Int? {
        switch self {
        case .current(let days), .expiresSoon(let days), .expired(let days):
            return days
        case .unknown:
            return nil
        }
    }
    
    var primaryColor: Color {
        switch self {
        case .current: return Color(hex: "#2D7A5E")  // Muted green
        case .expiresSoon: return Color(hex: "#9A7B2C")  // Muted amber
        case .expired: return Color(hex: "#9A3A3A")  // Muted red
        case .unknown: return .textSecondary
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .current: return Color(hex: "#E6F4EE")  // Light green
        case .expiresSoon: return Color(hex: "#FFF8E6")  // Light amber
        case .expired: return Color(hex: "#FFE6E6")  // Light red
        case .unknown: return Color(hex: "#F0F0F0")
        }
    }
}

// MARK: - Freshness Calculator

func computeScanFreshness(scanCompletedAt: Date?, now: Date = Date()) -> ScanFreshness {
    guard let scanDate = scanCompletedAt else {
        return .unknown
    }
    
    let calendar = Calendar.current
    let components = calendar.dateComponents([.day], from: scanDate, to: now)
    let daysOld = max(0, components.day ?? 0)  // Guard against negative (future dates)
    
    switch daysOld {
    case 0...10:
        return .current(daysOld: daysOld)
    case 11...14:
        return .expiresSoon(daysOld: daysOld)
    default:
        return .expired(daysOld: daysOld)
    }
}

// Calculate expiry date (scan date + 14 days)
func computeExpiryDate(scanCompletedAt: Date?) -> Date? {
    guard let scanDate = scanCompletedAt else { return nil }
    return Calendar.current.date(byAdding: .day, value: 14, to: scanDate)
}

// Format expiry date for display
func formatExpiryDate(_ date: Date?) -> String? {
    guard let date = date else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "MMMM d, yyyy"  // e.g., "January 26, 2026"
    return formatter.string(from: date)
}

// MARK: - Date Formatter

func formatScanDate(_ date: Date?) -> String? {
    guard let date = date else { return nil }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "MMM d, yyyy"  // e.g., "Jan 26, 2026"
    return "Run \(formatter.string(from: date))"
}

// MARK: - Scan Freshness Badge View

struct ScanFreshnessBadge: View {
    let freshness: ScanFreshness
    var showExpiryDate: Bool = false
    var scannedAt: Date? = nil
    var compact: Bool = false
    
    private var expiryDate: Date? {
        computeExpiryDate(scanCompletedAt: scannedAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: compact ? 0 : 6) {
            // Badge pill with expiry info
            HStack(spacing: 8) {
                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(freshness.primaryColor)
                        .frame(width: 6, height: 6)
                    
                    Text(freshness.label)
                        .font(.system(size: compact ? 11 : 12, weight: .semibold))
                        .foregroundColor(freshness.primaryColor)
                }
                .padding(.horizontal, compact ? 8 : 10)
                .padding(.vertical, compact ? 4 : 5)
                .background(freshness.backgroundColor)
                .clipShape(Capsule())
                
                // Expiry date (shown in header, not compact mode)
                if showExpiryDate, !compact, let expiry = expiryDate, let expiryText = formatExpiryDate(expiry) {
                    Text("Report expires on \(expiryText)")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        Text("Compact (for lists)")
            .font(.headline)
        
        HStack(spacing: 12) {
            ScanFreshnessBadge(freshness: .current(daysOld: 2), compact: true)
            ScanFreshnessBadge(freshness: .expiresSoon(daysOld: 12), compact: true)
            ScanFreshnessBadge(freshness: .expired(daysOld: 20), compact: true)
            ScanFreshnessBadge(freshness: .unknown, compact: true)
        }
        
        Divider()
        
        Text("With Expiry Date (for report header)")
            .font(.headline)
        
        VStack(alignment: .leading, spacing: 16) {
            ScanFreshnessBadge(
                freshness: .current(daysOld: 0),
                showExpiryDate: true,
                scannedAt: Date()
            )
            
            ScanFreshnessBadge(
                freshness: .current(daysOld: 5),
                showExpiryDate: true,
                scannedAt: Calendar.current.date(byAdding: .day, value: -5, to: Date())
            )
            
            ScanFreshnessBadge(
                freshness: .expiresSoon(daysOld: 12),
                showExpiryDate: true,
                scannedAt: Calendar.current.date(byAdding: .day, value: -12, to: Date())
            )
            
            ScanFreshnessBadge(
                freshness: .expired(daysOld: 20),
                showExpiryDate: true,
                scannedAt: Calendar.current.date(byAdding: .day, value: -20, to: Date())
            )
        }
    }
    .padding()
}
