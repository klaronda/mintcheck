//
//  SettingsView.swift
//  MintCheck
//
//  Account settings and preferences
//

import SwiftUI
import Supabase

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    let onMenuTap: () -> Void
    
    @State private var isEmailConfirmed: Bool = true
    @State private var showChangeEmailFromBanner: Bool = false
    @State private var showResendToast: Bool = false
    @State private var showSignOutAlert = false
    @State private var showDeleteAccountAlert = false
    @State private var showDeleteConfirmation = false
    @State private var isDeleting = false
    @State private var sharedReports: [ShareService.SharedReport] = []
    @State private var isLoadingSharedReports = false
    @State private var showDeleteLinkAlert = false
    @State private var linkToDelete: ShareService.SharedReport?
    @State private var showDeleteAccountFailedAlert = false
    @State private var deleteAccountError: String?
    @State private var deleteLinkError: String?
    @State private var loadSharedReportsError: String?
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Settings")
                        .font(.system(size: FontSize.h2, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Manage your account")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
                
                Button(action: onMenuTap) {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.mintGreen)
                        .padding(8)
                }
                .buttonStyle(.plain)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(Color.white)
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.borderColor),
                alignment: .bottom
            )
            
            if !isEmailConfirmed {
                EmailNotConfirmedBanner(
                    onResend: resendConfirmation,
                    onChangeEmail: { showChangeEmailFromBanner = true },
                    onSignOut: { Task { try? await authService.signOut() } }
                )
                .padding(.horizontal, 24)
                .padding(.top, 12)
            }
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Account Info Section (profile, email, password, security)
                    AccountInfoView()
                        .environmentObject(authService)
                    
                    // Plan Details (Early Access / Tester badge and upgrade cards)
                    PlanDetailsSection()
                        .environmentObject(authService)
                    
                    // Send feedback
                    Button(action: {
                        nav.feedbackSource = .in_app
                        nav.feedbackPrefillMessage = ""
                        nav.feedbackErrorCode = nil
                        nav.feedbackErrorMessage = nil
                        nav.feedbackScanStep = nil
                        nav.showFeedbackModal = true
                    }) {
                        HStack {
                            Text("Send feedback")
                                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                .foregroundColor(.textPrimary)
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16))
                        }
                        .padding(LayoutConstants.padding6)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadiusLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    // Shared Links Section
                    SharedLinksSection(
                        sharedReports: $sharedReports,
                        isLoading: $isLoadingSharedReports,
                        loadError: $loadSharedReportsError,
                        onDelete: { report in
                            linkToDelete = report
                            showDeleteLinkAlert = true
                        },
                        onCopy: { url in
                            UIPasteboard.general.string = url
                        },
                        onReportIssue: {
                            nav.feedbackSource = .error_cta
                            nav.feedbackPrefillMessage = "Couldn't load shared links."
                            nav.feedbackErrorCode = ErrorEventCode.ERR_LOAD_SHARED_REPORTS_FAIL.rawValue
                            nav.feedbackErrorMessage = loadSharedReportsError ?? "Load shared reports failed"
                            nav.feedbackScanStep = "settings"
                            nav.showFeedbackModal = true
                        }
                    )
                    
                    // App Info Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("About")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        VStack(spacing: 0) {
                            SettingsInfoRow(
                                label: "Version",
                                value: appVersion
                            )
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            SettingsLinkRow(
                                label: "Privacy Policy",
                                url: "https://mintcheckapp.com/privacy"
                            )
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            SettingsLinkRow(
                                label: "Terms of Service",
                                url: "https://mintcheckapp.com/terms"
                            )
                        }
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadiusLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                    
                    // Sign Out
                    Button(action: { showSignOutAlert = true }) {
                        HStack {
                            Text("Sign Out")
                                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                            Spacer()
                            Image(systemName: "arrow.right.square")
                                .font(.system(size: 16))
                        }
                        .foregroundColor(.textPrimary)
                        .padding(LayoutConstants.padding6)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadiusLarge)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                    
                    // Delete Account (subtle)
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Delete Account")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.textMuted)
                            
                            Text("Permanently delete your account and all data")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textMuted)
                        }
                        
                        Spacer()
                        
                        Button(action: { showDeleteAccountAlert = true }) {
                            Image(systemName: "trash")
                                .font(.system(size: 16))
                                .foregroundColor(.textMuted)
                                .padding(8)
                        }
                    }
                    .padding(.top, 16)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .background(Color.deepBackground)
        .sheet(isPresented: $showChangeEmailFromBanner) {
            ChangeEmailView(onDismiss: { showChangeEmailFromBanner = false })
                .environmentObject(authService)
                .environmentObject(nav)
        }
        .overlay {
            // Loading overlay during account deletion
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        ProgressView()
                            .scaleEffect(1.5)
                            .tint(.white)
                        
                        Text("Deleting account...")
                            .font(.system(size: FontSize.bodyLarge, weight: .medium))
                            .foregroundColor(.white)
                    }
                    .padding(32)
                    .background(Color.textPrimary.opacity(0.9))
                    .cornerRadius(LayoutConstants.borderRadiusLarge)
                }
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    try? await authService.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Account?", isPresented: $showDeleteAccountAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                showDeleteConfirmation = true
            }
        } message: {
            Text("This will permanently delete your account and all scan history. This action cannot be undone.")
        }
        .alert("Confirm delete of your MintCheck account.", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Confirm", role: .destructive) {
                Task {
                    isDeleting = true
                    do {
                        try await authService.deleteAccount()
                        // Set success message and navigate to home
                        await MainActor.run {
                            nav.accountDeletedMessage = "Your MintCheck account was successfully deleted."
                            nav.currentScreen = .home
                            isDeleting = false
                        }
                    } catch {
                        isDeleting = false
                        deleteAccountError = (error as NSError).localizedDescription
                        showDeleteAccountFailedAlert = true
                        print("Failed to delete account: \(error)")
                    }
                }
            }
        }
        .alert("Delete account failed", isPresented: $showDeleteAccountFailedAlert) {
            Button("OK") {
                showDeleteAccountFailedAlert = false
                deleteAccountError = nil
            }
            Button("Report this issue") {
                nav.feedbackSource = .error_cta
                nav.feedbackPrefillMessage = "Delete account failed."
                nav.feedbackErrorCode = ErrorEventCode.ERR_DELETE_ACCOUNT_FAIL.rawValue
                nav.feedbackErrorMessage = deleteAccountError ?? "Delete account failed"
                nav.feedbackScanStep = "settings"
                nav.showFeedbackModal = true
                showDeleteAccountFailedAlert = false
                deleteAccountError = nil
            }
        } message: {
            Text(deleteAccountError ?? "Something went wrong. Please try again.")
        }
        .alert("Delete Shared Link?", isPresented: $showDeleteLinkAlert) {
            Button("Cancel", role: .cancel) {
                linkToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let report = linkToDelete {
                    deleteSharedLink(report)
                }
                linkToDelete = nil
            }
        } message: {
            if let report = linkToDelete {
                Text("This will permanently delete the shareable link for \(report.vehicleName). Anyone with this link will no longer be able to view the report.")
            }
        }
        .alert("Couldn't delete link", isPresented: Binding(get: { deleteLinkError != nil }, set: { if !$0 { deleteLinkError = nil } })) {
            Button("OK") { deleteLinkError = nil }
            Button("Report this issue") {
                nav.feedbackSource = .error_cta
                nav.feedbackPrefillMessage = "Delete shared link failed."
                nav.feedbackErrorCode = ErrorEventCode.ERR_DELETE_SHARED_LINK_FAIL.rawValue
                nav.feedbackErrorMessage = deleteLinkError ?? "Delete shared link failed"
                nav.feedbackScanStep = "settings"
                nav.showFeedbackModal = true
                deleteLinkError = nil
            }
        } message: {
            Text(deleteLinkError ?? "Something went wrong. Please try again.")
        }
        .onAppear {
            loadSharedReports()
            Task { await refreshEmailConfirmed() }
        }
    }
    
    // MARK: - Shared Reports
    
    private func loadSharedReports() {
        guard let userId = authService.currentUser?.id else { return }
        
        isLoadingSharedReports = true
        
        Task {
            do {
                let session = try await SupabaseConfig.shared.client.auth.session
                let accessToken = session.accessToken
                let reports = try await ShareService.shared.getSharedReports(userId: userId, accessToken: accessToken)
                await MainActor.run {
                    sharedReports = reports
                    isLoadingSharedReports = false
                }
            } catch {
                print("Failed to load shared reports: \(error)")
                await MainActor.run {
                    loadSharedReportsError = (error as NSError).localizedDescription
                    isLoadingSharedReports = false
                }
            }
        }
    }
    
    private func deleteSharedLink(_ report: ShareService.SharedReport) {
        Task {
            do {
                let session = try await SupabaseConfig.shared.client.auth.session
                let accessToken = session.accessToken
                try await ShareService.shared.deleteSharedReport(reportId: report.id, accessToken: accessToken)
                await MainActor.run {
                    sharedReports.removeAll { $0.id == report.id }
                    deleteLinkError = nil
                }
            } catch {
                await MainActor.run {
                    deleteLinkError = (error as NSError).localizedDescription
                }
                print("Failed to delete shared report: \(error)")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var fullName: String {
        let first = authService.currentUser?.firstName ?? ""
        let last = authService.currentUser?.lastName ?? ""
        let name = "\(first) \(last)".trimmingCharacters(in: .whitespaces)
        return name.isEmpty ? "Not set" : name
    }
    
    private var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }
    
    private func refreshEmailConfirmed() async {
        isEmailConfirmed = await authService.isEmailConfirmed()
    }
    
    private func resendConfirmation() {
        Task {
            do {
                try await authService.resendConfirmationEmail()
                showResendToast = true
                await refreshEmailConfirmed()
            } catch {
                // Error shown via authService
            }
        }
    }
}

// MARK: - Email Not Confirmed Banner

private struct EmailNotConfirmedBanner: View {
    let onResend: () -> Void
    let onChangeEmail: () -> Void
    let onSignOut: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Confirm your email to continue.")
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            Text("Check your inbox for a confirmation link, or resend it.")
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.textSecondary)
            
            HStack(spacing: 10) {
                Button(action: onResend) {
                    Text("Resend email")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.mintGreen)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.mintGreen.opacity(0.08))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
                
                Button(action: onChangeEmail) {
                    Text("Change email")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Color.borderColor.opacity(0.4))
                        .cornerRadius(10)
                }
                .buttonStyle(.plain)
            }
            
            Button(action: onSignOut) {
                Text("Sign out")
                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    .foregroundColor(.statusDanger)
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadiusLarge)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Settings Info Row

