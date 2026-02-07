//
//  StatusBadge.swift
//  MintCheck
//
//  Status indicator badges for scan results
//

import SwiftUI

struct StatusBadge: View {
    let recommendation: RecommendationType
    var size: BadgeSize = .large
    
    enum BadgeSize {
        case small   // For list items
        case large   // For results header
    }
    
    var body: some View {
        HStack(spacing: size == .large ? 16 : 8) {
            // Icon
            iconView
            
            if size == .large {
                // Full text for large badge
                VStack(alignment: .leading, spacing: 4) {
                    Text(recommendation.title)
                        .font(.system(size: FontSize.h2, weight: .semibold))
                        .foregroundColor(statusColors.primary)
                }
            } else {
                // Compact text for small badge
                Text(recommendation.title)
                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                    .foregroundColor(statusColors.primary)
            }
        }
        .padding(size == .large ? LayoutConstants.padding6 : LayoutConstants.padding3)
        .frame(maxWidth: size == .large ? .infinity : nil, alignment: .leading)
        .background(statusColors.background)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(statusColors.primary, lineWidth: size == .large ? 2 : 1)
        )
    }
    
    @ViewBuilder
    private var iconView: some View {
        let iconSize: CGFloat = size == .large ? 48 : 24
        let symbolSize: CGFloat = size == .large ? 24 : 12
        
        ZStack {
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .fill(statusColors.primary)
                .frame(width: iconSize, height: iconSize)
            
            Image(systemName: recommendation.iconName)
                .font(.system(size: symbolSize, weight: .semibold))
                .foregroundColor(.white)
        }
    }
    
    private var statusColors: StatusColors {
        StatusColors.forRecommendation(recommendation)
    }
}

// MARK: - Status Dot (for system details)
struct StatusDot: View {
    let status: SystemStatus
    
    enum SystemStatus {
        case good
        case needsAttention
        
        var color: Color {
            switch self {
            case .good: return .statusSafe
            case .needsAttention: return .statusCaution
            }
        }
        
        var label: String {
            switch self {
            case .good: return "Good"
            case .needsAttention: return "Needs Attention"
            }
        }
    }
    
    var body: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(status.color)
                .frame(width: 8, height: 8)
            
            Text(status.label)
                .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Info Card
struct InfoCard: View {
    let text: String
    var icon: String? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if let iconName = icon {
                Image(systemName: iconName)
                    .font(.system(size: 16))
                    .foregroundColor(.textSecondary)
            }
            
            Text(text)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
        .padding(LayoutConstants.padding4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.softBackground)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 24) {
        StatusBadge(recommendation: .safe, size: .large)
        StatusBadge(recommendation: .caution, size: .large)
        StatusBadge(recommendation: .notRecommended, size: .large)
        
        HStack {
            StatusBadge(recommendation: .safe, size: .small)
            StatusBadge(recommendation: .caution, size: .small)
        }
        
        HStack {
            StatusDot(status: .good)
            StatusDot(status: .needsAttention)
        }
        
        InfoCard(
            text: "This check reviews the car's systems. Other inspections may be needed.",
            icon: "info.circle"
        )
    }
    .padding()
    .background(Color.deepBackground)
}
