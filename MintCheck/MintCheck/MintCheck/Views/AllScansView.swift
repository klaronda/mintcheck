//
//  AllScansView.swift
//  MintCheck
//
//  Full scan history with monthly grouping
//

import SwiftUI

struct AllScansView: View {
    let onViewScan: (String) -> Void
    let onBack: () -> Void
    
    @EnvironmentObject var scanService: ScanService
    
    /// Group scans by month (e.g., "January 2026")
    var groupedScans: [(String, [ScanHistoryItem])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        // Group by month string
        var groups: [String: [ScanHistoryItem]] = [:]
        for scan in scanService.scanHistory {
            let monthKey = formatter.string(from: scan.date)
            if groups[monthKey] == nil {
                groups[monthKey] = []
            }
            groups[monthKey]?.append(scan)
        }
        
        // Sort groups by date (most recent first)
        // We need to parse back to compare dates
        let sortedKeys = groups.keys.sorted { key1, key2 in
            guard let date1 = groups[key1]?.first?.date,
                  let date2 = groups[key2]?.first?.date else {
                return false
            }
            return date1 > date2
        }
        
        return sortedKeys.map { key in
            (key, groups[key] ?? [])
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                        Text("Back")
                            .font(.system(size: FontSize.bodyLarge, weight: .medium))
                    }
                    .foregroundColor(.mintGreen)
                }
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.borderColor),
                alignment: .bottom
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Title and description
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your Vehicle Scans")
                            .font(.system(size: FontSize.h2, weight: .bold))
                            .foregroundColor(.textPrimary)
                        
                        Text("Review all your vehicle scans for up to 180 days. To keep scans beyond that time, export the scans you want to PDF with the share button.")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Grouped scans
                    if groupedScans.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.text.magnifyingglass")
                                .font(.system(size: 48))
                                .foregroundColor(.textMuted)
                            
                            Text("No scans yet")
                                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                .foregroundColor(.textSecondary)
                            
                            Text("Start a Mint Check to scan your first vehicle.")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.textMuted)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 48)
                    } else {
                        ForEach(groupedScans, id: \.0) { monthYear, scans in
                            VStack(alignment: .leading, spacing: 12) {
                                // Month header
                                Text(monthYear)
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                
                                // Scans for this month
                                VStack(spacing: 10) {
                                    ForEach(scans) { scan in
                                        ScanHistoryCard(item: scan) {
                                            onViewScan(scan.id.uuidString)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.deepBackground)
    }
}

#Preview {
    AllScansView(onViewScan: { _ in }, onBack: {})
        .environmentObject(ScanService())
}
