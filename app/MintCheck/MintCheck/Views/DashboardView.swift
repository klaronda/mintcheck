//
//  DashboardView.swift
//  MintCheck
//
//  Main dashboard with scan history
//

import SwiftUI

struct DashboardView: View {
    let onStartCheck: () -> Void
    let onViewHistory: (String) -> Void
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var scanService: ScanService
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo header
            LogoHeader()
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Welcome message
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Welcome back, \(authService.currentUser?.displayName ?? "there")!")
                            .font(.system(size: FontSize.h2, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("Ready to check another vehicle?")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Start scan button
                    PrimaryButton(
                        title: "Start New Scan",
                        action: onStartCheck
                    )
                    
                    // Recent scans
                    if !scanService.scanHistory.isEmpty {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Recent Scans")
                                .font(.system(size: FontSize.h4, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            ForEach(scanService.scanHistory) { scan in
                                ScanHistoryCard(item: scan) {
                                    onViewHistory(scan.id.uuidString)
                                }
                            }
                        }
                    } else {
                        // Empty state
                        EmptyStateView()
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.deepBackground)
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        guard let userId = authService.currentUser?.id else { return }
        Task {
            try? await scanService.loadScanHistory(userId: userId)
        }
    }
}

// MARK: - Scan History Card
struct ScanHistoryCard: View {
    let item: ScanHistoryItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.vehicle)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(item.formattedDate)
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                // Status badge
                StatusBadge(recommendation: item.recommendation, size: .small)
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.textMuted)
            }
            .padding(LayoutConstants.padding4)
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "car.fill")
                .font(.system(size: 48))
                .foregroundColor(.textMuted)
            
            Text("No scans yet")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text("Start your first vehicle scan to see your results here.")
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
        .padding(.horizontal, 32)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

#Preview {
    DashboardView(onStartCheck: {}, onViewHistory: { _ in })
        .environmentObject(AuthService())
        .environmentObject(ScanService())
}