struct SettingsInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textPrimary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Settings Link Row

struct SettingsLinkRow: View {
    let label: String
    let url: String
    
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Button(action: {
            if let url = URL(string: url) {
                openURL(url)
            }
        }) {
            HStack {
                Text(label)
                    .font(.system(size: FontSize.bodyRegular))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                Image(systemName: "arrow.up.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Shared Links Section

struct SharedLinksSection: View {
    @Binding var sharedReports: [ShareService.SharedReport]
    @Binding var isLoading: Bool
    @Binding var loadError: String?
    let onDelete: (ShareService.SharedReport) -> Void
    let onCopy: (String) -> Void
    let onReportIssue: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Shared Links")
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Spacer()
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            if let error = loadError, !isLoading {
                // Load failed - show error with Report this issue
                VStack(spacing: 12) {
                    Text("Couldn't load shared links")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.textPrimary)
                    Text(error)
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                    Button(action: onReportIssue) {
                        Text("Report this issue")
                            .font(.system(size: FontSize.bodySmall, weight: .semibold))
                            .foregroundColor(.mintGreen)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(LayoutConstants.borderRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            } else if sharedReports.isEmpty && !isLoading {
                // Empty state
                VStack(spacing: 8) {
                    Text("No shared links")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                    
                    Text("When you share a report with a link, it will appear here.")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
                .padding(.horizontal, 16)
                .background(Color.white)
                .cornerRadius(LayoutConstants.borderRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(sharedReports.enumerated()), id: \.element.id) { index, report in
                        SharedLinkRow(
                            report: report,
                            onDelete: { onDelete(report) },
                            onCopy: { onCopy(report.shareUrl) }
                        )
                        
                        if index < sharedReports.count - 1 {
                            Divider()
                                .padding(.leading, 16)
                        }
                    }
                }
                .background(Color.white)
                .cornerRadius(LayoutConstants.borderRadiusLarge)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            }
        }
    }
}

// MARK: - Shared Link Row

struct SharedLinkRow: View {
    let report: ShareService.SharedReport
    let onDelete: () -> Void
    let onCopy: () -> Void
    
    private var scanFreshness: ScanFreshness {
        // Parse the scan date from report data
        let dateFormatter = ISO8601DateFormatter()
        if let scanDate = dateFormatter.date(from: report.reportData.scanDate) {
            return computeScanFreshness(scanCompletedAt: scanDate)
        }
        return .unknown
    }
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: report.createdAt)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(report.vehicleName)
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    HStack(spacing: 8) {
                        Text("Shared \(formattedDate)")
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                        
                        ScanFreshnessBadge(freshness: scanFreshness, compact: true)
                    }
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Button(action: onCopy) {
                        Image(systemName: "doc.on.doc")
                            .font(.system(size: 16))
                            .foregroundColor(.mintGreen)
                            .frame(width: 36, height: 36)
                    }
                    
                    Button(action: onDelete) {
                        Image(systemName: "trash")
                            .font(.system(size: 16))
                            .foregroundColor(.statusDanger)
                            .frame(width: 36, height: 36)
                    }
                }
            }
            
            // Show truncated URL
            Text(report.shareUrl)
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.mintGreen)
                .lineLimit(1)
                .truncationMode(.middle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }
}

