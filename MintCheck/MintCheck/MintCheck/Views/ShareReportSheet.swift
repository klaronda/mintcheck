//
//  ShareReportSheet.swift
//  MintCheck
//
//  Sheet for sharing scan reports via email
//

import SwiftUI
import Supabase

struct ShareReportSheet: View {
    let scanId: UUID
    let vehicleInfo: VehicleInfo
    let recommendation: RecommendationType
    let scanDate: Date
    let summary: String?
    let findings: [String]?
    let valuationLow: Int?
    let valuationHigh: Int?
    let odometerReading: Int?
    let askingPrice: Int?
    let dtcAnalyses: [DTCAnalysisService.DTCAnalysis]?
    let nhtsaData: NHTSADataJSON?
    let systemStatuses: [ShareService.SystemStatusJSON]?  // Authoritative system statuses from in-app results
    let existingShareCode: String?  // Existing share code if report was already shared
    let onDismiss: () -> Void
    let onShareCodeCreated: ((String) -> Void)?  // Callback when a new share code is created
    var isOffline: Bool = false  // When true, show offline message and disable send
    var isScanSaving: Bool = false  // When true, scan is still being saved — block share until done
    var onReportIssue: (() -> Void)? = nil  // When send fails, optional "Report this issue" callback
    
    @EnvironmentObject var authService: AuthService
    
