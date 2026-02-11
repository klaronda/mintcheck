//
//  TabBar.swift
//  MintCheck
//
//  Bottom navigation tab bar
//

import SwiftUI

/// Tab items for bottom navigation
enum TabItem: Hashable {
    case home
    case scan
    case help
    case settings
    // Menu-only items (not in bottom tab bar)
    case scanHistory
    case deepCheckReports
    
    /// The four tabs shown in the bottom tab bar
    static let bottomBarTabs: [TabItem] = [.home, .scan, .settings, .help]
    
    var title: String {
        switch self {
        case .home: return "Home"
        case .scan: return "Scan"
        case .help: return "Support"
        case .settings: return "Settings"
        case .scanHistory: return "History"
        case .deepCheckReports: return "Deep Check Reports"
        }
    }
    
    var iconName: String {
        switch self {
        case .home: return "icon-nav-home"
        case .scan: return "icon-nav-scan"
        case .help: return "icon-nav-support"
        case .settings: return "icon-nav-settings"
        case .scanHistory: return "icon-scan-history"
        case .deepCheckReports: return "DeepCheck_mint"
        }
    }
}

/// Bottom navigation tab bar
struct TabBar: View {
    @Binding var selectedTab: TabItem
    let onTabSelected: (TabItem) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.bottomBarTabs, id: \.self) { tab in
                TabBarItem(
                    tab: tab,
                    isSelected: selectedTab == tab,
                    action: {
                        selectedTab = tab
                        onTabSelected(tab)
                    }
                )
            }
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.borderColor),
            alignment: .top
        )
    }
}

/// Individual tab bar item with icon and label
struct TabBarItem: View {
    let tab: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                // Icon with optional background when selected
                if isSelected {
                    Image(tab.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.deepBackground)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                } else {
                    Image(tab.iconName)
                        .renderingMode(.template)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 28, height: 28)
                        .foregroundColor(.textSecondary)
                }
                
                Text(tab.title)
                    .font(.system(size: 11, weight: isSelected ? .semibold : .regular))
                    .foregroundColor(isSelected ? .textPrimary : .textSecondary)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    VStack {
        Spacer()
        TabBar(
            selectedTab: .constant(.home),
            onTabSelected: { _ in }
        )
    }
    .background(Color.deepBackground)
}
