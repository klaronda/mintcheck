//
//  ErrorHandlingComponents.swift
//  MintCheck
//
//  InlineAlert, TroubleshootSheet, OfflineBanner, ReportStatusBadge for error handling & offline fallback.
//

import SwiftUI

// MARK: - InlineAlert

enum InlineAlertType {
    case info
    case warning
    case error

    var icon: String {
        switch self {
        case .info: return "info.circle.fill"
        case .warning: return "exclamationmark.triangle.fill"
        case .error: return "xmark.circle.fill"
        }
    }

    var iconColor: Color {
        switch self {
        case .info: return .mintGreen
        case .warning: return .statusCaution
        case .error: return .statusDanger
        }
    }

    var backgroundColor: Color {
        switch self {
        case .info: return .statusSafeBg
        case .warning: return .statusCautionBg
        case .error: return .statusDangerBg
        }
    }
}

struct InlineAlert: View {
    let type: InlineAlertType
    let title: String
    let message: String
    let actions: [(title: String, action: () -> Void)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: type.icon)
                    .font(.system(size: 20))
                    .foregroundColor(type.iconColor)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(message)
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                }
                Spacer(minLength: 0)
            }
            if !actions.isEmpty {
                HStack(spacing: 12) {
                    ForEach(Array(actions.enumerated()), id: \.offset) { _, item in
                        Button(action: item.action) {
                            Text(item.title)
                                .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                                .foregroundColor(.mintGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(LayoutConstants.padding4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(type.backgroundColor)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(type.iconColor, lineWidth: 1)
        )
    }
}

// MARK: - TroubleshootSheet

struct TroubleshootSheet: View {
    let onDismiss: () -> Void
    let onNeedHelp: (() -> Void)?

    private let steps: [(title: String, body: String)] = [
        ("Make sure the scanner is plugged in", "The OBD-II port is usually under the dashboard on the driver's side. The scanner should power on when the vehicle's ignition is on."),
        ("Check the scanner's Wi‑Fi", "Many scanners create a Wi‑Fi network (e.g. OBDII, Veepeak). Ensure the scanner is powered and broadcasting."),
        ("Try connecting manually", "Open Settings → Wi‑Fi and connect to the scanner's network, then return to MintCheck and tap Connect to Scanner again."),
        ("Restart the scanner", "Unplug the scanner, wait a few seconds, then plug it back in. Wait for it to power on before connecting.")
    ]

    init(onDismiss: @escaping () -> Void, onNeedHelp: (() -> Void)? = nil) {
        self.onDismiss = onDismiss
        self.onNeedHelp = onNeedHelp
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("If MintCheck can't find your scanner, try these steps.")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                            .padding(.bottom, 8)

                        ForEach(Array(steps.enumerated()), id: \.offset) { index, step in
                            VStack(alignment: .leading, spacing: 8) {
                                HStack(alignment: .top, spacing: 8) {
                                    Text("\(index + 1).")
                                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                        .foregroundColor(.mintGreen)
                                    Text(step.title)
                                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                }
                                Text(step.body)
                                    .font(.system(size: FontSize.bodyRegular))
                                    .foregroundColor(.textSecondary)
                                    .lineSpacing(4)
                                    .padding(.leading, 24)
                            }
                            .padding(LayoutConstants.padding4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.softBackground)
                            .cornerRadius(LayoutConstants.borderRadius)
                        }

                        if onNeedHelp != nil {
                            Button(action: { onNeedHelp?() }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "questionmark.circle")
                                    Text("Need help?")
                                        .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                                }
                                .foregroundColor(.mintGreen)
                            }
                            .padding(.top, 8)
                        }
                    }
                    .padding(24)
                }
                .background(Color.deepBackground)
            }
            .navigationTitle("Troubleshoot connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { onDismiss() }
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.mintGreen)
                }
            }
        }
    }
}

// MARK: - OfflineBanner

struct OfflineBanner: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 16))
                .foregroundColor(.white)
            Text("You're offline. Some features will be available when you're back online.")
                .font(.system(size: FontSize.bodySmall, weight: .medium))
                .foregroundColor(.white)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, LayoutConstants.padding4)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(Color.textSecondary)
        .cornerRadius(LayoutConstants.borderRadius)
    }
}

// MARK: - ReportStatusBadge

enum ReportStorageStatus {
    case localOnly       // Offline scan, not yet uploaded
    case pendingUpload   // Saved locally, upload failed or deferred
    case uploaded        // Successfully saved to cloud

    var label: String {
        switch self {
        case .localOnly: return "Offline scan"
        case .pendingUpload: return "Upload pending"
        case .uploaded: return "Uploaded"
        }
    }

    var icon: String {
        switch self {
        case .localOnly: return "wifi.slash"
        case .pendingUpload: return "arrow.clockwise.circle"
        case .uploaded: return "checkmark.circle"
        }
    }

    var color: Color {
        switch self {
        case .localOnly: return .textSecondary
        case .pendingUpload: return .statusCaution
        case .uploaded: return .statusSafe
        }
    }
}

struct ReportStatusBadge: View {
    let status: ReportStorageStatus

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: status.icon)
                .font(.system(size: 14))
            Text(status.label)
                .font(.system(size: FontSize.bodySmall, weight: .medium))
        }
        .foregroundColor(status.color)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(status.color.opacity(0.15))
        .cornerRadius(4)
    }
}
