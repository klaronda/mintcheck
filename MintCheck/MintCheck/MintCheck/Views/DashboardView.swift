//
//  DashboardView.swift
//  MintCheck
//
//  Main dashboard with scan history and device recommendations
//

import SwiftUI

struct DashboardView: View {
    let onStartCheck: () -> Void
    /// When provided and Buyer Pass is active, early-access vehicle card shows a second CTA to scan using Buyer Pass.
    var onStartBuyerPassCheck: (() -> Void)? = nil
    let onViewHistory: (String) -> Void
    let onMenuTap: () -> Void
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var scanService: ScanService
    @EnvironmentObject var nav: NavigationManager
    
    @State private var isEmailConfirmed: Bool = true
    @State private var deepCheckReports: [DeepCheckPurchase] = []
    @State private var hasOwnScanner: Bool = false
    @State private var showScannerDismissToast: Bool = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            DashboardHeader(
                userName: authService.currentUser?.firstName ?? "there",
                onMenuTap: onMenuTap
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    if !isEmailConfirmed {
                        EmailNotConfirmedBanner(
                            onResend: resendConfirmation,
                            onChangeEmail: { nav.currentScreen = .settings },
                            onSignOut: { Task { try? await authService.signOut() } }
                        )
                    }
                    
                    if authService.hasFullAccess {
                        // Full access: primary card (or early-access "Your vehicle" card), recent scans, OBD, upgrade options
                        if authService.isEarlyAccess, let vehicle = scanService.vehicles.first {
                            // Early access with a saved vehicle: show vehicle card
                            VStack(alignment: .leading, spacing: 16) {
                                Text(vehicle.shortDisplayName)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Text("As an early adopter of MintCheck, scans for this vehicle are free – no plan required.")
                                    .font(.system(size: FontSize.bodyLarge))
                                    .foregroundColor(.textSecondary)
                                    .lineSpacing(4)
                                PrimaryButton(
                                    title: "Scan Again",
                                    action: onStartCheck
                                )
                                if BuyerPassService.shared.activeBuyerPass?.isActive == true,
                                   let onBP = onStartBuyerPassCheck {
                                    SecondaryButton(
                                        title: "Scan with Buyer Pass",
                                        action: onBP,
                                        style: .outlined
                                    )
                                    .padding(.top, 8)
                                }
                            }
                            .padding(LayoutConstants.padding6)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        } else {
                            // Full access (or early access with no vehicle yet): standard "Ready to check" card
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Ready to check a vehicle?")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                Text(authService.isEarlyAccess
                                     ? "Scan one vehicle. Know what's going on."
                                     : "Scan as many vehicles as you like. Know what's going on.")
                                    .font(.system(size: FontSize.bodyLarge))
                                    .foregroundColor(.textSecondary)
                                    .lineSpacing(4)
                                PrimaryButton(
                                    title: "Start a Mint Check",
                                    action: onStartCheck
                                )
                            }
                            .padding(LayoutConstants.padding6)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        }
                        
                        if !scanService.scanHistory.isEmpty {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Text("Recent Scans")
                                        .font(.system(size: FontSize.h4, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                }
                                
                                VStack(spacing: 10) {
                                    ForEach(scanService.scanHistory.prefix(6)) { scan in
                                        ScanHistoryCard(item: scan) {
                                            onViewHistory(scan.id.uuidString)
                                        }
                                    }
                                }
                            }
                        }
                        
                        if !hasOwnScanner {
                            OBDDeviceSection(onDismiss: dismissScannerSection)
                        } else if showScannerDismissToast {
                            ScannerDismissToast()
                        }
                        