    @State private var recipientsText: String = ""
    @State private var message: String = ""
    @State private var createShareableLink: Bool = false
    @State private var isLoading: Bool = false
    @State private var showSuccess: Bool = false
    @State private var shareUrl: String?
    @State private var errorMessage: String?
    @State private var sendFailedWithLink: String?  // When send failed but we have a share URL to copy
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case recipients, message
    }
    
    // Computed property for existing share URL
    private var existingShareUrl: String? {
        guard let code = existingShareCode else { return nil }
        return "https://mintcheckapp.com/report/\(code)"
    }
    
    // Whether there's already a share link
    private var hasExistingLink: Bool {
        existingShareCode != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Vehicle info header
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Share Report")
                                .font(.system(size: FontSize.h3, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text(vehicleInfo.displayName)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 8)
                        
                        // Recipients field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Recipients")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            ZStack(alignment: .leading) {
                                if recipientsText.isEmpty {
                                    Text(verbatim: "email@example.com, another@example.com")
                                        .font(.system(size: FontSize.bodyRegular))
                                        .foregroundColor(.textMuted)
                                        .padding(.horizontal, 14)
                                }
                                TextField("", text: $recipientsText)
                                    .font(.system(size: FontSize.bodyRegular))
                                    .foregroundColor(.textPrimary)
                                    .padding(14)
                                    .focused($focusedField, equals: .recipients)
                                    .textContentType(.none)
                            }
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            
                            Text("Separate multiple emails with commas. Leave blank to only send to yourself.")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textMuted)
                        }
                        
                        // Message field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Message (optional)")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            TextEditor(text: $message)
                                .font(.system(size: FontSize.bodyRegular))
                                .frame(minHeight: 100)
                                .padding(10)
                                .background(Color.white)
                                .cornerRadius(LayoutConstants.borderRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                )
                                .focused($focusedField, equals: .message)
                            
                            Text("Add a personal note to include with the report.")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textMuted)
                        }
                        
                        // Shareable link section
                        VStack(alignment: .leading, spacing: 12) {
                            if hasExistingLink, let url = existingShareUrl {
                                // Show existing link
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "link.circle.fill")
                                            .font(.system(size: 22))
                                            .foregroundColor(.mintGreen)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Shareable link")
                                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                                .foregroundColor(.textPrimary)
                                            
                                            Text("This report already has a shareable link")
                                                .font(.system(size: FontSize.bodySmall))
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    
                                    Button(action: { copyToClipboard(url) }) {
                                        HStack {
                                            Text(url)
                                                .font(.system(size: FontSize.bodySmall))
                                                .foregroundColor(.mintGreen)
                                                .lineLimit(1)
                                            
                                            Spacer()
                                            
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mintGreen)
                                        }
                                        .padding(12)
                                        .background(Color.statusSafeBg)
                                        .cornerRadius(LayoutConstants.borderRadius)
                                    }
                                }
                            } else {
                                // Checkbox to create new link
                                Button(action: { createShareableLink.toggle() }) {
                                    HStack(spacing: 12) {
                                        Image(systemName: createShareableLink ? "checkmark.square.fill" : "square")
                                            .font(.system(size: 22))
                                            .foregroundColor(createShareableLink ? .mintGreen : .textMuted)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Create shareable link")
                                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                                .foregroundColor(.textPrimary)
                                            
                                            Text("Generate a public link anyone can view")
                                                .font(.system(size: FontSize.bodySmall))
                                                .foregroundColor(.textSecondary)
                                        }
                                        
                                        Spacer()
                                    }
                                    .contentShape(Rectangle())
                                }
                                .buttonStyle(.plain)
                                
                                if createShareableLink {
                                    HStack(spacing: 8) {
                                        Image(systemName: "info.circle")
                                            .font(.system(size: 14))
                                            .foregroundColor(.mintGreen)
                                        
                                        Text("Link will be included in the email. You can manage links in Settings.")
                                            .font(.system(size: FontSize.bodySmall))
                                            .foregroundColor(.textSecondary)
                                    }
                                    .padding(12)
                                    .background(Color.statusSafeBg)
                                    .cornerRadius(LayoutConstants.borderRadius)
                                }
                            }
                        }
                        
                        // What's included
                        VStack(alignment: .leading, spacing: 12) {
                            Text("What's included")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                IncludedItem(icon: "doc.text", text: "Full scan report with findings")
                                IncludedItem(icon: "calendar", text: "Scan date and validity period")
                                IncludedItem(icon: "dollarsign.circle", text: "Vehicle valuation estimate")
                                IncludedItem(icon: "paperclip", text: "PDF attachment")
                            }
                        }
                        .padding(16)
                        .background(Color.softBackground)
                        .cornerRadius(LayoutConstants.borderRadius)
                        
                        // Offline message
                        if isOffline {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi.slash")
                                    .foregroundColor(.statusCaution)
                                Text("You're offline. Sharing will be available when you're back online.")
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(12)
                            .background(Color.statusCautionBg)
                            .cornerRadius(LayoutConstants.borderRadius)
                        }
                        
                        // Error message (send failed)
                        if let error = errorMessage {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle")
                                        .foregroundColor(.statusDanger)
                                    Text(error)
                                        .font(.system(size: FontSize.bodySmall))
                                        .foregroundColor(.statusDanger)
                                }
                                HStack(spacing: 12) {
                                    Button(action: sendReport) {
                                        Text("Try Again")
                                            .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                            .foregroundColor(.mintGreen)
                                    }
                                    if let link = sendFailedWithLink ?? existingShareUrl {
                                        Button(action: { copyToClipboard(link) }) {
                                            Text("Copy Share Link")
                                                .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                                .foregroundColor(.mintGreen)
                                        }
                                    }
                                    if let report = onReportIssue {
                                        Button(action: report) {
                                            Text("Report this issue")
                                                .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                                .foregroundColor(.mintGreen)
                                        }
                                    }
                                }
                            }
                            .padding(12)
                            .background(Color.statusDangerBg)
                            .cornerRadius(LayoutConstants.borderRadius)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                
                // Bottom action area
                VStack(spacing: 12) {
                    if showSuccess {
                        // Success state
                        VStack(spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.mintGreen)
                                Text("Report sent successfully!")
                                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                    .foregroundColor(.textPrimary)
                            }
                            
                            if let url = shareUrl {
                                VStack(spacing: 8) {
                                    Text("Shareable link:")
                                        .font(.system(size: FontSize.bodySmall))
                                        .foregroundColor(.textSecondary)
                                    
                                    Button(action: { copyToClipboard(url) }) {
                                        HStack {
                                            Text(url)
                                                .font(.system(size: FontSize.bodySmall))
                                                .foregroundColor(.mintGreen)
                                                .lineLimit(1)
                                            
                                            Image(systemName: "doc.on.doc")
                                                .font(.system(size: 14))
                                                .foregroundColor(.mintGreen)
                                        }
                                    }
                                }
                                .padding(12)
                                .background(Color.statusSafeBg)
                                .cornerRadius(LayoutConstants.borderRadius)
                            }
                            
                            PrimaryButton(title: "Done", action: onDismiss)
                        }
                    } else {
                        // Send button (disabled when offline)
                        PrimaryButton(
                            title: isLoading ? "Sending..." : "Send Report",
                            action: sendReport,
                            isEnabled: !isLoading && !isOffline,
                            isLoading: isLoading
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 16)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(.borderColor),
                    alignment: .top
                )
            }
            .background(Color.deepBackground)
            .onTapGesture {
                focusedField = nil
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.mintGreen)
                }
            }
        }
    }
    
    // MARK: - Actions
    
    private func sendReport() {
        guard let user = authService.currentUser else {
            errorMessage = "Please sign in to share reports"
            return
        }
        if isOffline {
            errorMessage = "You're offline. Sharing will be available when you're back online."
            return
        }
        if isScanSaving {
            errorMessage = "Your scan is still saving. Please try again in a moment."
            return
        }
        
        // Client-side email validation
        let recipientStrings = recipientsText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
        let invalidEmails = recipientStrings.filter { !$0.isValidEmail }
        if !invalidEmails.isEmpty {
            errorMessage = "Please enter valid email addresses."
            return
        }
        let recipients = recipientStrings.filter { $0.contains("@") }
        
        isLoading = true
        errorMessage = nil
        sendFailedWithLink = nil
        
        let userName = [user.firstName, user.lastName]
            .compactMap { $0 }
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespaces)
        
        // Use existing share URL if available, otherwise let API create new one if requested
        let shouldCreateLink = hasExistingLink ? false : createShareableLink
        
        Task {
            do {
                // Get access token from session
                let session = try await SupabaseConfig.shared.client.auth.session
                let accessToken = session.accessToken
                
                let response = try await ShareService.shared.shareReport(
                    scanId: scanId,
                    recipients: recipients,
                    message: message.isEmpty ? nil : message,
                    createLink: shouldCreateLink,
                    vehicleInfo: vehicleInfo,
                    recommendation: recommendation,
                    scanDate: scanDate,
                    summary: summary,
                    findings: findings,
                    valuationLow: valuationLow,
                    valuationHigh: valuationHigh,
                    odometerReading: odometerReading,
                    askingPrice: askingPrice,
                    dtcAnalyses: dtcAnalyses,
                    nhtsaData: nhtsaData,
                    systemStatuses: systemStatuses,
                    userEmail: user.email ?? "",
                    userName: userName.isEmpty ? "MintCheck User" : userName,
                    accessToken: accessToken
                )
                
                await MainActor.run {
                    isLoading = false
                    if response.success {
                        showSuccess = true
                        // Use existing URL if we have one, otherwise use new one from response
                        shareUrl = hasExistingLink ? existingShareUrl : response.shareUrl
                        
                        // Notify parent if a new share code was created
                        if let newCode = response.shareCode, !hasExistingLink {
                            onShareCodeCreated?(newCode)
                        }
                    } else {
                        errorMessage = userFacingShareErrorMessage(response.error ?? "Failed to send report")
                        if let url = response.shareUrl ?? (hasExistingLink ? existingShareUrl : nil) {
                            sendFailedWithLink = url
                        }
                        ErrorEventLogger.shared.log(
                            screen: "shareReport",
                            errorCode: .ERR_EMAIL_SEND_FAIL,
                            message: response.error ?? "Send failed"
                        )
                    }
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = userFacingShareErrorMessage(error.localizedDescription)
                    if hasExistingLink, let url = existingShareUrl {
                        sendFailedWithLink = url
                    }
                    ErrorEventLogger.shared.log(
                        screen: "shareReport",
                        errorCode: .ERR_EMAIL_SEND_FAIL,
                        message: error.localizedDescription
                    )
                }
            }
        }
    }
    
    /// Maps raw API/network error (e.g. "HTTP 500") to a short, user-facing message shown in red.
    private func userFacingShareErrorMessage(_ raw: String) -> String {
        let lower = raw.lowercased()
        if lower.contains("500") || lower.contains("internal server error") {
            return "Something went wrong on our end. Please try again in a moment."
        }
        if lower.contains("502") || lower.contains("503") || lower.contains("504") {
            return "Our servers are temporarily busy. Please try again in a moment."
        }
        if lower.contains("400") || lower.contains("bad request") {
            // Show server message when scan not saved yet (share before save completes)
            if lower.contains("scan not found") || lower.contains("save the report first") {
                return raw
            }
            return "We couldn't send the report. Please check the email addresses and try again."
        }
        if lower.contains("401") || lower.contains("unauthorized") {
            return "Please sign in again to share reports."
        }
        if lower.contains("429") || lower.contains("too many requests") {
            return "Too many attempts. Please wait a moment and try again."
        }
        if lower.contains("network") || lower.contains("connection") || lower.contains("offline") {
            return "We couldn't reach our servers. Check your connection and try again."
        }
        // If it already looks like a sentence, use it; otherwise avoid showing raw codes
        if raw.starts(with: "HTTP ") || raw.allSatisfy({ $0.isNumber }) || raw.count < 10 {
            return "We couldn't send the email. Please try again."
        }
        return raw
    }

    private func copyToClipboard(_ text: String) {
        UIPasteboard.general.string = text
    }
}

// MARK: - Included Item

struct IncludedItem: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.mintGreen)
                .frame(width: 20)
            
            Text(text)
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Preview

// MARK: - Email validation
private extension String {
    var isValidEmail: Bool {
        let pattern = #"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$"#
        return range(of: pattern, options: .regularExpression) != nil
    }
}

#Preview {
    ShareReportSheet(
        scanId: UUID(),
        vehicleInfo: VehicleInfo(year: "2020", make: "Honda", model: "Accord"),
        recommendation: .safe,
        scanDate: Date(),
        summary: "Vehicle is in good condition",
        findings: ["No DTCs found", "Battery healthy"],
        valuationLow: 18000,
        valuationHigh: 21000,
        odometerReading: 45000,
        askingPrice: 19500,
        dtcAnalyses: nil,
        nhtsaData: nil,
        systemStatuses: nil,
        existingShareCode: nil,
        onDismiss: {},
        onShareCodeCreated: nil
    )
    .environmentObject(AuthService())
}
