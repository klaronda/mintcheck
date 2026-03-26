//
//  ContentView.swift
//  MintCheck
//
//  Root navigation controller
//

import SwiftUI
import Combine
import Supabase

/// Navigation state manager for the app
class NavigationManager: ObservableObject {
    @Published var currentScreen: Screen = .loading  // Start on splash screen
    @Published var hasSeenOnboarding: Bool = false
    @Published var currentScanData: ScanData = ScanData()
    @Published var selectedSystemDetail: String? = nil
    @Published var selectedSystemDetailStatus: String? = nil
    @Published var startInCreateMode: Bool = false
    @Published var authCheckComplete: Bool = false
    @Published var accountDeletedMessage: String? = nil  // Toast message after account deletion
    @Published var isAILoading: Bool = false  // Track AI analysis loading state
    @Published var resetPasswordExpired: Bool = false   // Deep link reset token was expired
    @Published var showFeedbackModal: Bool = false
    /// URL for in-app Deep Check report viewer; when set, show DeepCheckReportView
    @Published var deepCheckReportURL: String?
    /// When set, Done on Deep Check report returns here (e.g. .results); otherwise dashboard.
    @Published var returnToScreenAfterDeepCheckReport: Screen? = nil
    /// Prevents duplicate save when close/tab/return trigger save concurrently
    @Published var isSavingScan: Bool = false
    /// Cached first vehicle for free users (loaded before scan flow to compare VIN after scan)
    @Published var freeUserVehicle: VehicleInfo? = nil
    /// Incremented each time we enter the scan flow to force SwiftUI to recreate ScanFlowView with fresh state
    @Published var scanFlowId: Int = 0
    /// Session ID for Deep Check purchase (from Stripe redirect URL)
    @Published var deepCheckSessionId: String? = nil
    /// Whether the user has any completed deep check reports (for menu display)
    @Published var hasDeepCheckReports: Bool = false
    /// When true, the current scan is paid via a one-time scan credit (skip VIN lock, consume credit after save)
    @Published var isUsingPurchasedScan: Bool = false
    /// User-facing toast message (nil = no toast). Rendered by ContentView overlay.
    @Published var toastMessage: String? = nil
    /// When set, toast shows "Report this issue" and this context is used for feedback modal.
    @Published var toastFailureContext: (errorCode: String, message: String, scanStep: String)? = nil
    var feedbackSource: FeedbackSource = .in_app
    var feedbackPrefillMessage: String = ""
    var feedbackErrorCode: String? = nil
    var feedbackErrorMessage: String? = nil
    var feedbackScanStep: String? = nil
    
    init() {
        // Load persisted state
        hasSeenOnboarding = UserDefaults.standard.bool(forKey: "hasSeenOnboarding")
    }
    
    func completeOnboarding() {
        hasSeenOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasSeenOnboarding")
    }
    
    func resetOnboarding() {
        hasSeenOnboarding = false
        UserDefaults.standard.set(false, forKey: "hasSeenOnboarding")
    }
    
    func resetScanData() {
        currentScanData = ScanData()
        freeUserVehicle = nil
        isUsingPurchasedScan = false
        scanFlowId += 1
    }
    
    /// Start scan flow with Buyer Pass (early-access users: any vehicle, use BP quota). Resets scan data then sets flag.
    func startScanWithBuyerPass() {
        resetScanData()
        currentScanData.useBuyerPassForThisScan = true
        currentScreen = .scanFlow
    }
    
    /// Show a user-facing toast. When errorCode is non-nil, the toast shows "Report this issue".
    func showErrorToast(_ message: String, errorCode: String? = nil, errorMessage: String? = nil, scanStep: String? = nil) {
        Task { @MainActor in
            toastMessage = message
            if let code = errorCode {
                toastFailureContext = (code, errorMessage ?? message, scanStep ?? "unknown")
            } else {
                toastFailureContext = nil
            }
        }
    }
    
    /// Clear the toast (e.g. after user taps "Report this issue" or dismisses).
    func clearToast() {
        Task { @MainActor in
            toastMessage = nil
            toastFailureContext = nil
        }
    }
}

/// All possible screens in the app
enum Screen {
    case loading      // Splash screen while checking auth
    case home
    case signIn
    case onboarding
    case dashboard
    case allScans
    case support      // Help articles
    case settings     // Account settings
    case scanFlow
    case vehicleBasics
    case deviceConnection
    case scanning
    case disconnectReconnect
    case quickHumanCheck
    case results
    case systemDetail
    case resetPassword       // Set new password from deep link (recovery session)
    case resetPasswordExpired // Link expired, show resend
    case emailConfirmationSuccess // Email confirmed via deep link
    case deepCheckSuccess    // Returned from Stripe Deep Check payment
    case deepCheckReport     // In-app WebView for a single Deep Check report
    case myDeepChecks        // List of user's Deep Vehicle Check purchases
    case deepCheckEntry      // VIN entry + checkout for Deep Check (free dashboard CTA)
    case freeVinMismatch     // Free user scanned a different vehicle than their first
    case buyerPassSuccess    // Returned from Stripe Buyer Pass payment
}

/// How the scan was run (for offline fallback).
enum ScanMode: String, Codable {
    case online_scan
    case offline_scan
}

/// Report storage state for upload/offline handling.
enum ReportStorage: String, Codable {
    case local_only     // Offline scan, not yet uploaded
    case pending_upload // Save/upload failed or deferred
    case uploaded       // Successfully saved to cloud
}

/// Data collected during a scan session
struct ScanData {
    var scanId: UUID?  // ID of the scan (for historical views or after saving)
    var vehicleInfo: VehicleInfo?
    var deviceType: DeviceType?
    var vin: String?
    var humanCheck: QuickCheckData?
    var recommendation: RecommendationType?
    var scanResults: OBDScanResults?
    var historyReport: VehicleHistoryReport?  // Free NHTSA data (recalls, complaints, safety)
    var valuationResult: ValuationService.ValuationResult?  // Vehicle value estimate
    var dtcAnalysis: DTCAnalysisService.AnalysisResponse?  // AI-powered DTC analysis
    var isHistoricalView: Bool = false  // True when viewing a past scan
    var aiNetworkError: Bool = false  // True if AI call failed due to network error
    var scanDate: Date?  // Date the scan was completed (for freshness badge)
    var shareCode: String?  // Share link code if report has been shared
    var scanMode: ScanMode = .online_scan
    var reportStorage: ReportStorage = .uploaded  // .local_only or .pending_upload when offline/failed
    var vinVerified: Bool?  // True if VIN confirmed (decode or ECU match)
    var vinMismatch: Bool?  // True if ECU VIN != user-entered VIN
    var vinPartial: Bool? = nil  // True when ECU returned non-empty VIN with length != 17
    var freeUserVinBlocked: Bool = false  // True if free user scanned a different vehicle
    /// When true, early-access user is using Buyer Pass for this scan (any vehicle, use BP quota)
    var useBuyerPassForThisScan: Bool = false
}

enum DeviceType: Codable {
    case wifi
    case bluetooth
}