                        if let activeSub = BuyerPassService.shared.activeBuyerPass, activeSub.isActive {
                            // Buyer Pass active: section headers + sub card + deep check + help
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scan Plans")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                ActiveBuyerPassCard(
                                    subscription: activeSub,
                                    todayScans: scanService.todayScansCount
                                )
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                Text("Add-Ons")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                PlanProductCard(
                                    imageName: "DeepCheck_mint",
                                    title: "Check a car's history.",
                                    bodyText: "Enter the VIN and get a full report on accident history, title and more.",
                                    subtextBold: "$9.99",
                                    ctaTitle: "Run a Deep Check",
                                    ctaAction: { nav.currentScreen = .deepCheckEntry }
                                )
                            }

                            NeedHelpCard(onVisitSupport: { nav.currentScreen = .support })
                        } else {
                            // No buyer pass: same card style as free users (Scan Plans + Add-Ons)
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scan Plans")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                PlanProductCard(
                                    imageName: "BuyersPass_mint",
                                    title: "Scan unlimited vehicles.",
                                    bodyText: "Buying a used car? Scan up to 10 times per day, for 60 days.",
                                    subtextBold: "$14.99",
                                    ctaTitle: "Get Buyer Pass",
                                    ctaAction: {
                                        Task {
                                            do {
                                                let checkoutURL = try await BuyerPassService.shared.createCheckoutSession()
                                                await MainActor.run { UIApplication.shared.open(checkoutURL) }
                                            } catch {
                                                await MainActor.run {
                                                    nav.showErrorToast("Something went wrong. Please try again.", errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue, errorMessage: error.localizedDescription, scanStep: "checkout")
                                                }
                                            }
                                        }
                                    }
                                )
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                Text("Add-Ons")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                PlanProductCard(
                                    imageName: "DeepCheck_mint",
                                    title: "Check a car's history.",
                                    bodyText: "Enter the VIN and get a full report on accident history, title and more.",
                                    subtextBold: "$9.99",
                                    ctaTitle: "Run a Deep Check",
                                    ctaAction: { nav.currentScreen = .deepCheckEntry }
                                )
                            }

                            NeedHelpCard(onVisitSupport: { nav.currentScreen = .support })
                        }
                    } else {
                        // Free user: Scan card (0/3), OBD, Scan Plans, Add-Ons, Need Help
                        FreeUserScanCard(
                            onStartCheck: onStartCheck,
                            scanCount: min(scanService.scanHistory.count, 3),
                            vehicle: scanService.vehicles.first
                        )
                        
                        // Show active Buyer Pass card if active; otherwise show upsell
                        if let activeSub = BuyerPassService.shared.activeBuyerPass, activeSub.isActive {
                            if !hasOwnScanner {
                                OBDDeviceSection(onDismiss: dismissScannerSection)
                            } else if showScannerDismissToast {
                                ScannerDismissToast()
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scan Plans")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                ActiveBuyerPassCard(
                                    subscription: activeSub,
                                    todayScans: scanService.todayScansCount
                                )
                            }

                            VStack(alignment: .leading, spacing: 16) {
                                Text("Add-Ons")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                PlanProductCard(
                                    imageName: "DeepCheck_mint",
                                    title: "Check a car's history.",
                                    bodyText: "Enter the VIN and get a full report on accident history, title and more.",
                                    subtextBold: "$9.99",
                                    ctaTitle: "Run a Deep Check",
                                    ctaAction: { nav.currentScreen = .deepCheckEntry }
                                )
                            }

                            NeedHelpCard(onVisitSupport: { nav.currentScreen = .support })
                        } else {
                            if !hasOwnScanner {
                                OBDDeviceSection(onDismiss: dismissScannerSection)
                            } else if showScannerDismissToast {
                                ScannerDismissToast()
                            }
                            
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Scan Plans")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                PlanProductCard(
                                    imageName: "BuyersPass_mint",
                                    title: "Scan unlimited vehicles.",
                                    bodyText: "Buying a used car? Scan up to 10 times per day, for 60 days.",
                                    subtextBold: "$14.99",
                                    ctaTitle: "Get Buyer Pass",
                                    ctaAction: {
                                        Task {
                                            do {
                                                let checkoutURL = try await BuyerPassService.shared.createCheckoutSession()
                                                await MainActor.run {
                                                    UIApplication.shared.open(checkoutURL)
                                                }
                                            } catch {
                                                await MainActor.run {
                                                    nav.showErrorToast("Something went wrong. Please try again.", errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue, errorMessage: error.localizedDescription, scanStep: "checkout")
                                                }
                                            }
                                        }
                                    }
                                )
                            }
                        
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Add-Ons")
                                    .font(.system(size: FontSize.h4, weight: .semibold))
                                    .foregroundColor(.textPrimary)
                                PlanProductCard(
                                    imageName: "DeepCheck_mint",
                                    title: "Check a car's history.",
                                    bodyText: "Enter the VIN and get a full report on accident history, title and more.",
                                    subtextBold: "$9.99",
                                    ctaTitle: "Run a Deep Check",
                                    ctaAction: { nav.currentScreen = .deepCheckEntry }
                                )
                            }
                        
                            NeedHelpCard(onVisitSupport: { nav.currentScreen = .support })
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120) // Extra padding for tab bar
            }
            .refreshable {
                await refreshDashboard()
            }
        }
        .background(Color.deepBackground)
        .onAppear {
            hasOwnScanner = UserDefaults.standard.bool(forKey: scannerDismissKey())
            loadData()
            Task { await refreshEmailConfirmed() }
        }
    }
    
    private func refreshDashboard() async {
        guard let userId = authService.currentUser?.id else { return }
        try? await scanService.loadScanHistory(userId: userId)
        if !authService.hasFullAccess || authService.isEarlyAccess {
            try? await scanService.loadVehicles(userId: userId)
        }
        await authService.refreshBuyerPassStatus()
        if let reports = try? await DeepCheckService.shared.getMyDeepChecks() {
            deepCheckReports = reports
            nav.hasDeepCheckReports = !reports.isEmpty
        }
        await refreshEmailConfirmed()
    }
    
    private func scannerDismissKey() -> String {
        let uid = authService.currentUser?.id.uuidString ?? ""
        return "hasOwnScanner_\(uid)"
    }

    private func dismissScannerSection() {
        let key = scannerDismissKey()
        UserDefaults.standard.set(true, forKey: key)
        withAnimation(.easeInOut(duration: 0.25)) {
            hasOwnScanner = true
            showScannerDismissToast = true
        }
        // Auto-hide toast after 4 seconds
        Task {
            try? await Task.sleep(nanoseconds: 4_000_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.3)) {
                    showScannerDismissToast = false
                }
            }
        }
    }

    private func loadData() {
        guard let userId = authService.currentUser?.id else { return }
        Task {
            try? await scanService.loadScanHistory(userId: userId)
            if !authService.hasFullAccess || authService.isEarlyAccess {
                try? await scanService.loadVehicles(userId: userId)
            }
            await authService.refreshBuyerPassStatus()
            if let reports = try? await DeepCheckService.shared.getMyDeepChecks() {
                deepCheckReports = reports
                nav.hasDeepCheckReports = !reports.isEmpty
            }
        }
    }
    
    private func refreshEmailConfirmed() async {
        isEmailConfirmed = await authService.isEmailConfirmed()
    }
    
    private func resendConfirmation() {
        Task {
            do {
                try await authService.resendConfirmationEmail()
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

// MARK: - Dashboard Header

struct DashboardHeader: View {
    let userName: String
    let onMenuTap: () -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text("Home")
                    .font(.system(size: FontSize.h2, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Welcome back, \(userName)")
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
    }
}

// MARK: - Scan History Card

struct ScanHistoryCard: View {
    let item: ScanHistoryItem
    let onTap: () -> Void
    
    private var isExpired: Bool {
        let daysOld = Calendar.current.dateComponents([.day], from: item.date, to: Date()).day ?? 0
        return daysOld >= 15
    }
    
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
                
                // Show Expired badge (gray) if 15+ days old, otherwise show recommendation badge
                if isExpired {
                    ExpiredBadge()
                } else {
                    StatusBadge(recommendation: item.recommendation, size: .small)
                }
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

// MARK: - Expired Badge (Gray) — matches StatusBadge small style

struct ExpiredBadge: View {
    var body: some View {
        Text("Expired")
            .font(.system(size: FontSize.bodySmall, weight: .semibold))
            .foregroundColor(Color(hex: "#666666"))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color(hex: "#F0F0F0"))
            .cornerRadius(4)
    }
}

// MARK: - Free User Homepage

struct FreeUserScanCard: View {
    let onStartCheck: () -> Void
    let scanCount: Int
    var vehicle: VehicleInfo? = nil
    
    private var hasScanned: Bool { vehicle != nil && scanCount > 0 }
    private var isMaxed: Bool { scanCount >= 3 }
    
    /// Build the vehicle descriptor, e.g. "2018 Honda Accord" or "Honda Accord" if year is unavailable
    private var vehicleDescriptor: String {
        guard let v = vehicle else { return "" }
        let year = (v.year == "(Year N/A)" || v.year.isEmpty) ? nil : v.year
        if let year = year {
            return "\(year) \(v.make) \(v.model)"
        }
        return "\(v.make) \(v.model)"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if isMaxed {
                // All 3 free scans used
                Text("You've used all 3 free scans.")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("To keep scanning, add a Buyer Pass for unlimited scans for 60 days.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                
                Text("3/3 free scans used")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
            } else if hasScanned {
                // Scan 1 or 2: user has a vehicle
                Text("Scan the same vehicle.")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Check the engine, battery, and fuel system health of your \(vehicleDescriptor) again.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                
                Text("\(scanCount)/3 free scans used")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                
                PrimaryButton(
                    title: "Scan Again",
                    action: onStartCheck
                )
            } else {
                // 0 scans: first-time user
                Text("Scan one vehicle, on us.")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Use your existing OBD-II device to get your car's engine health.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
                
                Text("\(scanCount)/3 free scans used")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                
                PrimaryButton(
                    title: "Start Your Mint Check",
                    action: onStartCheck
                )
            }
        }
        .padding(LayoutConstants.padding6)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

/// Product-style card for Scan Plans / Add-Ons (image, title, body, bold subtext, CTA) — image no container, top-aligned
struct PlanProductCard: View {
    let imageName: String
    let title: String
    let bodyText: String
    let subtextBold: String
    let ctaTitle: String
    let ctaAction: () -> Void
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(imageName)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 80, height: 80)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(bodyText)
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                
                Text(subtextBold)
                    .font(.system(size: FontSize.bodySmall, weight: .bold))
                    .foregroundColor(.textPrimary)
                    .padding(.top, 2)
                
                Button(action: ctaAction) {
                    Text(ctaTitle)
                        .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                        .foregroundColor(.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(LayoutConstants.padding6)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

struct NeedHelpCard: View {
    let onVisitSupport: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Need Help?")
                .font(.system(size: FontSize.bodyLarge, weight: .bold))
                .foregroundColor(.textPrimary)
            
            Text("Learn all about OBD-II scanners, how MintCheck works, and more on our Support page.")
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
            
            Button(action: onVisitSupport) {
                Text("Visit MintCheck Help")
                    .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    .foregroundColor(.mintGreen)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(LayoutConstants.padding6)
        .background(Color.clear)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Free User VIN Mismatch Block Screen

struct FreeVinMismatchView: View {
    let vehicleDisplayName: String
    let onTryAgain: () -> Void
    let onGetBuyerPass: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                ZStack {
                    Circle()
                        .fill(Color.statusCaution.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 44))
                        .foregroundColor(.statusCaution)
                }
                
                Text("It looks like this is a different vehicle.")
                    .font(.system(size: FontSize.h3, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("The vehicle you just scanned doesn't match your \(vehicleDisplayName). To scan unlimited vehicles for 60 days, add a Buyer Pass.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Try Again",
                    action: onTryAgain
                )
                
                Button(action: onGetBuyerPass) {
                    Text("Get Buyer Pass")
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.mintGreen)
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
    }
}

// MARK: - Deep Check Entry (from free dashboard "Run a Deep Check" CTA)

struct DeepCheckEntryView: View {
    let onBack: () -> Void
    @EnvironmentObject var nav: NavigationManager
    @Environment(\.openURL) private var openURL
    @State private var vinInput: String = ""
    @State private var isCreatingSession = false
    @State private var showNoVinAlert = false
    
    private var resolvedVIN: String {
        vinInput.trimmingCharacters(in: .whitespaces).uppercased()
    }
    
    private var canStartCheckout: Bool {
        resolvedVIN.count == 17 && resolvedVIN.isValidVIN
    }
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: onBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Deep Vehicle Check")
                        .font(.system(size: FontSize.h3, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text("Enter the VIN and get a full accident, title, damage check and more for $30 less than competitors.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    
                    TextField("VIN (17 characters)", text: $vinInput)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .font(.system(size: FontSize.bodyRegular, design: .monospaced))
                        .padding(12)
                        .background(Color(.systemGray6))
                        .cornerRadius(LayoutConstants.borderRadius)
                    
                    PrimaryButton(
                        title: isCreatingSession ? "Starting…" : "Run a Deep Check",
                        action: { Task { await startCheckout() } },
                        isEnabled: canStartCheckout && !isCreatingSession
                    )
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(24)
            }
        }
        .background(Color.deepBackground)
        .alert("VIN required", isPresented: $showNoVinAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Enter a 17-character VIN (no I, O, or Q).")
        }
    }
    
    private func startCheckout() async {
        let vin = resolvedVIN
        guard vin.count == 17 else {
            await MainActor.run { showNoVinAlert = true }
            return
        }
        guard vin.isValidVIN else {
            await MainActor.run {
                nav.showErrorToast("VIN must be 17 characters and cannot contain I, O, or Q.")
            }
            return
        }
        await MainActor.run { isCreatingSession = true }
        defer { Task { @MainActor in isCreatingSession = false } }
        do {
            let url = try await DeepCheckService.shared.createSession(vin: vin)
            await MainActor.run { openURL(url) }
        } catch {
            await MainActor.run {
                nav.showErrorToast("Something went wrong. Please try again.", errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue, errorMessage: (error as? DeepCheckError)?.message ?? error.localizedDescription, scanStep: "deep_check")
            }
        }
    }
}

// MARK: - OBD Device Section

struct OBDDeviceSection: View {
    var onDismiss: (() -> Void)? = nil

    private let device = OBDDevice(
        name: "WiFi ELM327 Generic Scanner",
        description: "Works great with MintCheck and is about $20.",
        url: "https://www.amazon.com/dp/B0BRKJ38ZQ?tag=mintcheck-20",
        imageName: "generic-scanner"
    )
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("MintCheck-Tested Car Scanners")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            OBDDeviceCard(device: device, onDismiss: onDismiss)
        }
    }
}

struct OBDDevice: Identifiable {
    let id = UUID()
    let name: String
    let rating: String?
    let reviews: String?
    let description: String?
    let url: String
    let imageName: String?
    
    init(name: String, rating: String? = nil, reviews: String? = nil, description: String? = nil, url: String, imageName: String? = nil) {
        self.name = name
        self.rating = rating
        self.reviews = reviews
        self.description = description
        self.url = url
        self.imageName = imageName
    }
}

struct OBDDeviceCard: View {
    let device: OBDDevice
    var onDismiss: (() -> Void)? = nil
    
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .fill(Color.deepBackground)
                        .frame(width: 80, height: 80)
                        .clipped()
                    
                    if let imageName = device.imageName {
                        Image(imageName)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: LayoutConstants.borderRadius))
                    } else {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 28))
                            .foregroundColor(.textSecondary)
                    }
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    if let description = device.description {
                        Text(description)
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                    } else if let rating = device.rating, let reviews = device.reviews {
                        Text("\(rating) \u{2022} \(reviews)")
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        if let url = URL(string: device.url) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("Buy Now")
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.textPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                    }

                    if let dismiss = onDismiss {
                        Button(action: dismiss) {
                            Text("I have a wifi scanner already")
                                .font(.system(size: FontSize.bodySmall, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding(.top, 4)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(LayoutConstants.padding6)
        }
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Dashboard Plan Card (slim upgrade card)
struct DashboardPlanCard: View {
    let title: String
    let bodyText: String
    let cta: String
    let url: String
    /// When set, CTA runs this instead of opening url
    var onCtaTap: (() -> Void)? = nil
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Text(bodyText)
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: {
                if let action = onCtaTap {
                    action()
                } else if let u = URL(string: url) {
                    UIApplication.shared.open(u)
                }
            }) {
                Text(cta)
                    .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    .foregroundColor(.mintGreen)
            }
        }
        .padding(LayoutConstants.padding6)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Scanner Dismiss Toast

private struct ScannerDismissToast: View {
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundColor(.mintGreen)
                .font(.system(size: 18))
            Text("Great! If you need help purchasing a scanner, visit our Support page.")
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.textSecondary)
                .lineSpacing(2)
        }
        .padding(LayoutConstants.padding4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.mintGreen.opacity(0.06))
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.mintGreen.opacity(0.2), lineWidth: 1)
        )
        .transition(.opacity)
    }
}

// MARK: - Active Buyer Pass Card

struct ActiveBuyerPassCard: View {
    let subscription: BuyerPassSubscription
    let todayScans: Int
    @EnvironmentObject var nav: NavigationManager

    private let maxDaily = 10
    @State private var isRenewing = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row: title + badge
            HStack {
                Text("Buyer Pass")
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Text("Active")
                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                    .foregroundColor(Color(red: 0.09, green: 0.56, blue: 0.33))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color(red: 0.09, green: 0.56, blue: 0.33).opacity(0.12))
                    .cornerRadius(12)
            }

            Text("Scan up to 10 vehicles per day for 60 days.")
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
                .lineSpacing(2)

            // Stat counters
            HStack(spacing: 0) {
                statItem(
                    value: "\(subscription.daysRemaining)",
                    label: "Days Left"
                )
                Spacer()
                statItem(
                    value: "\(todayScans)/\(maxDaily)",
                    label: "Scans Today"
                )
                Spacer()
                statItem(
                    value: "Unlimited",
                    label: "Vehicles"
                )
            }

            // Renew button — only visible in the last 7 days
            if subscription.daysRemaining <= 7 {
                PrimaryButton(
                    title: isRenewing ? "Opening…" : "Renew Buyer Pass",
                    action: {
                        guard !isRenewing else { return }
                        isRenewing = true
                        Task {
                            do {
                                let checkoutURL = try await BuyerPassService.shared.createCheckoutSession()
                                await MainActor.run { UIApplication.shared.open(checkoutURL) }
                            } catch {
                                await MainActor.run {
                                    nav.showErrorToast("Something went wrong. Please try again.", errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue, errorMessage: error.localizedDescription, scanStep: "checkout")
                                }
                            }
                            await MainActor.run { isRenewing = false }
                        }
                    },
                    isEnabled: !isRenewing
                )
            }
        }
        .padding(LayoutConstants.padding6)
        .background(
            Color.mintGreen.opacity(0.06)
        )
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.mintGreen.opacity(0.35), lineWidth: 1.5)
        )
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: FontSize.h3, weight: .bold))
                .foregroundColor(.textPrimary)
            Text(label)
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
        DashboardView(
            onStartCheck: {},
            onViewHistory: { _ in },
            onMenuTap: {}
        )
        .environmentObject(AuthService())
        .environmentObject(ScanService())
}