// MARK: - Plan Details Section (Early Access / Tester badge and upgrade cards)
struct PlanDetailsSection: View {
    @EnvironmentObject var authService: AuthService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Plan Details")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)

            // Active Buyer Pass
            if let activeSub = BuyerPassService.shared.activeBuyerPass, activeSub.isActive {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Buyer Pass")
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                        Text("Active")
                            .font(.system(size: FontSize.bodySmall, weight: .semibold))
                            .foregroundColor(Color(red: 0.09, green: 0.56, blue: 0.33))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color(red: 0.09, green: 0.56, blue: 0.33).opacity(0.12))
                            .cornerRadius(10)
                    }

                    Text("\(activeSub.daysRemaining) days remaining. Scan up to 10 vehicles per day.")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)

                    if let endDate = activeSub.endedAt {
                        let formatter: DateFormatter = {
                            let f = DateFormatter()
                            f.dateStyle = .medium
                            return f
                        }()
                        Text("Expires \(formatter.string(from: endDate))")
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                    }

                    // Renew link — only visible in the last 7 days
                    if activeSub.daysRemaining <= 7 {
                        Button(action: {
                            Task {
                                do {
                                    let checkoutURL = try await BuyerPassService.shared.createCheckoutSession()
                                    await MainActor.run { UIApplication.shared.open(checkoutURL) }
                                } catch {
                                    print("Renew Buyer Pass error: \(error)")
                                }
                            }
                        }) {
                            Text("Renew Buyer Pass")
                                .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                                .foregroundColor(.mintGreen)
                        }
                        .padding(.top, 4)
                    }
                }
                .padding(LayoutConstants.padding4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.mintGreen.opacity(0.06))
                .cornerRadius(LayoutConstants.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .stroke(Color.mintGreen.opacity(0.35), lineWidth: 1)
                )
            } else if authService.hasFullAccess {
                // Early Access / Tester
                VStack(alignment: .leading, spacing: 12) {
                    Text(authService.isTester ? "Tester (full access)" : "Early Access User")
                        .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                        .foregroundColor(.mintGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.mintGreen.opacity(0.15))
                        .clipShape(Capsule())
                    Text(authService.isTester
                            ? "You can scan as many vehicles as you like. Advanced analysis requires a subscription."
                            : "You can scan one vehicle as often as you like. Advanced analysis requires a subscription.")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    DashboardPlanCard(
                        title: "Buyer Pass",
                        bodyText: "60-day full access when shopping for a used car.",
                        cta: "Learn more",
                        url: "",
                        onCtaTap: {
                            Task {
                                do {
                                    let checkoutURL = try await BuyerPassService.shared.createCheckoutSession()
                                    await MainActor.run { UIApplication.shared.open(checkoutURL) }
                                } catch {
                                    print("Buyer Pass checkout error: \(error)")
                                }
                            }
                        }
                    )
                }
            } else {
                // Free user — no active plan
                VStack(alignment: .leading, spacing: 12) {
                    Text("Free")
                        .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                        .foregroundColor(.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                    Text("Scan one vehicle up to 3 times for free. Upgrade to a Buyer Pass for unlimited scanning.")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    DashboardPlanCard(
                        title: "Buyer Pass",
                        bodyText: "60-day full access when shopping for a used car.",
                        cta: "Get Buyer Pass",
                        url: "",
                        onCtaTap: {
                            Task {
                                do {
                                    let checkoutURL = try await BuyerPassService.shared.createCheckoutSession()
                                    await MainActor.run { UIApplication.shared.open(checkoutURL) }
                                } catch {
                                    print("Buyer Pass checkout error: \(error)")
                                }
                            }
                        }
                    )
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    SettingsView(onMenuTap: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