struct ContentView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var scanService: ScanService
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var connectionManager: ConnectionManagerService
    @Environment(\.scenePhase) private var scenePhase
    
    @State private var selectedTab: TabItem = .home
    @State private var isMenuOpen = false
    @State private var selectedSupportArticle: SupportArticle?
    @State private var showShareSheet = false
    @State private var showVinMismatchBlockAlert = false  // Early Access: block scan when VIN mismatch unresolved
    @State private var showFreeScansMaxedAlert = false  // Free user: all 3 free scans used
    @State private var showBuyerPassDailyLimitAlert = false  // Buyer Pass: 10/day limit reached
    /// Delay before showing the offline banner so we don't flash it on initial load while network is still coming up.
    @State private var offlineBannerAllowed = false
    
    /// Screens that show the bottom tab bar
    private var showsTabBar: Bool {
        [.dashboard, .allScans, .support, .settings, .results].contains(nav.currentScreen)
    }
    
    /// Screens where we already handle offline (scan flow, results); don't show global offline banner.
    private var isScanFlowOrResults: Bool {
        switch nav.currentScreen {
        case .scanFlow, .vehicleBasics, .deviceConnection, .scanning, .disconnectReconnect, .quickHumanCheck, .results:
            return true
        default:
            return false
        }
    }
    
    /// Show global "No connection" bar when offline and not on a screen that has its own handling.
    /// Only after a short delay so we don't show it on initial app load while the network is still coming up.
    private var shouldShowOfflineBanner: Bool {
        connectionManager.internetStatus == .offline && !isScanFlowOrResults && offlineBannerAllowed
    }
    
    /// Summary for share/save: AI summary when non-empty, otherwise default so report always has text
    private static let defaultSummaryText = "Vehicle scan completed. Review the report for full details."
    
    /// Build authoritative system statuses from OBD scan results, matching ResultsView logic.
    private static func buildSystemStatuses(from scanResults: OBDScanResults?) -> [ShareService.SystemStatusJSON] {
        let dtcs = scanResults?.dtcs ?? []
        let emissionsDTCs = dtcs.filter { $0.hasPrefix("P04") || $0.hasPrefix("P044") }
        
        func status(hasData: Bool, isOK: Bool, unknownDetails: [String], unknownExplanation: String,
                     goodDetails: [String], goodExplanation: String,
                     attentionStatus: String, attentionDetails: [String], attentionExplanation: String)
        -> (status: String, details: [String], explanation: String) {
            if !hasData { return ("Unknown", unknownDetails, unknownExplanation) }
            if isOK { return ("Good", goodDetails, goodExplanation) }
            return (attentionStatus, attentionDetails, attentionExplanation)
        }
        
        let unknownMsg = "This system wasn't tested or didn't report enough data to evaluate."
        
        // Engine
        let hasEngineData = (scanResults?.rpm != nil || scanResults?.coolantTemp != nil) || !dtcs.isEmpty
        var engineAttnDetails = ["\(dtcs.count) trouble code\(dtcs.count == 1 ? "" : "s") detected"]
        for dtc in dtcs.prefix(3) { engineAttnDetails.append(dtc) }
        let engine = status(hasData: hasEngineData, isOK: dtcs.isEmpty,
                            unknownDetails: ["No engine data was reported by the vehicle"], unknownExplanation: unknownMsg,
                            goodDetails: ["No trouble codes detected", "All sensors responding correctly", "Timing and performance normal"],
                            goodExplanation: "The engine is operating normally with no issues detected.",
                            attentionStatus: "Needs Attention", attentionDetails: engineAttnDetails,
                            attentionExplanation: "The engine has trouble codes that need attention.")
        
        // Fuel
        let hasFuelData = scanResults?.fuelLevel != nil || scanResults?.shortTermFuelTrim != nil || scanResults?.longTermFuelTrim != nil
        let fuelOK = (scanResults?.fuelLevel ?? 50) > 10
        let fuel = status(hasData: hasFuelData, isOK: fuelOK,
                          unknownDetails: ["No fuel system data was reported by the vehicle"], unknownExplanation: unknownMsg,
                          goodDetails: ["Fuel system operating normally", "No leaks detected", "Injectors responding correctly"],
                          goodExplanation: "The fuel system is delivering the correct amount of fuel and maintaining proper pressure.",
                          attentionStatus: "Low", attentionDetails: ["Fuel level low", "Check fuel system if recently filled"],
                          attentionExplanation: "The fuel level is low.")
        
        // Emissions
        let hasEmissionsData = !emissionsDTCs.isEmpty || scanResults?.barometricPressure != nil
        let emissionsOK = emissionsDTCs.isEmpty
        let emissionsAttnDetails = ["Emissions-related codes detected"] + emissionsDTCs.prefix(2).map { $0 }
        let emissions = status(hasData: hasEmissionsData, isOK: emissionsOK,
                               unknownDetails: ["No emissions data was reported by the vehicle"], unknownExplanation: unknownMsg,
                               goodDetails: ["Catalytic converter functioning normally", "All emissions monitors ready", "Should pass emissions testing"],
                               goodExplanation: "All emissions systems are functioning correctly.",
                               attentionStatus: "Needs Attention", attentionDetails: emissionsAttnDetails,
                               attentionExplanation: "Some emissions systems may need attention.")
        
        // Electrical
        let hasElectricalData = scanResults?.batteryVoltage != nil
        let voltage = scanResults?.batteryVoltage ?? 0
        let electricalOK = voltage >= 12.4 && voltage <= 14.8
        let electrical = status(hasData: hasElectricalData, isOK: electricalOK,
                                unknownDetails: ["No battery/electrical data was reported by the vehicle"], unknownExplanation: unknownMsg,
                                goodDetails: ["Battery voltage normal", "Charging system functioning", "Electrical systems stable"],
                                goodExplanation: "The electrical system is functioning properly.",
                                attentionStatus: "Needs Attention",
                                attentionDetails: voltage < 12.4 ? ["Battery voltage low (\(String(format: "%.1f", voltage))V)"] : ["Battery voltage high (\(String(format: "%.1f", voltage))V)"],
                                attentionExplanation: "The battery or charging system may need attention.")
        
        return [
            ShareService.SystemStatusJSON(name: "Engine", status: engine.status, details: engine.details, explanation: engine.explanation),
            ShareService.SystemStatusJSON(name: "Fuel System", status: fuel.status, details: fuel.details, explanation: fuel.explanation),
            ShareService.SystemStatusJSON(name: "Emissions", status: emissions.status, details: emissions.details, explanation: emissions.explanation),
            ShareService.SystemStatusJSON(name: "Electrical", status: electrical.status, details: electrical.details, explanation: electrical.explanation),
        ]
    }
    private var effectiveSummaryForShare: String {
        let s = nav.currentScanData.dtcAnalysis?.summary
        let trimmed = s.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { $0.isEmpty ? nil : $0 }
        return trimmed ?? Self.defaultSummaryText
    }
    
    var body: some View {
        ZStack {
            // Dashboard is always at the bottom of the stack when logged in
            if nav.authCheckComplete && authService.currentUser != nil {
                DashboardView(
                    onStartCheck: { nav.resetScanData(); nav.currentScreen = .scanFlow },
                    onStartBuyerPassCheck: { nav.startScanWithBuyerPass() },
                    onViewHistory: handleViewHistory,
                    onMenuTap: { isMenuOpen = true }
                )
            }
            
            switch nav.currentScreen {
            case .loading:
                // Plain mint only; logo only on native LaunchScreen to avoid logo jump
                Color.mintGreen
                    .ignoresSafeArea()
                
            case .home:
                HomeView(
                    onStartCheck: handleStartCheck,
                    onSignIn: { 
                        nav.startInCreateMode = true
                        nav.currentScreen = .signIn 
                    },
                    onBuyStarterKit: {
                        if let url = URL(string: "https://mintcheckapp.com/starter-kit") {
                            UIApplication.shared.open(url)
                        }
                    }
                )
                
            case .signIn:
                SignInView(
                    onBack: { 
                        nav.startInCreateMode = false
                        nav.currentScreen = .home 
                    },
                    onSignIn: handleSignIn,
                    startInCreateMode: nav.startInCreateMode
                )
                
            case .onboarding:
                OnboardingView(
                    onComplete: handleOnboardingComplete,
                    onBack: { nav.currentScreen = .home }
                )
                
            case .dashboard:
                // Dashboard is rendered above, this case is just for the switch
                EmptyView()
                
            case .allScans:
                AllScansView(
                    onViewScan: handleViewHistory,
                    onBack: { nav.currentScreen = .dashboard }
                )
                
            case .support:
                SupportView(onMenuTap: { isMenuOpen = true })
                
            case .settings:
                SettingsView(onMenuTap: { isMenuOpen = true })

            case .scanFlow:
                ScanFlowView(
                    flowId: nav.scanFlowId,
                    onExit: { nav.currentScreen = .dashboard },
                    onExitToScannerHelp: { article in
                        nav.currentScreen = .dashboard
                        selectedSupportArticle = article
                    }
                )
                .id(nav.scanFlowId)
                
            case .vehicleBasics:
                VehicleBasicsView(
                    onBack: { nav.currentScreen = .dashboard },
                    onNext: handleVehicleBasicsNext
                )
                
            case .deviceConnection:
                DeviceConnectionView(
                    onBack: { nav.currentScreen = .vehicleBasics },
                    onConnect: handleDeviceConnect
                )
                
            case .scanning:
                ScanningView(
                    onComplete: handleScanComplete,
                    onStartOver: { nav.currentScreen = .deviceConnection },
                    obdService: OBDService(),
                    onReportIssue: { errorMsg in
                        nav.feedbackSource = .error_cta
                        nav.feedbackPrefillMessage = "Scan failed."
                        nav.feedbackErrorCode = ErrorEventCode.ERR_OBD_DROP.rawValue
                        nav.feedbackErrorMessage = errorMsg ?? "An error occurred during the scan."
                        nav.feedbackScanStep = "scanning"
                        nav.showFeedbackModal = true
                    }
                )
                .environmentObject(scanService)
                
            case .disconnectReconnect:
                DisconnectReconnectView(onComplete: handleDisconnectComplete)
                
            case .quickHumanCheck:
                QuickHumanCheckView(onComplete: handleQuickCheckComplete)
                
            case .results:
                // Show loading screen if AI is still loading
                if nav.isAILoading {
                    ResultsLoadingView()
                } else if let vehicleInfo = nav.currentScanData.vehicleInfo,
                   let recommendation = nav.currentScanData.recommendation {
                    ResultsView(
                        vehicleInfo: vehicleInfo,
                        recommendation: recommendation,
                        scanResults: nav.currentScanData.scanResults,
                        historyReport: nav.currentScanData.historyReport,
                        valuationResult: nav.currentScanData.valuationResult,
                        askingPrice: nav.currentScanData.humanCheck?.askingPrice,
                        dtcAnalysis: nav.currentScanData.dtcAnalysis,
                        aiNetworkError: nav.currentScanData.aiNetworkError,
                        scanDate: nav.currentScanData.scanDate ?? Date(),
                        reportStorage: nav.currentScanData.reportStorage,
                        scanMode: nav.currentScanData.scanMode,
                        onViewDetails: handleViewSystemDetail,
                        onShare: handleShare,
                        onClose: handleCloseResults,
                        onDelete: handleDeleteScan,
                        onUploadNow: handleUploadNow,
                        onReportIssue: nil,
                        onOpenDeepCheckReport: { url in
                            nav.deepCheckReportURL = url
                            nav.returnToScreenAfterDeepCheckReport = .results
                            nav.currentScreen = .deepCheckReport
                        },
                        vinVerified: nav.currentScanData.vinVerified,
                        vinMismatch: nav.currentScanData.vinMismatch,
                        vinPartial: nav.currentScanData.vinPartial
                    )
                } else {
                    // Fallback: missing data - this should not happen
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 48))
                            .foregroundColor(.statusCaution)
                        Text("Unable to load scan results")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        Text("We couldn't load this report.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                            .multilineTextAlignment(.center)
                        PrimaryButton(
                            title: "Return to Dashboard",
                            action: {
                                nav.resetScanData()
                                nav.currentScreen = .dashboard
                            }
                        )
                        .padding(.horizontal, 40)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.deepBackground)
                }
                
            case .systemDetail:
                if let section = nav.selectedSystemDetail {
                    SystemDetailView(
                        section: section,
                        status: nav.selectedSystemDetailStatus ?? "Unknown",
                        onBack: { nav.currentScreen = .results }
                    )
                }
                
            case .resetPassword, .resetPasswordExpired:
                ResetPasswordView(
                    isExpired: nav.resetPasswordExpired,
                    onDone: {
                        nav.resetPasswordExpired = false
                        nav.currentScreen = .signIn
                    },
                    onResend: {
                        nav.resetPasswordExpired = false
                        nav.currentScreen = .signIn
                    }
                )
                .environmentObject(authService)
                
            case .emailConfirmationSuccess:
                EmailConfirmationView(
                    onContinue: {
                        if authService.currentUser == nil {
                            nav.currentScreen = .signIn
                        } else {
                            // First time entering after email confirm: show onboarding like handleSignIn(isNewSignup: true)
                            nav.resetOnboarding()
                            nav.currentScreen = nav.hasSeenOnboarding ? .dashboard : .onboarding
                        }
                    }
                )
                .environmentObject(authService)

            case .deepCheckSuccess:
                DeepCheckSuccessView(
                    onDone: {
                        nav.currentScreen = .dashboard
                    }
                )
                .environmentObject(authService)

            case .deepCheckReport:
                if let urlString = nav.deepCheckReportURL, !urlString.isEmpty, let url = URL(string: urlString) {
                    DeepCheckReportView(url: url, onDone: {
                        nav.deepCheckReportURL = nil
                        if let target = nav.returnToScreenAfterDeepCheckReport {
                            nav.currentScreen = target
                            nav.returnToScreenAfterDeepCheckReport = nil
                        } else {
                            nav.currentScreen = .dashboard
                        }
                    })
                } else {
                    Color.clear.onAppear { nav.currentScreen = .dashboard }
                }

            case .myDeepChecks:
                MyDeepChecksView(onBack: { nav.currentScreen = .dashboard })
                    .environmentObject(nav)

            case .deepCheckEntry:
                DeepCheckEntryView(onBack: { nav.currentScreen = .dashboard })

            case .freeVinMismatch:
                FreeVinMismatchView(
                    vehicleDisplayName: nav.freeUserVehicle?.shortDisplayName ?? "your vehicle",
                    onTryAgain: {
                        nav.resetScanData()
                        nav.currentScreen = .dashboard
                    },
                    onGetBuyerPass: {
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

            case .buyerPassSuccess:
                BuyerPassSuccessView(
                    onDone: {
                        nav.currentScreen = .dashboard
                    }
                )
                .environmentObject(authService)
                .environmentObject(scanService)
            }
        }
        .alert("VIN mismatch detected", isPresented: $showVinMismatchBlockAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("We couldn't confirm the VIN for your last scan. Please contact support to resolve before starting a new scan.")
        }
        .confirmationDialog("All free scans used", isPresented: $showFreeScansMaxedAlert, titleVisibility: .visible) {
            Button("Get Buyer Pass — $14.99") {
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
            Button("Buy One Scan — $3.99") {
                Task {
                    do {
                        try await OneTimeScanService.shared.purchase()
                        await MainActor.run {
                            nav.resetScanData()
                            nav.isUsingPurchasedScan = true
                            nav.currentScreen = .scanFlow
                        }
                    } catch let error as OneTimeScanError {
                        if case .purchaseFailed("Purchase was cancelled.") = error { return }
                        await MainActor.run {
                            nav.showErrorToast(error.message, errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue, errorMessage: error.message, scanStep: "checkout")
                        }
                    } catch {
                        await MainActor.run {
                            nav.showErrorToast("Something went wrong. Please try again.", errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue, errorMessage: error.localizedDescription, scanStep: "checkout")
                        }
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("You've used all 3 free scans. Buy a single scan or get a Buyer Pass for unlimited scanning.")
        }
        .alert("Daily scan limit reached", isPresented: $showBuyerPassDailyLimitAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("You've reached your 10 scan limit for today. Come back tomorrow to scan more vehicles.")
        }
        .overlay {
            if isMenuOpen {
                ZStack(alignment: .trailing) {
                    Color.black.opacity(0.45)
                        .ignoresSafeArea()
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isMenuOpen = false
                            }
                        }
                    
                    MenuPanel(
                        onSelect: { tab in
                            withAnimation(.easeInOut(duration: 0.2)) {
                                isMenuOpen = false
                            }
                            handleTabSelection(tab)
                        }
                    )
                    .transition(.move(edge: .trailing))
                }
                .animation(.easeInOut(duration: 0.2), value: isMenuOpen)
            }
        }
        .sheet(item: $selectedSupportArticle) { article in
            if article.id == "wifi-scanners" {
                ScannerHelpArticleView(article: article) {
                    selectedSupportArticle = nil
                }
                .environmentObject(authService)
                .environmentObject(nav)
            } else {
                SupportArticleDetailView(article: article) {
                    selectedSupportArticle = nil
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let vehicleInfo = nav.currentScanData.vehicleInfo,
               let recommendation = nav.currentScanData.recommendation {
                ShareReportSheet(
                    scanId: nav.currentScanData.scanId ?? UUID(),
                    vehicleInfo: vehicleInfo,
                    recommendation: recommendation,
                    scanDate: nav.currentScanData.scanDate ?? Date(),
                    summary: effectiveSummaryForShare,
                    findings: nav.currentScanData.scanResults?.keyFindings,
                    valuationLow: nav.currentScanData.valuationResult?.lowEstimate,
                    valuationHigh: nav.currentScanData.valuationResult?.highEstimate,
                    odometerReading: nav.currentScanData.humanCheck?.odometerReading,
                    askingPrice: nav.currentScanData.humanCheck?.askingPrice,
                    dtcAnalyses: nav.currentScanData.dtcAnalysis?.analyses,
                    totalRepairCostLow: nav.currentScanData.dtcAnalysis?.totalRepairCostLow,
                    totalRepairCostHigh: nav.currentScanData.dtcAnalysis?.totalRepairCostHigh,
                    nhtsaData: nav.currentScanData.historyReport?.toJSON(),
                    systemStatuses: Self.buildSystemStatuses(from: nav.currentScanData.scanResults),
                    existingShareCode: nav.currentScanData.shareCode,
                    onDismiss: { showShareSheet = false },
                    onShareCodeCreated: { newCode in
                        nav.currentScanData.shareCode = newCode
                    },
                    isOffline: connectionManager.internetStatus == .offline,
                    isScanSaving: nav.isSavingScan || nav.currentScanData.reportStorage == .pending_upload,
                    onReportIssue: {
                        nav.feedbackSource = .error_cta
                        nav.feedbackPrefillMessage = "Send report failed."
                        nav.feedbackErrorCode = ErrorEventCode.ERR_EMAIL_SEND_FAIL.rawValue
                        nav.feedbackErrorMessage = "Send report failed"
                        nav.feedbackScanStep = "shareReport"
                        nav.showFeedbackModal = true
                    }
                )
                .environmentObject(authService)
            }
        }
        .sheet(isPresented: $nav.showFeedbackModal) {
            FeedbackModalView(
                isPresented: $nav.showFeedbackModal,
                defaultCategory: nav.feedbackSource == .error_cta ? .bug : .suggestion,
                defaultMessage: nav.feedbackPrefillMessage,
                source: nav.feedbackSource,
                errorCode: nav.feedbackErrorCode,
                errorMessage: nav.feedbackErrorMessage,
                scanStepForPrefill: nav.feedbackScanStep
            )
            .environmentObject(authService)
            .environmentObject(nav)
            .environmentObject(connectionManager)
        }
        .onChange(of: nav.showFeedbackModal) { _, visible in
            if !visible {
                nav.feedbackErrorCode = nil
                nav.feedbackErrorMessage = nil
                nav.feedbackScanStep = nil
            }
        }
        .onAppear {
            checkInitialNavigation()
            Task {
                _ = await connectionManager.checkInternetStatus()
                await FeedbackService.shared.flushQueueIfOnline(connectionManager: connectionManager)
            }
            // Allow offline banner only after a few seconds so we don't show it on initial load
            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                offlineBannerAllowed = true
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task {
                    await connectionManager.wifiManager.fetchCurrentSSID()
                    _ = await connectionManager.checkInternetStatus()
                }
            }
        }
        .onOpenURL { url in
            Task { @MainActor in
                let result = await DeepLinkService.handle(url: url)
                switch result {
                case .emailConfirmationSuccess:
                    await authService.checkSession()
                    nav.currentScreen = .emailConfirmationSuccess
                case .showResetPassword:
                    nav.resetPasswordExpired = false
                    nav.currentScreen = .resetPassword
                case .linkExpired:
                    nav.resetPasswordExpired = true
                    nav.currentScreen = .resetPassword
                case .deepCheckSuccess(let sessionId):
                    nav.deepCheckSessionId = sessionId
                    nav.currentScreen = .deepCheckSuccess
                case .buyerPassSuccess:
                    nav.currentScreen = .buyerPassSuccess
                case .invalidLink, .ignored:
                    break
                }
            }
        }
        .onChange(of: authService.currentUser) { _, newUser in
            if nav.authCheckComplete {
                if newUser != nil && nav.currentScreen == .home {
                    // User logged in - go to dashboard
                    nav.currentScreen = .dashboard
                    selectedTab = .home
                } else if newUser == nil {
                    // User logged out - go to home
                    nav.resetScanData()
                    nav.currentScreen = .home
                    selectedTab = .home
                }
            }
        }
        .overlay(alignment: .top) {
            if shouldShowOfflineBanner {
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "wifi.slash")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.textSecondary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("No connection.")
                                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            Text(connectionManager.wifiManager.isConnectedToOBDNetwork
                                 ? "Looks like we lost internet connection. Make sure you're not connected to your OBD-II scanner's Wi‑Fi."
                                 : "Looks like we lost internet connection.")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textSecondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                            Button(action: {
                                if let url = URL(string: UIApplication.openSettingsURLString) {
                                    UIApplication.shared.open(url)
                                }
                            }) {
                                Text("Open Settings")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.mintGreen)
                            }
                            .padding(.top, 2)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        Spacer(minLength: 0)
                    }
                    .padding(.horizontal, LayoutConstants.padding4)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(Color.softBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(Color.borderColor),
                        alignment: .bottom
                    )
                    Spacer(minLength: 0)
                }
            }
        }
        .animation(.easeInOut(duration: 0.25), value: shouldShowOfflineBanner)
        .overlay {
            if let message = nav.toastMessage {
                VStack {
                    Spacer()
                    // Full-width butter bar: error (red) when Report this issue, neutral (gray) otherwise
                    VStack(spacing: 10) {
                        Text(message)
                            .font(.system(size: FontSize.bodySmall, weight: .medium))
                            .foregroundColor(nav.toastFailureContext != nil ? .white : .textPrimary)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                        if let ctx = nav.toastFailureContext {
                            Button(action: {
                                nav.feedbackSource = .error_cta
                                nav.feedbackPrefillMessage = message
                                nav.feedbackErrorCode = ctx.errorCode
                                nav.feedbackErrorMessage = ctx.message
                                nav.feedbackScanStep = ctx.scanStep
                                nav.showFeedbackModal = true
                                nav.clearToast()
                            }) {
                                Text("Report this issue")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                            .stroke(Color.white, lineWidth: 1.5)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, LayoutConstants.padding4)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity)
                    .background(nav.toastFailureContext != nil ? Color.statusDanger : Color.softBackground)
                    .overlay(
                        Rectangle()
                            .frame(height: 1)
                            .foregroundColor(nav.toastFailureContext != nil ? Color.statusDanger.opacity(0.8) : Color.borderColor),
                        alignment: .top
                    )
                    .padding(.bottom, 80)
                }
                .transition(.opacity)
                .onTapGesture {
                    if nav.toastFailureContext == nil { nav.clearToast() }
                }
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) { nav.clearToast() }
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: nav.toastMessage)
        .onChange(of: nav.currentScreen) { _, newScreen in
            nav.clearToast()
            switch newScreen {
            case .dashboard, .allScans:
                selectedTab = .home
            case .support:
                selectedTab = .help
            case .settings:
                selectedTab = .settings
            default:
                break
            }
        }
    }
    
    // MARK: - Tab Bar Handler
    
    private func handleTabSelection(_ tab: TabItem) {
        // If we're on results screen and navigating away, save the scan first
        if nav.currentScreen == .results && !nav.currentScanData.isHistoricalView {
            Task {
                let saved = await saveScanToSupabase()
                await MainActor.run {
                    if saved {
                        nav.resetScanData()
                        navigateToTab(tab)
                    }
                    // If save failed, toast is already set by saveScanToSupabase; don't navigate away
                }
            }
        } else {
            navigateToTab(tab)
        }
    }
    
    private func navigateToTab(_ tab: TabItem) {
        switch tab {
        case .home:
            nav.currentScreen = .dashboard
        case .scan:
            nav.resetScanData()
            nav.currentScreen = .scanFlow
        case .help:
            nav.currentScreen = .support
        case .scanHistory:
            nav.currentScreen = .allScans
        case .deepCheckReports:
            nav.currentScreen = .myDeepChecks
        case .settings:
            nav.currentScreen = .settings
        }
    }

    // MARK: - Menu Panel
    
    private struct MenuPanel: View {
        let onSelect: (TabItem) -> Void
        @EnvironmentObject var scanService: ScanService
        @EnvironmentObject var nav: NavigationManager
        
        var body: some View {
            GeometryReader { geometry in
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Menu")
                            .font(.system(size: FontSize.h3, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        ForEach([TabItem.home, .scan, .help], id: \.self) { tab in
                            Button(action: { onSelect(tab) }) {
                                HStack(spacing: 12) {
                                    Image(tab.iconName)
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text(tab.title)
                                        .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        
                        // Account section
                        VStack(alignment: .leading, spacing: 20) {
                            Text("Account")
                                .font(.system(size: FontSize.h4, weight: .semibold))
                                .foregroundColor(Color(red: 26/255, green: 26/255, blue: 26/255))
                                .padding(.top, 16)
                            
                            if !scanService.scanHistory.isEmpty {
                                Button(action: { onSelect(.scanHistory) }) {
                                    HStack(spacing: 12) {
                                        Image("icon-scan-history")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(.textPrimary)
                                        
                                        Text("History")
                                            .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            if nav.hasDeepCheckReports {
                                Button(action: { onSelect(.deepCheckReports) }) {
                                    HStack(spacing: 12) {
                                        Image("icon-nav-reports")
                                            .renderingMode(.template)
                                            .resizable()
                                            .scaledToFit()
                                            .frame(width: 22, height: 22)
                                            .foregroundColor(.textPrimary)
                                        
                                        Text("Reports")
                                            .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                            
                            Button(action: { onSelect(.settings) }) {
                                HStack(spacing: 12) {
                                    Image("icon-nav-settings")
                                        .renderingMode(.template)
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 22, height: 22)
                                        .foregroundColor(.textPrimary)
                                    
                                    Text("Settings")
                                        .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                        .foregroundColor(.textPrimary)
                                    
                                    Spacer()
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 32)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width * (2.0 / 3.0), height: geometry.size.height)
                .background(Color.white)
                .overlay(
                    Rectangle()
                        .frame(width: 1)
                        .foregroundColor(.borderColor),
                    alignment: .leading
                )
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }

    private struct ScannerHelpArticleView: View {
        let article: SupportArticle
        let onDone: () -> Void

        @EnvironmentObject private var authService: AuthService
        @EnvironmentObject private var nav: NavigationManager

        private var device: OBDDevice {
            let web = "https://mintcheckapp.com/starter-kit"
            if authService.currentUser != nil {
                return OBDDevice(
                    name: "MintCheck Starter Kit",
                    description: "Wi-Fi scanner plus a 60-day Buyer Pass.",
                    url: web,
                    imageName: "starter-kit-scanner",
                    purchaseButtonTitle: "Buy Starter Kit"
                )
            }
            return OBDDevice(
                name: "MintCheck Starter Kit",
                description: "Wi-Fi scanner plus a 60-day Buyer Pass. Order on the web.",
                url: web,
                imageName: "starter-kit-scanner",
                purchaseButtonTitle: "Shop Starter Kit"
            )
        }
        
        var body: some View {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(article.content)
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                        
                        OBDDeviceCard(
                            device: device,
                            onPurchaseTap: authService.currentUser != nil
                                ? {
                                    Task {
                                        do {
                                            let checkoutURL = try await StarterKitService.shared.createCheckoutSession()
                                            await MainActor.run { UIApplication.shared.open(checkoutURL) }
                                        } catch let error as StarterKitError {
                                            await MainActor.run {
                                                nav.showErrorToast(
                                                    error.message,
                                                    errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue,
                                                    errorMessage: error.message,
                                                    scanStep: "starter_kit_checkout"
                                                )
                                            }
                                        } catch {
                                            await MainActor.run {
                                                nav.showErrorToast(
                                                    "Something went wrong. Please try again.",
                                                    errorCode: ErrorEventCode.ERR_CHECKOUT_FAIL.rawValue,
                                                    errorMessage: error.localizedDescription,
                                                    scanStep: "starter_kit_checkout"
                                                )
                                            }
                                        }
                                    }
                                }
                                : nil
                        )
                    }
                    .padding(24)
                }
                .background(Color.deepBackground)
                .navigationTitle(article.title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Done") { onDone() }
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.mintGreen)
                    }
                }
            }
        }
    }
    
    /// Check if user is already logged in on app launch
    private func checkInitialNavigation() {
        Task {
            while authService.isLoading {
                try? await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
            }
            await MainActor.run {
                nav.authCheckComplete = true
                if let user = authService.currentUser {
                    // Support reset: if profile has reset_onboarding, clear local onboarding and show onboarding again
                    if user.resetOnboarding == true {
                        nav.resetOnboarding()
                        nav.currentScreen = .onboarding
                        Task {
                            await authService.clearResetOnboardingFlag()
                        }
                    } else {
                        nav.currentScreen = .dashboard
                    }
                } else {
                    nav.currentScreen = .home
                }
            }
        }
    }
    
    // MARK: - Navigation Handlers
    
    private func handleStartCheck() {
        if authService.currentUser == nil {
            nav.currentScreen = .signIn
        } else if !nav.hasSeenOnboarding {
            nav.currentScreen = .onboarding
        } else if authService.isEarlyAccess {
            // Early access: one VIN only – block if they already have a different vehicle registered
            Task {
                guard let userId = authService.currentUser?.id else { return }
                do {
                    let blocked = try await scanService.hasVinMismatch(userId: userId)
                    await MainActor.run {
                        if blocked {
                            showVinMismatchBlockAlert = true
                        } else {
                            nav.resetScanData()
                            nav.currentScreen = .scanFlow
                        }
                    }
                } catch {
                    await MainActor.run {
                        nav.resetScanData()
                        nav.currentScreen = .scanFlow
                    }
                }
            }
        } else if !authService.hasFullAccess {
            // Free user: one VIN, up to 3 scans — or purchased credits
            Task {
                guard let userId = authService.currentUser?.id else { return }
                try? await scanService.loadVehicles(userId: userId)
                try? await scanService.loadScanHistory(userId: userId)
                await OneTimeScanService.shared.loadCredits()
                await MainActor.run {
                    if scanService.scanHistory.count >= 3 && OneTimeScanService.shared.scanCredits <= 0 {
                        showFreeScansMaxedAlert = true
                    } else if scanService.scanHistory.count >= 3 && OneTimeScanService.shared.scanCredits > 0 {
                        nav.resetScanData()
                        nav.isUsingPurchasedScan = true
                        nav.currentScreen = .scanFlow
                    } else {
                        nav.freeUserVehicle = scanService.vehicles.first
                        nav.resetScanData()
                        nav.currentScreen = .scanFlow
                    }
                }
            }
        } else if authService.hasBuyerPass {
            // Buyer Pass: 10 scans per day limit
            Task {
                guard let userId = authService.currentUser?.id else { return }
                try? await scanService.loadScanHistory(userId: userId)
                await MainActor.run {
                    if scanService.todayScansCount >= 10 {
                        showBuyerPassDailyLimitAlert = true
                    } else {
                        nav.resetScanData()
                        nav.currentScreen = .scanFlow
                    }
                }
            }
        } else {
            // Tester or other: no VIN limit – go straight to scan flow
            nav.resetScanData()
            nav.currentScreen = .scanFlow
        }
    }
    
    private func handleSignIn(user: UserProfile, isNewSignup: Bool) {
        if isNewSignup {
            nav.resetOnboarding()  // Reset onboarding for new users
        }
        if !nav.hasSeenOnboarding {
            nav.currentScreen = .onboarding
        } else {
            nav.currentScreen = .dashboard
        }
    }
    
    private func handleOnboardingComplete() {
        nav.completeOnboarding()
        if authService.currentUser != nil {
            nav.currentScreen = .dashboard
        } else {
            nav.currentScreen = .signIn
        }
    }

    private func handleVehicleBasicsNext(vehicleInfo: VehicleInfo) {
        nav.currentScanData.vehicleInfo = vehicleInfo
        nav.currentScanData.vin = vehicleInfo.vin
        if authService.isEarlyAccess {
            Task {
                await ensureEarlyAccessVehicleSaved(vehicleInfo)
                await MainActor.run {
                    nav.currentScreen = .deviceConnection
                }
            }
        } else {
            nav.currentScreen = .deviceConnection
        }
    }
    
    /// For early access: ensure the "one car" exists (and is locked) as soon as they confirm VIN, before first scan save.
    private func ensureEarlyAccessVehicleSaved(_ vehicleInfo: VehicleInfo) async {
        guard let userId = authService.currentUser?.id else { return }
        try? await scanService.loadVehicles(userId: userId)
        guard scanService.vehicles.first == nil else { return }
        guard let saved = try? await scanService.createVehicle(vehicleInfo, userId: userId) else { return }
        try? await scanService.setVehicleVinLocked(vehicleId: saved.id)
    }
    
    private func handleDeviceConnect(deviceType: DeviceType) {
        nav.currentScanData.deviceType = deviceType
        connectionManager.setDeviceType(deviceType)
        nav.currentScreen = .scanning
    }
    
    private func handleScanComplete(results: OBDScanResults) {
        nav.currentScanData.scanResults = results
        
        // Auto-disconnect from WiFi/Bluetooth after scan completes
        Task {
            // Disconnect based on device type
            await connectionManager.disconnectAll()
            
            // Navigate directly to QuickHumanCheck (skip disconnectReconnect screen)
            await MainActor.run {
                nav.currentScreen = .quickHumanCheck
            }
        }
        
        // Fetch free vehicle history in background (recalls, complaints, safety ratings)
        Task {
            await fetchVehicleHistory()
        }
    }
    
    /// Fetch free NHTSA data (recalls, complaints, safety ratings)
    private func fetchVehicleHistory() async {
        guard let vehicle = nav.currentScanData.vehicleInfo else { return }
        let report = await VehicleHistoryService.fetchReport(for: vehicle)
        await MainActor.run {
            nav.currentScanData.historyReport = report
        }
    }
    
    private func handleDisconnectComplete() {
        nav.currentScreen = .quickHumanCheck
    }
    
    private func handleQuickCheckComplete(data: QuickCheckData) {
        nav.currentScanData.humanCheck = data
        
        // Determine recommendation based on scan results and human check
        let recommendation = determineRecommendation(
            scanResults: nav.currentScanData.scanResults,
            humanCheck: data
        )
        nav.currentScanData.recommendation = recommendation
        nav.currentScanData.scanDate = Date()  // Set scan date for freshness badge
        
        // Start AI analysis (DTCs + Valuation) if DTCs are present
        // Wait for AI call to complete (max 5 seconds) before showing results
        if let scanResults = nav.currentScanData.scanResults,
           !scanResults.dtcs.isEmpty,
           let vehicleInfo = nav.currentScanData.vehicleInfo {
            
            // Set loading state
            nav.isAILoading = true
            
            Task {
                let startTime = Date()
                let maximumWaitTime: TimeInterval = 5.0
                
                // Start AI call
                let aiTask = Task {
                    try await DTCAnalysisService.shared.analyzeScanResults(
                        scanResults: scanResults,
                        vehicleInfo: vehicleInfo,
                        humanCheck: data,
                        recommendation: recommendation
                    )
                }
                
                // Race: AI call vs 5-second timeout
                var analysisResult: DTCAnalysisService.AnalysisResponse? = nil
                var analysisError: Error? = nil
                
                await withTaskGroup(of: Void.self) { group in
                    // Task 1: AI call
                    group.addTask {
                        do {
                            let result = try await aiTask.value
                            await MainActor.run {
                                analysisResult = result
                            }
                        } catch {
                            await MainActor.run {
                                analysisError = error
                            }
                        }
                    }
                    
                    // Task 2: Timeout
                    group.addTask {
                        try? await Task.sleep(nanoseconds: UInt64(maximumWaitTime * 1_000_000_000))
                        aiTask.cancel()  // Cancel AI if timeout reached
                    }
                    
                    // Wait for first to complete
                    await group.next()
                    group.cancelAll()
                }
                
                // Ensure minimum 5 second display time
                let elapsedTime = Date().timeIntervalSince(startTime)
                if elapsedTime < maximumWaitTime {
                    let remainingTime = maximumWaitTime - elapsedTime
                    try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
                }
                
                await MainActor.run {
                    // Store results if AI completed
                    if let analysis = analysisResult {
                        nav.currentScanData.dtcAnalysis = analysis
                        
                        // Store vehicle valuation from AI response
                        if let valuation = analysis.vehicleValuation {
                            nav.currentScanData.valuationResult = ValuationService.ValuationResult(
                                lowEstimate: valuation.lowEstimate,
                                highEstimate: valuation.highEstimate,
                                baseValue: (valuation.lowEstimate + valuation.highEstimate) / 2,
                                adjustments: [],
                                disclaimer: valuation.reasoning ?? "Prices vary by trim, mileage, condition, and region.",
                                kbbURL: nil,
                                carsComURL: nil
                            )
                        }
                    } else if let error = analysisError {
                        // Check if it's a network error
                        if let analysisError = error as? DTCAnalysisService.AnalysisError,
                           case .networkError = analysisError {
                            nav.currentScanData.aiNetworkError = true
                        }
                        nav.showErrorToast("Analysis failed. You can still view your scan.")
                    } else {
                        print("DTC analysis timed out or was cancelled")
                    }
                    
                    nav.isAILoading = false
                    nav.currentScreen = .results
                }
            }
        } else {
            // No DTCs - navigate immediately
            nav.currentScreen = .results
        }
    }
    
    
    private func handleViewSystemDetail(section: String, status: String) {
        nav.selectedSystemDetail = section
        nav.selectedSystemDetailStatus = status
        nav.currentScreen = .systemDetail
    }
    
    private func handleReturnToDashboard() {
        // Only save if this is a new scan (not viewing history)
        if nav.currentScanData.isHistoricalView {
            nav.resetScanData()
            nav.currentScreen = .dashboard
        } else {
            // Save scan to Supabase before returning
            Task {
                await saveScanToSupabase()
                await MainActor.run {
                    nav.resetScanData()
                    nav.currentScreen = .dashboard
                }
            }
        }
    }
    
    private func handleUploadNow() {
        Task {
            await saveScanToSupabase()
            await MainActor.run {
                if nav.currentScanData.reportStorage == .uploaded {
                    nav.showErrorToast("Upload complete")
                }
            }
        }
    }
    
    private func saveScanToSupabase() async -> Bool {
        // Already saved — don't create a duplicate
        if nav.currentScanData.scanId != nil { return true }
        
        guard let userId = authService.currentUser?.id,
              let vehicleInfo = nav.currentScanData.vehicleInfo,
              let recommendation = nav.currentScanData.recommendation else {
            await MainActor.run {
                nav.currentScanData.reportStorage = .pending_upload
                nav.showErrorToast("We couldn't save this scan.")
            }
            return false
        }
        
        let alreadySaving = await MainActor.run {
            if nav.isSavingScan { return true }
            nav.isSavingScan = true
            return false
        }
        if alreadySaving { return false }
        defer { Task { @MainActor in nav.isSavingScan = false } }
        
        do {
            var vehicleId: UUID
            if authService.isEarlyAccess, !nav.currentScanData.useBuyerPassForThisScan {
                // Early access (free scan): one VIN forever – reuse or create and lock
                try await scanService.loadVehicles(userId: userId)
                if let existing = scanService.vehicles.first {
                    let currentVin = (vehicleInfo.vin ?? "").trimmingCharacters(in: .whitespaces).uppercased()
                    let existingVin = (existing.vin ?? "").trimmingCharacters(in: .whitespaces).uppercased()
                    guard !currentVin.isEmpty, currentVin == existingVin else {
                        await MainActor.run {
                            nav.showErrorToast("You can only scan the vehicle you registered. This VIN doesn't match.")
                        }
                        return false
                    }
                    vehicleId = existing.id
                } else {
                    let savedVehicle = try await scanService.createVehicle(vehicleInfo, userId: userId)
                    try await scanService.setVehicleVinLocked(vehicleId: savedVehicle.id)
                    vehicleId = savedVehicle.id
                }
            } else if !authService.hasFullAccess && !nav.isUsingPurchasedScan {
                // Free user: reuse existing vehicle or create first one
                try await scanService.loadVehicles(userId: userId)
                if let existing = scanService.vehicles.first {
                    vehicleId = existing.id
                } else {
                    let savedVehicle = try await scanService.createVehicle(vehicleInfo, userId: userId)
                    vehicleId = savedVehicle.id
                }
            } else {
                // Tester or other: create vehicle per scan
                let savedVehicle = try await scanService.createVehicle(vehicleInfo, userId: userId)
                vehicleId = savedVehicle.id
            }
            
            // Build AI analysis JSON if available
            var aiAnalysisJSON: AIAnalysisJSON? = nil
            if let dtcAnalysis = nav.currentScanData.dtcAnalysis {
                let dtcAnalyses = dtcAnalysis.analyses.map { analysis in
                    DTCAnalysisJSON(
                        code: analysis.code,
                        name: analysis.name,
                        description: analysis.description,
                        repairCostLow: analysis.repairCostLow,
                        repairCostHigh: analysis.repairCostHigh,
                        urgency: analysis.urgency,
                        commonForVehicle: analysis.commonForVehicle
                    )
                }
                
                var valuationJSON: VehicleValuationJSON? = nil
                if let valuation = dtcAnalysis.vehicleValuation {
                    valuationJSON = VehicleValuationJSON(
                        lowEstimate: valuation.lowEstimate,
                        highEstimate: valuation.highEstimate,
                        reasoning: valuation.reasoning
                    )
                }
                
                aiAnalysisJSON = AIAnalysisJSON(
                    analyses: dtcAnalyses,
                    totalRepairCostLow: dtcAnalysis.totalRepairCostLow,
                    totalRepairCostHigh: dtcAnalysis.totalRepairCostHigh,
                    overallUrgency: dtcAnalysis.overallUrgency,
                    summary: dtcAnalysis.summary,
                    vehicleValuation: valuationJSON
                )
            }
            
            // Then save the scan
            let scanData = ScanDataJSON(
                deviceType: nav.currentScanData.scanResults?.deviceType,
                scanDuration: nil,
                keyFindings: nav.currentScanData.scanResults?.keyFindings,
                priceRange: nil,
                priceNote: nil,
                repairEstimate: nil,
                aiAnalysis: aiAnalysisJSON
            )
            
            let quickCheck = nav.currentScanData.humanCheck?.toJSON()
            let obdData = nav.currentScanData.scanResults?.toJSON()
            let nhtsaData = nav.currentScanData.historyReport?.toJSON()
            let valuationJSON = nav.currentScanData.valuationResult?.toJSON()
            
            // Use AI summary when present and non-empty; otherwise default so report always has summary text
            let aiSummaryRaw = nav.currentScanData.dtcAnalysis?.summary
            let aiSummary = aiSummaryRaw.map { $0.trimmingCharacters(in: .whitespaces) }.flatMap { $0.isEmpty ? nil : $0 }
            let summaryToSave = aiSummary ?? Self.defaultSummaryText
            
            // Retry save up to 3 times over ~1 minute (0s, ~20s, ~40s) for flaky connectivity
            let maxAttempts = 3
            let delayBetweenAttempts: UInt64 = 20_000_000_000 // 20 seconds in nanoseconds
            var lastError: Error?
            for attempt in 1...maxAttempts {
                do {
                    let saved = try await scanService.saveScan(
                        userId: userId,
                        vehicleId: vehicleId,
                        recommendation: recommendation,
                        scanData: scanData,
                        quickCheck: quickCheck,
                        obdData: obdData,
                        nhtsaData: nhtsaData,
                        odometerReading: nav.currentScanData.humanCheck?.odometerReading,
                        askingPrice: nav.currentScanData.humanCheck?.askingPrice,
                        estimatedValue: valuationJSON,
                        summary: summaryToSave,
                        vinVerified: nav.currentScanData.vinVerified,
                        vinMismatch: nav.currentScanData.vinMismatch,
                        analysisEnabled: !authService.hasFullAccess
                    )
                    await MainActor.run {
                        nav.currentScanData.scanId = saved.id
                        nav.currentScanData.reportStorage = .uploaded
                        nav.showErrorToast("Scan saved")
                    }
                    if nav.isUsingPurchasedScan {
                        await OneTimeScanService.shared.consumeCredit()
                        await MainActor.run { nav.isUsingPurchasedScan = false }
                    }
                    return true
                } catch {
                    lastError = error
                    if attempt < maxAttempts {
                        try? await Task.sleep(nanoseconds: delayBetweenAttempts)
                    }
                }
            }
            if let err = lastError { throw err }
        } catch {
            await MainActor.run {
                nav.currentScanData.reportStorage = .pending_upload
                nav.showErrorToast("Couldn't upload. Tap \"Upload now\" when you're back online.", errorCode: ErrorEventCode.ERR_SAVE_UPLOAD_FAIL.rawValue, errorMessage: error.localizedDescription, scanStep: "results")
            }
            ErrorEventLogger.shared.log(
                screen: "results",
                internetStatus: connectionManager.internetStatus.rawValue,
                errorCode: .ERR_SAVE_UPLOAD_FAIL,
                message: error.localizedDescription
            )
            return false
        }
        return true
    }
    
    private func handleShare() {
        Task {
            // Refresh connectivity before deciding if sharing should be considered offline.
            _ = await connectionManager.checkInternetStatus()
            await MainActor.run {
                showShareSheet = true
            }
        }
    }
    
    private func handleCloseResults() {
        // Save scan if new, then return to dashboard
        if nav.currentScanData.isHistoricalView {
            nav.resetScanData()
            nav.currentScreen = .dashboard
            selectedTab = .home
        } else {
            Task {
                await saveScanToSupabase()
                await MainActor.run {
                    nav.resetScanData()
                    nav.currentScreen = .dashboard
                    selectedTab = .home
                }
            }
        }
    }
    
    private func handleDeleteScan() {
        guard let userId = authService.currentUser?.id,
              let scanId = nav.currentScanData.scanId else {
            nav.resetScanData()
            nav.currentScreen = .dashboard
            return
        }
        
        Task {
            do {
                try await scanService.deleteScan(scanId: scanId, userId: userId)
                await MainActor.run {
                    nav.resetScanData()
                    nav.currentScreen = .dashboard
                }
            } catch {
                await MainActor.run {
                    nav.showErrorToast("Couldn't delete. Tap to try again.", errorCode: ErrorEventCode.ERR_DELETE_FAIL.rawValue, errorMessage: error.localizedDescription, scanStep: "results")
                }
                ErrorEventLogger.shared.log(
                    screen: "results",
                    errorCode: .ERR_DELETE_FAIL,
                    message: error.localizedDescription
                )
            }
        }
    }
    
    private func handleViewHistory(scanId: String) {
        guard let scanUUID = UUID(uuidString: scanId) else { return }
        
        Task {
            do {
                // Load the full scan details
                let scanResult = try await scanService.loadScanDetails(scanId: scanUUID)
                
                // Load the vehicle info
                if let vehicleId = scanResult.vehicleId {
                    let vehicles: [VehicleInfo] = try await SupabaseConfig.shared.client
                        .from("vehicles")
                        .select()
                        .eq("id", value: vehicleId.uuidString)
                        .execute()
                        .value
                    
                    if let vehicle = vehicles.first {
                        let resolvedHistory: VehicleHistoryReport?
                        if let nhtsaData = scanResult.nhtsaData {
                            resolvedHistory = VehicleHistoryReport.fromJSON(nhtsaData)
                        } else if VehicleHistoryService.canFetchNHTSA(for: vehicle) {
                            resolvedHistory = await VehicleHistoryService.fetchReport(for: vehicle)
                        } else {
                            resolvedHistory = nil
                        }
                        
                        await MainActor.run {
                            // Populate nav data with historical scan
                            nav.currentScanData.scanId = scanUUID  // Store the scan ID for deletion
                            nav.currentScanData.vehicleInfo = vehicle
                            nav.currentScanData.recommendation = scanResult.recommendation
                            nav.currentScanData.isHistoricalView = true  // Mark as historical
                            nav.currentScanData.scanDate = scanResult.createdAt  // Restore scan date for freshness badge
                            nav.currentScanData.shareCode = scanResult.shareCode  // Restore share code if exists
                            nav.currentScanData.historyReport = resolvedHistory
                            
                            // Convert OBD JSON back to results if available
                            if let obdData = scanResult.obdData {
                                var results = OBDScanResults()
                                results.vin = obdData.vin
                                results.dtcs = obdData.dtcs ?? []
                                results.rpm = obdData.rpm
                                results.coolantTemp = obdData.coolantTemp
                                results.batteryVoltage = obdData.batteryVoltage
                                results.fuelLevel = obdData.fuelLevel
                                results.engineLoad = obdData.engineLoad
                                results.intakeTemp = obdData.intakeTemp
                                results.throttlePosition = obdData.throttlePosition
                                results.distanceSinceCleared = obdData.distanceSinceCleared
                                results.warmupsSinceCleared = obdData.warmupCycles
                                results.fuelType = obdData.fuelType
                                results.obdStandard = obdData.obdStandard
                                results.barometricPressure = obdData.barometricPressure
                                nav.currentScanData.scanResults = results
                                nav.currentScanData.vinPartial = (obdData.vin != nil && (obdData.vin?.count ?? 0) != 17)
                            }
                            
                            // Restore VIN verification flags from database
                            nav.currentScanData.vinVerified = scanResult.vinVerified
                            nav.currentScanData.vinMismatch = scanResult.vinMismatch
                            
                            // Restore valuation data if available
                            if let valuationJSON = scanResult.estimatedValue {
                                nav.currentScanData.valuationResult = ValuationService.ValuationResult(
                                    lowEstimate: valuationJSON.lowEstimate ?? 0,
                                    highEstimate: valuationJSON.highEstimate ?? 0,
                                    baseValue: valuationJSON.baseValue ?? 0,
                                    adjustments: valuationJSON.adjustments?.compactMap { adj in
                                        guard let desc = adj.description, let amount = adj.amount else { return nil }
                                        return ValuationService.Adjustment(
                                            description: desc,
                                            amount: amount,
                                            category: ValuationService.Adjustment.AdjustmentCategory(rawValue: adj.category ?? "other") ?? .other
                                        )
                                    } ?? [],
                                    disclaimer: valuationJSON.disclaimer ?? ValuationService.standardDisclaimer,
                                    kbbURL: valuationJSON.kbbURL,
                                    carsComURL: valuationJSON.carsComURL
                                )
                                
                                // Restore asking price for display
                                if let askingPrice = scanResult.askingPrice {
                                    nav.currentScanData.humanCheck = QuickCheckData(askingPrice: askingPrice)
                                }
                            }
                            
                            // Restore AI analysis if available
                            if let scanData = scanResult.scanData,
                               let aiAnalysis = scanData.aiAnalysis {
                                // Convert to DTCAnalysisService.AnalysisResponse
                                let analyses = (aiAnalysis.analyses ?? []).map { analysis in
                                    DTCAnalysisService.DTCAnalysis(
                                        code: analysis.code ?? "",
                                        name: analysis.name ?? "",
                                        description: analysis.description ?? "",
                                        repairCostLow: analysis.repairCostLow ?? 0,
                                        repairCostHigh: analysis.repairCostHigh ?? 0,
                                        urgency: analysis.urgency ?? "low",
                                        commonForVehicle: analysis.commonForVehicle ?? false
                                    )
                                }
                                
                                var valuation: DTCAnalysisService.VehicleValuation? = nil
                                if let v = aiAnalysis.vehicleValuation {
                                    valuation = DTCAnalysisService.VehicleValuation(
                                        lowEstimate: v.lowEstimate ?? 0,
                                        highEstimate: v.highEstimate ?? 0,
                                        reasoning: v.reasoning
                                    )
                                }
                                
                                nav.currentScanData.dtcAnalysis = DTCAnalysisService.AnalysisResponse(
                                    analyses: analyses,
                                    totalRepairCostLow: aiAnalysis.totalRepairCostLow ?? 0,
                                    totalRepairCostHigh: aiAnalysis.totalRepairCostHigh ?? 0,
                                    overallUrgency: aiAnalysis.overallUrgency ?? "none",
                                    summary: aiAnalysis.summary ?? "",
                                    vehicleValuation: valuation
                                )
                                
                                // Also restore valuation from AI analysis if not already set
                                if nav.currentScanData.valuationResult == nil, let valuation = valuation {
                                    nav.currentScanData.valuationResult = ValuationService.ValuationResult(
                                        lowEstimate: valuation.lowEstimate,
                                        highEstimate: valuation.highEstimate,
                                        baseValue: (valuation.lowEstimate + valuation.highEstimate) / 2,
                                        adjustments: [],
                                        disclaimer: valuation.reasoning ?? "Prices vary by trim, mileage, condition, and region.",
                                        kbbURL: nil,
                                        carsComURL: nil
                                    )
                                }
                            }
                            
                            nav.currentScreen = .results
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    nav.showErrorToast("Couldn't load scan history. Pull to refresh to try again.", errorCode: ErrorEventCode.ERR_GENERIC.rawValue, errorMessage: error.localizedDescription, scanStep: "all_scans")
                }
            }
        }
    }
    
    private func determineRecommendation(scanResults: OBDScanResults?, humanCheck: QuickCheckData) -> RecommendationType {
        // Define critical warning lights (important lights that indicate serious issues)
        let criticalWarningLights: Set<WarningLightType> = [.checkEngine, .radiator, .oil, .battery, .airbag]
        
        // Check if any critical warning lights are on
        let warningLightSet = Set(humanCheck.warningLightTypes)
        let hasCriticalLights = humanCheck.dashboardLights && 
                               !humanCheck.warningLightTypes.isEmpty &&
                               !warningLightSet.isDisjoint(with: criticalWarningLights)
        
        // Primary decision maker: OBD scan results (~60% weight)
        var obdRecommendation: RecommendationType = .safe
        
        if let results = scanResults {
            // Any DTCs = serious concern
            if !results.dtcs.isEmpty {
                obdRecommendation = .notRecommended
            }
            
            // Overheating = serious concern
            if let coolant = results.coolantTemp, coolant > 105 {
                obdRecommendation = .notRecommended
            }
            
            // Low voltage = moderate concern
            if let voltage = results.batteryVoltage, voltage < 12.5 {
                if obdRecommendation == .safe {
                    obdRecommendation = .caution
                }
            }
            
            // Recently cleared codes = suspicious
            // If cleared codes AND critical lights are on → "Not Recommended" (red flag)
            // If cleared codes but NO critical lights → "Caution" (could be maintenance)
            if results.recentlyCleared {
                if hasCriticalLights {
                    // Recently cleared codes + critical lights = red flag
                    obdRecommendation = .notRecommended
                } else if obdRecommendation == .safe {
                    // Recently cleared codes but no critical lights = caution (could be maintenance)
                    obdRecommendation = .caution
                }
            }
        }
        
        // Vehicle history check (~10% weight)
        var historyRecommendation: RecommendationType = .safe
        
        if let historyReport = nav.currentScanData.historyReport {
            if historyReport.hasOpenRecalls {
                if historyReport.severeComplaintCount > 5 {
                    historyRecommendation = .notRecommended
                } else {
                    historyRecommendation = .caution
                }
            } else if historyReport.severeComplaintCount > 3 {
                historyRecommendation = .caution
            }
        }
        
        // Human check - critical lights can trigger "Not Recommended"
        var humanRecommendation: RecommendationType = .safe
        
        // Critical warning lights are a red flag
        if hasCriticalLights {
            humanRecommendation = .notRecommended
        } else {
            // Count other concerning factors from human check
            var concernCount = 0
            
            if humanCheck.dashboardLights {
                concernCount += 1
            }
            if humanCheck.engineSounds {
                concernCount += 1
            }
            if humanCheck.tireCondition == "Bare" {
                concernCount += 1
            }
            if humanCheck.interiorCondition == "Poor" {
                concernCount += 1
            }
            
            // Other human check factors can only raise to caution
            if concernCount >= 2 {
                humanRecommendation = .caution
            }
        }
        
        // Final recommendation: OBD/History/Human critical lights can trigger notRecommended
        if obdRecommendation == .notRecommended || historyRecommendation == .notRecommended || humanRecommendation == .notRecommended {
            return .notRecommended
        }
        
        if obdRecommendation == .caution || historyRecommendation == .caution || humanRecommendation == .caution {
            return .caution
        }
        
        return .safe
    }
}

// MARK: - Loading View (Splash Screen)

struct LoadingView: View {
    var body: some View {
        ZStack {
            // Mint background
            Color.mintGreen
                .ignoresSafeArea()
            
            // White logo lockup centered
            Image("lockup-white")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(AuthService())
        .environmentObject(ScanService())
        .environmentObject(NavigationManager())
}
