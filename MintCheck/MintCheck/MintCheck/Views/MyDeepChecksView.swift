//
//  MyDeepChecksView.swift
//  MintCheck
//
//  List of user's Deep Vehicle Check purchases; tap a ready report to open in-app.
//

import SwiftUI

struct MyDeepChecksView: View {
    let onBack: () -> Void

    @EnvironmentObject var nav: NavigationManager
    @State private var purchases: [DeepCheckPurchase] = []
    @State private var isLoading = true
    @State private var loadError: String? = nil
    @State private var isRefreshing = false

    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .none
        return f
    }()

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(title: "My Deep Vehicle Checks", showBackButton: true, backAction: onBack)

            if isLoading, !isRefreshing {
                Spacer()
                ProgressView()
                    .scaleEffect(1.2)
                Text("Loading…")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 8)
                Spacer()
            } else if purchases.isEmpty {
                Spacer()
                VStack(spacing: 20) {
                    Image(systemName: loadError != nil ? "wifi.exclamationmark" : "doc.text.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.textSecondary)
                    Text(loadError != nil ? "Couldn't load your reports" : "No Deep Vehicle Checks yet")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text(loadError != nil
                         ? "Pull down to try again, or check your connection."
                         : "Purchase a Deep Check from the dashboard to see accident history, title status, and more.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    if loadError != nil {
                        Button("Retry") { Task { await load(showLoading: true) } }
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.mintGreen)
                            .padding(.top, 8)
                    }
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(purchases) { purchase in
                            DeepCheckRowView(
                                purchase: purchase,
                                dateFormatter: dateFormatter,
                                onOpenReport: {
                                    if let url = purchase.reportUrl, !url.isEmpty {
                                        nav.deepCheckReportURL = url
                                        nav.currentScreen = .deepCheckReport
                                    }
                                },
                                onEmailSent: { Task { await load(showLoading: false) } }
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .padding(.bottom, 40)
                }
                .refreshable {
                    await load(showLoading: false)
                }
            }
        }
        .background(Color.deepBackground)
        .task {
            await load(showLoading: true)
        }
    }

    private func load(showLoading: Bool) async {
        if showLoading { isLoading = true }
        else { isRefreshing = true }
        loadError = nil
        do {
            let list = try await DeepCheckService.shared.getMyDeepChecks()
            await MainActor.run {
                purchases = list
                loadError = nil
                isLoading = false
                isRefreshing = false
            }
        } catch {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            do {
                let list = try await DeepCheckService.shared.getMyDeepChecks()
                await MainActor.run {
                    purchases = list
                    loadError = nil
                    isLoading = false
                    isRefreshing = false
                }
            } catch {
                await MainActor.run {
                    purchases = []
                    loadError = (error as? DeepCheckError)?.message ?? "Couldn't load your reports. Pull down to try again."
                    isLoading = false
                    isRefreshing = false
                }
            }
        }
    }
}

// MARK: - Row for a single purchase
private struct DeepCheckRowView: View {
    let purchase: DeepCheckPurchase
    let dateFormatter: DateFormatter
    let onOpenReport: () -> Void
    let onEmailSent: () -> Void

    @State private var isSendingEmail = false
    @State private var emailError: String?
    @State private var emailJustSent = false

    private static var emailedAtFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM d, yyyy 'at' h:mm a zzz"
        return f
    }

    private var canOpenReport: Bool {
        purchase.status == "report_ready" && (purchase.reportUrl ?? "").isEmpty == false
    }

    private var reportCodeFromUrl: String? {
        guard let urlString = purchase.reportUrl, let url = URL(string: urlString) else { return nil }
        let code = url.lastPathComponent
        return code.isEmpty ? nil : code
    }

    private var showEmailStatus: Bool {
        canOpenReport && (purchase.reportEmailedAt != nil || emailJustSent)
    }

    private var showEmailButton: Bool {
        canOpenReport && purchase.reportEmailedAt == nil && !emailJustSent
    }

    var body: some View {
        Button(action: {
            if canOpenReport { onOpenReport() }
        }) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        if let ymm = purchase.yearMakeModel, !ymm.isEmpty {
                            Text(ymm)
                                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                .foregroundColor(.textPrimary)
                        }
                        Text(purchase.vin)
                            .font(.system(size: FontSize.bodySmall, weight: .medium, design: .monospaced))
                            .foregroundColor(.textSecondary)
                        Text(dateFormatter.string(from: purchase.createdAt))
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                        if purchase.status == "report_failed", let err = purchase.reportError, !err.isEmpty {
                            Text(err)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.statusCaution)
                                .lineLimit(2)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    Spacer()
                    statusBadge
                    if canOpenReport {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(16)

                if showEmailStatus {
                    Text(emailStatusText)
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 16)
                        .padding(.bottom, 12)
                } else if showEmailButton, let code = reportCodeFromUrl {
                    HStack(spacing: 8) {
                        Button(action: { sendEmail(code: code) }) {
                            if isSendingEmail {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Text("Email me report")
                                    .font(.system(size: FontSize.bodySmall, weight: .medium))
                                    .foregroundColor(.mintGreen)
                            }
                        }
                        .disabled(isSendingEmail)
                        if let err = emailError {
                            Text(err)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.statusDanger)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canOpenReport)
        .padding(.bottom, 12)
    }

    private var emailStatusText: String {
        if emailJustSent {
            return "Report sent to your email."
        }
        guard let date = purchase.reportEmailedAt else { return "" }
        return "Emailed to you on \(Self.emailedAtFormatter.string(from: date))"
    }

    private func sendEmail(code: String) {
        emailError = nil
        isSendingEmail = true
        Task {
            do {
                try await DeepCheckService.shared.emailReport(reportCode: code)
                await MainActor.run {
                    isSendingEmail = false
                    emailJustSent = true
                    onEmailSent()
                }
            } catch {
                await MainActor.run {
                    isSendingEmail = false
                    emailError = (error as? DeepCheckEmailError)?.message ?? "Could not send email."
                }
            }
        }
    }

    private var statusBadge: some View {
        Text(statusLabel)
            .font(.system(size: FontSize.bodySmall, weight: .medium))
            .foregroundColor(statusColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.15))
            .cornerRadius(6)
    }

    private var statusLabel: String {
        switch purchase.status {
        case "report_ready": return "Ready"
        case "paid": return "Processing"
        case "report_failed": return "Failed"
        default: return "Pending"
        }
    }

    private var statusColor: Color {
        switch purchase.status {
        case "report_ready": return .statusSafe
        case "paid": return .textSecondary
        case "report_failed": return .statusCaution
        default: return .textSecondary
        }
    }
}

#Preview {
    MyDeepChecksView(onBack: {})
        .environmentObject(NavigationManager())
}
