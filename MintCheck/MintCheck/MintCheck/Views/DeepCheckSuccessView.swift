//
//  DeepCheckSuccessView.swift
//  MintCheck
//
//  Shown when user returns from Stripe Deep Check payment (deep link).
//

import Combine
import SwiftUI
import Supabase

struct DeepCheckSuccessView: View {
    private static let generatingSteps: [String] = [
        "Entering VIN number",
        "Checking accident databases",
        "Analyzing vehicle history",
        "Creating a unique page for your vehicle",
        "Emailing you a copy"
    ]
    private static let stepAdvanceInterval: TimeInterval = 12

    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    let onDone: () -> Void

    @State private var status: DeepCheckStatus?
    @State private var isLoading = true
    @State private var isPolling = false
    @State private var currentStepIndex: Int = 0

    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: "Deep Vehicle Check",
                showBackButton: false,
                backAction: {}
            )

            if isLoading {
                stepProgressView(subtitle: "Loading…")
            } else if let s = status, s.status == "pending" {
                VStack(spacing: 24) {
                    Spacer()
                    ProgressView()
                        .scaleEffect(1.2)
                    Text("Confirming your payment…")
                        .font(.system(size: FontSize.bodyLarge, weight: .medium))
                        .foregroundColor(.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Text("This usually takes just a few seconds.")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
            } else if isPolling {
                stepProgressView(subtitle: "Generating your report… This usually takes under a minute.")
            } else if let s = status {
                ScrollView {
                    VStack(spacing: 24) {
                        if let urlString = s.reportUrl, !urlString.isEmpty {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.statusSafe)
                            Text("Your Deep Vehicle Check is ready")
                                .font(.system(size: FontSize.h4, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            Text("Open your report to view accident history, title status, and more.")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            PrimaryButton(title: "Open Report", action: {
                                nav.deepCheckReportURL = urlString
                                nav.currentScreen = .deepCheckReport
                            })
                            .padding(.horizontal, 24)
                            Text("If you're having trouble viewing your report, check your email for a link.")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 24)
                                .padding(.top, 4)
                        } else if s.status == "report_failed" {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.statusCaution)
                            Text("We couldn't generate your report")
                                .font(.system(size: FontSize.h4, weight: .semibold))
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            if let err = s.reportError, !err.isEmpty {
                                Text(err)
                                    .font(.system(size: FontSize.bodySmall, design: .monospaced))
                                    .foregroundColor(.textSecondary)
                                    .multilineTextAlignment(.center)
                                    .padding(.horizontal)
                            }
                            Text("Try again in a few minutes, or contact support@mintcheckapp.com with your order details and we'll make it right.")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        } else if s.status == "paid" {
                            stepProgressView(subtitle: "Generating your report… This usually takes under a minute.")
                                .padding(.vertical, 24)
                            PrimaryButton(title: "Check status", action: { refreshStatus() })
                                .padding(.horizontal, 24)
                        } else {
                            Text("Your Deep Check is being processed.")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                        }
                        PrimaryButton(title: "Done", action: {
                            nav.currentScreen = .myDeepChecks
                        })
                            .padding(.horizontal, 24)
                            .padding(.top, 8)
                    }
                    .padding(.vertical, 40)
                }
            } else {
                VStack(spacing: 24) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 56))
                        .foregroundColor(.textSecondary)
                    Text("We're still processing your payment.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    Text("Check back in a moment, or view your reports below.")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                    PrimaryButton(title: "View my reports", action: {
                        nav.currentScreen = .myDeepChecks
                    })
                    .padding(.horizontal, 24)
                    Button("Done") {
                        nav.currentScreen = .myDeepChecks
                    }
                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    .foregroundColor(.textSecondary)
                    .padding(.top, 8)
                    Spacer()
                }
            }
        }
        .background(Color.deepBackground)
        .onReceive(Timer.publish(every: Self.stepAdvanceInterval, on: .main, in: .common).autoconnect()) { _ in
            if isLoading || isPolling {
                currentStepIndex = min(currentStepIndex + 1, Self.generatingSteps.count - 1)
            }
        }
        .task {
            await loadAndPollUntilReady()
        }
    }

    private func stepProgressView(subtitle: String) -> some View {
        VStack(spacing: 24) {
            Spacer()
            ProgressView()
                .scaleEffect(1.2)
            Text(subtitle)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(spacing: 0) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.borderColor)
                            .frame(height: 4)
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mintGreen)
                            .frame(
                                width: geometry.size.width * (CGFloat(currentStepIndex + 1) / CGFloat(Self.generatingSteps.count)),
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.3), value: currentStepIndex)
                    }
                }
                .frame(height: 4)
                .padding(.horizontal, 24)
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(Array(Self.generatingSteps.enumerated()), id: \.offset) { index, stepText in
                        HStack(spacing: 12) {
                            if index < currentStepIndex {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 20))
                                    .foregroundColor(.statusSafe)
                                Text(stepText)
                                    .font(.system(size: FontSize.bodyRegular))
                                    .foregroundColor(.textSecondary)
                            } else if index == currentStepIndex {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text(stepText)
                                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                    .foregroundColor(.textPrimary)
                            } else {
                                Image(systemName: "circle")
                                    .font(.system(size: 20))
                                    .foregroundColor(.borderColor)
                                Text(stepText)
                                    .font(.system(size: FontSize.bodyRegular))
                                    .foregroundColor(.textSecondary)
                            }
                            Spacer(minLength: 0)
                        }
                    }
                }
                .padding(.top, 20)
                .padding(.horizontal, 24)
            }
            Spacer()
        }
    }

    private func loadAndPollUntilReady() async {
        await MainActor.run {
            isLoading = true
            currentStepIndex = 0
        }
        // Refresh session so token is fresh when opening app via Universal Link (reduces 401).
        _ = try? await SupabaseConfig.shared.client.auth.refreshSession()

        // Use the sessionId from the deep link URL if available (to fetch the specific purchase)
        let sessionId = await MainActor.run { nav.deepCheckSessionId }
        var current = await DeepCheckService.shared.getMyDeepCheck(sessionId: sessionId)

        // If "pending" status, show "Confirming your payment..." and poll until it transitions to "paid" or beyond
        if let c = current, c.status == "pending" {
            await MainActor.run {
                status = c
                isLoading = false
            }
            // Poll for up to 30 seconds until payment is confirmed (webhook updates status to "paid")
            for _ in 0..<10 {
                try? await Task.sleep(nanoseconds: 3_000_000_000)
                current = await DeepCheckService.shared.getMyDeepCheck(sessionId: sessionId)
                await MainActor.run { status = current }
                if current?.status != "pending" { break }
            }
        } else if current == nil {
            // Retry fetching if not found immediately (race condition with webhook)
            for _ in 0..<3 {
                try? await Task.sleep(nanoseconds: 2_500_000_000)
                current = await DeepCheckService.shared.getMyDeepCheck(sessionId: sessionId)
                if current != nil { break }
            }
            await MainActor.run { status = current }
        } else {
            await MainActor.run { status = current }
        }

        isLoading = false

        guard status?.status == "paid" else {
            if let s = status, s.reportUrl != nil, !(s.reportUrl ?? "").isEmpty {
                await MainActor.run {
                    nav.deepCheckReportURL = s.reportUrl
                    nav.currentScreen = .deepCheckReport
                }
            }
            return
        }

        isPolling = true
        for _ in 0..<40 {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            let next = await DeepCheckService.shared.getMyDeepCheck(sessionId: sessionId)
            await MainActor.run { status = next }
            if next?.status == "report_ready", let url = next?.reportUrl, !url.isEmpty {
                await MainActor.run {
                    isPolling = false
                    nav.deepCheckReportURL = url
                    nav.currentScreen = .deepCheckReport
                }
                return
            }
            if next?.status == "report_failed" { break }
        }
        await MainActor.run { isPolling = false }
    }

    private func refreshStatus() {
        Task {
            let sessionId = await MainActor.run { nav.deepCheckSessionId }
            status = await DeepCheckService.shared.getMyDeepCheck(sessionId: sessionId)
            if let s = status, s.reportUrl != nil, !(s.reportUrl ?? "").isEmpty {
                nav.deepCheckReportURL = s.reportUrl
                nav.currentScreen = .deepCheckReport
            }
        }
    }
}

#Preview {
    DeepCheckSuccessView(onDone: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
