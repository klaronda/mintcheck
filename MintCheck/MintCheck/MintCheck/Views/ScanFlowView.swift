//
//  ScanFlowView.swift
//  MintCheck
//
//  New simplified scan flow with shared progress header
//

import SwiftUI

struct ScanFlowView: View {
    let flowId: Int
    let onExit: () -> Void
    let onExitToScannerHelp: (SupportArticle) -> Void
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var connectionManager: ConnectionManagerService
    @EnvironmentObject var nav: NavigationManager
    @State private var step: ScanFlowStep = .engineOn
    @State private var lastSeenFlowId: Int = -1
    @State private var vinNumber = ""
    @State private var odometerReading = ""
    @State private var vehicleMake = ""
    @State private var vehicleModel = ""
    @State private var vehicleYear = ""
    @State private var showCamera = false
    @State private var showNoScannerDialog = false
    @State private var showOBDHelp = false
    @State private var isDisconnecting = false
    /// When non-nil, DisconnectWifiStepView shows state-specific help (still on scanner vs no internet).
    @State private var disconnectHelpState: DisconnectStepHelpState = .none
    /// Number of "Check Again" retries with no internet; after 2+, we show "Continue with offline report".
    @State private var disconnectRetryCount = 0
    @StateObject private var obdService = OBDService()
    @State private var isDecodingVin = false
    @State private var showVinRegionHint = false
    @State private var decodedVehicleInfo: VehicleInfo?
    @State private var analysisStarted = false
    @State private var showDecodedInfo: Bool = false
    @State private var decodedInfo: VINDecodeResult?
    @State private var showVinHelpSheet = false
    
    private let vinDecoder = VINDecoderService()
    
    var body: some View {
        VStack(spacing: 0) {
            if step.showsProgressHeader {
                progressHeader
            }
            
            switch step {
            case .engineOn:
                EngineOnStepView(onContinue: { step = .enterVin })
            case .enterVin:
                EnterVinStepView(
                    vinNumber: $vinNumber,
                    odometerReading: $odometerReading,
                    showCamera: $showCamera,
                    onContinue: handleVinContinue,
                    onVehicleDetails: authService.isEarlyAccess ? {} : { step = .vehicleDetails },
                    onVinHelp: authService.isEarlyAccess ? { showVinHelpSheet = true } : nil,
                    showRegionHint: showVinRegionHint,
                    onConfirmDetails: handleConfirmVehicleDetails,
                    showDecodedInfo: $showDecodedInfo,
                    decodedInfo: $decodedInfo,
                    isVinLocked: !authService.hasFullAccess && nav.freeUserVehicle?.vin != nil && !vinNumber.isEmpty
                )
                .sheet(isPresented: $showCamera) {
                    VINCameraView(onVINScanned: { scannedVIN in
                        vinNumber = scannedVIN
                        showCamera = false
                    })
                }
            case .vehicleDetails:
                VehicleDetailsStepView(
                    make: $vehicleMake,
                    model: $vehicleModel,
                    year: $vehicleYear,
                    odometerReading: $odometerReading,
                    onContinue: {
                        let year = vehicleYear.trimmingCharacters(in: .whitespaces).isEmpty ? "(Year N/A)" : vehicleYear.trimmingCharacters(in: .whitespaces)
                        let info = VehicleInfo(
                            vin: vinNumber.trimmingCharacters(in: .whitespaces).isEmpty ? nil : vinNumber.trimmingCharacters(in: .whitespaces),
                            year: year,
                            make: vehicleMake.trimmingCharacters(in: .whitespaces),
                            model: vehicleModel.trimmingCharacters(in: .whitespaces)
                        )
                        nav.currentScanData.vehicleInfo = info
                        nav.currentScanData.vin = info.vin
                        step = .locatePort
                    }
                )
            case .locatePort:
                LocatePortStepView(
                    onHelp: { showOBDHelp = true },
                    onContinue: { step = .connectWifi },
                    onNoScanner: { showNoScannerDialog = true }
                )
            case .connectWifi:
                ConnectWifiStepView(
                    onOpenSettings: openSettings,
                    onStartScan: {
                        Task {
                            let hasInternet = await connectionManager.checkInternetStatus()
                            await MainActor.run {
                                nav.currentScanData.scanMode = hasInternet ? .online_scan : .offline_scan
                                connectionManager.setDeviceType(.wifi)
                                step = .scanning
                            }
                        }
                    },
                    onCheckInternet: { await connectionManager.checkInternetStatus() },
                    onReportIssue: {
                        nav.feedbackSource = .error_cta
                        nav.feedbackPrefillMessage = "Issue occurred during connect_obd"
                        nav.feedbackErrorCode = ErrorEventCode.ERR_OBD_EARLY_WIFI.rawValue
                        nav.feedbackErrorMessage = "Scanner connected too soon"
                        nav.feedbackScanStep = "connect_obd"
                        nav.showFeedbackModal = true
                    },
                    onReportConnectFailed: { count in
                        nav.feedbackSource = .error_cta
                        nav.feedbackPrefillMessage = "Couldn't find your scanner automatically."
                        nav.feedbackErrorCode = ErrorEventCode.ERR_OBD_CONNECT_FAIL.rawValue
                        nav.feedbackErrorMessage = "Connect to scanner failed (attempt \(count))"
                        nav.feedbackScanStep = "connect_obd"
                        nav.showFeedbackModal = true
                    },
                    onHavingTroubleConnecting: {
                        let article = SupportArticle(
                            id: "connect-scanner",
                            title: "How to connect your OBD-II scanner",
                            content: """
                            Follow these steps to connect your OBD-II scanner and start a vehicle scan:
                            
                            **Step 1: Locate the OBD-II port**
                            Find the port under the dashboard on the driver's side. See our "Finding your OBD-II port" article for detailed instructions.
                            
                            **Step 2: Plug in the scanner**
                            Insert your OBD-II scanner firmly into the port. It should click into place.
                            
                            **Step 3: Turn on the ignition**
                            Turn your vehicle's ignition to the "ON" position. The engine does not need to be running for most scans.
                            
                            **Step 4: Connect to the scanner**
                            
                            For WiFi scanners:
                            - Open your phone's Settings
                            - Go to WiFi settings
                            - Connect to the scanner's network (usually named "OBDII", "WiFi_OBD", or similar)
                            - Return to MintCheck
                            
                            For Bluetooth scanners:
                            - Enable Bluetooth on your phone
                            - Pair with the scanner in your phone's Bluetooth settings
                            - Return to MintCheck
                            
                            **Step 5: Start the scan**
                            Tap "Start Scan" in MintCheck to begin the diagnostic check. The scan typically takes 30-60 seconds.
                            
                            **Troubleshooting:**
                            - Make sure the scanner is fully inserted
                            - Ensure the ignition is on (not just accessories)
                            - Try reconnecting to the scanner's WiFi/Bluetooth
                            - Restart the scanner by unplugging and re-plugging it
                            """
                        )
                        onExitToScannerHelp(article)
                    },
                    isOffline: connectionManager.internetStatus == .offline,
                    wifiManager: connectionManager.wifiManager
                )
            case .scanning:
                ScanningView(
                    onComplete: { results in
                        nav.currentScanData.scanResults = results
                        nav.currentScanData.recommendation = recommendationFromScan(results: results)
                        nav.currentScanData.reportStorage = nav.currentScanData.scanMode == .offline_scan ? .local_only : .uploaded
                        let userVin = (nav.currentScanData.vehicleInfo?.vin ?? "").trimmingCharacters(in: .whitespaces).uppercased()
                        let ecuVin = (results.vin ?? "").trimmingCharacters(in: .whitespaces).uppercased()
                        let ecuVinIsPartial = !ecuVin.isEmpty && ecuVin.count != 17
                        nav.currentScanData.vinPartial = ecuVinIsPartial ? true : (ecuVin.isEmpty ? nil : false)
                        if ecuVinIsPartial {
                            nav.currentScanData.vinVerified = false
                            nav.currentScanData.vinMismatch = false
                        } else if !userVin.isEmpty && !ecuVin.isEmpty {
                            if userVin != ecuVin {
                                nav.currentScanData.vinMismatch = true
                                nav.currentScanData.vinVerified = false
                            } else {
                                nav.currentScanData.vinVerified = true
                                nav.currentScanData.vinMismatch = false
                            }
                        } else if !ecuVin.isEmpty {
                            nav.currentScanData.vinVerified = true
                            nav.currentScanData.vinMismatch = false
                        } else {
                            nav.currentScanData.vinVerified = false
                            nav.currentScanData.vinMismatch = false
                        }
                        
                        // Note: Free user VIN enforcement is now handled at input time —
                        // the VIN field is pre-filled and locked on scans 2-3, so no
                        // post-scan ECU comparison is needed.
                        
                        step = .unplugDevice
                    },
                    onStartOver: { step = .connectWifi },
                    obdService: obdService,
                    onReportIssue: { errorMsg in
                        nav.feedbackSource = .error_cta
                        nav.feedbackPrefillMessage = "Scan failed."
                        nav.feedbackErrorCode = ErrorEventCode.ERR_OBD_DROP.rawValue
                        nav.feedbackErrorMessage = errorMsg ?? "An error occurred during the scan."
                        nav.feedbackScanStep = "scanning"
                        nav.showFeedbackModal = true
                    }
                )
            case .unplugDevice:
                UnplugDeviceStepView(
                    onContinue: { step = .disconnectWifi }
                )
            case .disconnectWifi:
                DisconnectWifiStepView(
                    isDisconnecting: isDisconnecting,
                    helpState: disconnectHelpState,
                    retryCount: disconnectRetryCount,
                    onOpenSettings: openSettings,
                    onRetry: handleDisconnectRetry,
                    onContinueOffline: {
                        nav.currentScanData.scanMode = .offline_scan
                        disconnectRetryCount = 0
                        step = .analyzingResults
                    },
                    wifiManager: connectionManager.wifiManager
                )
            case .analyzingResults:
                AnalyzingResultsView()
            case .results:
                PlaceholderStepView(title: "Results", onContinue: onExit)
            }
        }
        .background(Color.deepBackground)
        .sheet(isPresented: $showOBDHelp) {
            OBDHelpSheet()
        }
        .sheet(isPresented: $showVinHelpSheet) {
            VINHelpSheet(onDismiss: { showVinHelpSheet = false })
        }
        .onAppear {
            if flowId != lastSeenFlowId {
                lastSeenFlowId = flowId
                step = .engineOn
                
                // Free user returning for scan 2 or 3: pre-fill and lock the VIN
                if !authService.hasFullAccess,
                   let cachedVehicle = nav.freeUserVehicle,
                   let cachedVin = cachedVehicle.vin,
                   !cachedVin.trimmingCharacters(in: .whitespaces).isEmpty {
                    vinNumber = cachedVin.trimmingCharacters(in: .whitespaces).uppercased()
                }
            }
        }
        .alert("MintCheck is only compatible with select Wi‑Fi scanners.", isPresented: $showNoScannerDialog) {
            Button("Exit Scan", role: .destructive) {
                let article = SupportArticle(
                    id: "wifi-scanners",
                    title: "Where to buy vehicle Wi‑Fi scanners",
                    content: """
                    You can purchase compatible Wi‑Fi scanners online. Below are a few options that arrive quickly and work well with MintCheck.
                    """
                )
                onExitToScannerHelp(article)
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("On the next screen, we’ll highlight a few affordable scanners that work great and arrive quickly.")
        }
        .onChange(of: step) { _, newStep in
            if newStep == .disconnectWifi {
                handleDisconnectFlow()
            }
            if newStep == .analyzingResults {
                startAnalysisFlow()
            }
        }
    }
    
    private var progressHeader: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: handleBack) {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.textSecondary)
                        .frame(width: 44, height: 44)
                }
                
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.borderColor)
                            .frame(height: 4)
                        
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mintGreen)
                            .frame(
                                width: geometry.size.width * progressBarFraction,
                                height: 4
                            )
                            .animation(.easeInOut(duration: 0.3), value: progressBarFraction)
                    }
                }
                .frame(height: 4)
                .padding(.trailing, 16)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            
            HStack {
                Text(step.progressLabel)
                    .font(.system(size: FontSize.bodySmall, weight: .medium))
                    .foregroundColor(.textSecondary)
                
                Spacer()
                
                Text(step.stepCountLabel)
                    .font(.system(size: FontSize.bodySmall, weight: .medium))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
        }
        .background(Color.white)
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.borderColor),
            alignment: .bottom
        )
    }
    
    private func handleBack() {
        switch step {
        case .engineOn:
            onExit()
        default:
            step = step.previous ?? .engineOn
        }
    }
    
    private var progressBarFraction: CGFloat {
        // Keep header progress static - don't animate during scan
        // The scanning view has its own progress bar
        return step.progressFraction
    }

    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }

    private func handleVinContinue() {
        guard !isDecodingVin else { return }
        // Full access (early_access / tester): VIN is required; no make/model-only path
        if authService.hasFullAccess {
            guard vinNumber.isValidVIN else { return }
            // Fall through to decode and proceed (no vehicleDetails skip)
        } else if !vehicleMake.trimmingCharacters(in: .whitespaces).isEmpty,
                  !vehicleModel.trimmingCharacters(in: .whitespaces).isEmpty {
            let year = vehicleYear.isEmpty ? "(Year N/A)" : vehicleYear
            nav.currentScanData.vehicleInfo = VehicleInfo(
                vin: vinNumber.isEmpty ? nil : vinNumber,
                year: year,
                make: vehicleMake,
                model: vehicleModel
            )
            step = .locatePort
            return
        } else {
            guard vinNumber.isValidVIN else {
                step = .vehicleDetails
                return
            }
        }

        // Use existing decoded info if available (from green box lookup)
        if let decoded = decodedInfo {
            let make = decoded.make ?? ""
            let model = decoded.model ?? ""
            let year = decoded.year ?? "(Year N/A)"
            
            if make.isEmpty || model.isEmpty {
                showVinRegionHint = true
                step = .vehicleDetails
            } else {
                let vehicleInfo = VehicleInfo(
                    vin: vinNumber,
                    year: year,
                    make: make,
                    model: model,
                    trim: decoded.trim,
                    fuelType: decoded.fuelType,
                    engine: decoded.engineDescription,
                    transmission: decoded.transmission,
                    drivetrain: decoded.driveType
                )
                decodedVehicleInfo = vehicleInfo
                nav.currentScanData.vehicleInfo = vehicleInfo
                showVinRegionHint = false
                step = .locatePort
            }
            return
        }

        // Decode VIN if not already decoded
        isDecodingVin = true
        showVinRegionHint = false
        Task {
            do {
                let decoded = try await vinDecoder.decodeVIN(vinNumber)
                let make = decoded.make ?? ""
                let model = decoded.model ?? ""
                let year = decoded.year ?? "(Year N/A)"

                await MainActor.run {
                    isDecodingVin = false
                    decodedInfo = decoded
                    if make.isEmpty || model.isEmpty {
                        showVinRegionHint = true
                        step = .vehicleDetails
                    } else {
                        let vehicleInfo = VehicleInfo(
                            vin: vinNumber,
                            year: year,
                            make: make,
                            model: model,
                            trim: decoded.trim,
                            fuelType: decoded.fuelType,
                            engine: decoded.engineDescription,
                            transmission: decoded.transmission,
                            drivetrain: decoded.driveType
                        )
                        decodedVehicleInfo = vehicleInfo
                        nav.currentScanData.vehicleInfo = vehicleInfo
                        showVinRegionHint = false
                        step = .locatePort
                    }
                }
            } catch {
                await MainActor.run {
                    isDecodingVin = false
                    showVinRegionHint = true
                    if !authService.hasFullAccess {
                        step = .vehicleDetails
                    }
                }
            }
        }
    }

    private func handleConfirmVehicleDetails() {
        guard vinNumber.isValidVIN else {
            step = .vehicleDetails
            return
        }

        // If we already decoded, just show it
        if let decoded = decodedInfo {
            showDecodedInfo = true
            return
        }

        // Decode VIN and show in green box
        isDecodingVin = true
        showVinRegionHint = false
        Task {
            do {
                let decoded = try await vinDecoder.decodeVIN(vinNumber)
                await MainActor.run {
                    isDecodingVin = false
                    decodedInfo = decoded
                    showDecodedInfo = true
                    showVinRegionHint = false
                }
            } catch {
                await MainActor.run {
                    isDecodingVin = false
                    showVinRegionHint = true
                    showDecodedInfo = false
                }
            }
        }
    }

    private func recommendationFromScan(results: OBDScanResults) -> RecommendationType {
        var recommendation: RecommendationType = .safe

        if !results.dtcs.isEmpty {
            recommendation = .notRecommended
        }

        if let coolant = results.coolantTemp, coolant > 105 {
            recommendation = .notRecommended
        }

        if let voltage = results.batteryVoltage, voltage < 12.5, recommendation == .safe {
            recommendation = .caution
        }

        if results.recentlyCleared && recommendation == .safe {
            recommendation = .caution
        }

        // If 2+ of 4 systems returned no data and nothing else is wrong,
        // we can't confidently say the car is healthy.
        if recommendation == .safe {
            let hasEngineData = (results.rpm != nil || results.coolantTemp != nil) || !results.dtcs.isEmpty
            let hasFuelData = results.fuelLevel != nil || results.shortTermFuelTrim != nil || results.longTermFuelTrim != nil
            let hasEmissionsData = !results.dtcs.filter({ $0.hasPrefix("P04") || $0.hasPrefix("P044") }).isEmpty || results.barometricPressure != nil
            let hasElectricalData = results.batteryVoltage != nil

            let unknownCount = [hasEngineData, hasFuelData, hasEmissionsData, hasElectricalData]
                .filter { !$0 }.count

            if unknownCount >= 2 {
                recommendation = .lowData
            }
        }

        return recommendation
    }

    private func handleDisconnectFlow() {
        guard !isDisconnecting else { return }
        isDisconnecting = true
        disconnectHelpState = .none

        Task {
            // First fetch current SSID so user can see what they're connected to
            await connectionManager.wifiManager.fetchCurrentSSID()
            
            // disconnectWiFi() returns TRUE if successfully disconnected, FALSE if still connected
            let disconnectedSuccessfully = await connectionManager.disconnectWiFi()
            
            if disconnectedSuccessfully {
                // Successfully disconnected - wait for internet and proceed
                let hasInternet = await connectionManager.waitForInternet(timeout: 8)
                
                await MainActor.run {
                    isDisconnecting = false
                    if hasInternet {
                        disconnectRetryCount = 0
                        step = .analyzingResults
                    } else {
                        // Disconnected but no internet yet - show help (counts as first "no internet")
                        Task {
                            await connectionManager.wifiManager.fetchCurrentSSID()
                        }
                        disconnectHelpState = .noInternet
                        disconnectRetryCount = 1
                    }
                }
            } else {
                // Still connected to OBD WiFi - fetch SSID for display and show help
                await connectionManager.wifiManager.fetchCurrentSSID()
                
                await MainActor.run {
                    isDisconnecting = false
                    disconnectHelpState = .stillConnected
                    // Auto-open Settings so user can manually disconnect
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        openSettings()
                    }
                }
            }
        }
    }

    private func handleDisconnectRetry() {
        // User already disconnected manually - just verify internet and proceed
        guard !isDisconnecting else { return }
        isDisconnecting = true
        disconnectHelpState = .none
        
        Task {
            // Fetch current SSID to show what they're connected to now
            await connectionManager.wifiManager.fetchCurrentSSID()
            
            // Check if we have internet now
            let hasInternet = await connectionManager.waitForInternet(timeout: 8)
            
            await MainActor.run {
                isDisconnecting = false
                if hasInternet {
                    disconnectRetryCount = 0
                    step = .analyzingResults
                } else {
                    disconnectHelpState = .noInternet
                    disconnectRetryCount += 1
                }
            }
        }
    }

    private func startAnalysisFlow() {
        guard !analysisStarted else { return }
        analysisStarted = true

        guard let scanResults = nav.currentScanData.scanResults,
              let vehicleInfo = nav.currentScanData.vehicleInfo else {
            // Safety: vehicleInfo can be nil if user reached scanning without it (e.g. old path). Avoid broken results screen.
            nav.resetScanData()
            nav.currentScreen = .dashboard
            return
        }

        // Offline scan: skip AI analysis and go straight to results
        if nav.currentScanData.scanMode == .offline_scan {
            nav.isAILoading = false
            nav.currentScreen = .results
            return
        }

        nav.isAILoading = true

        Task {
            let startTime = Date()
            let maximumWaitTime: TimeInterval = 5.0

            let aiTask = Task {
                try await DTCAnalysisService.shared.analyzeScanResults(
                    scanResults: scanResults,
                    vehicleInfo: vehicleInfo,
                    humanCheck: nil
                )
            }

            var analysisResult: DTCAnalysisService.AnalysisResponse? = nil
            var analysisError: Error? = nil

            await withTaskGroup(of: Void.self) { group in
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

                group.addTask {
                    try? await Task.sleep(nanoseconds: UInt64(maximumWaitTime * 1_000_000_000))
                    aiTask.cancel()
                }

                await group.next()
                group.cancelAll()
            }

            let elapsedTime = Date().timeIntervalSince(startTime)
            if elapsedTime < maximumWaitTime {
                let remainingTime = maximumWaitTime - elapsedTime
                try? await Task.sleep(nanoseconds: UInt64(remainingTime * 1_000_000_000))
            }

            await MainActor.run {
                if let analysis = analysisResult {
                    nav.currentScanData.dtcAnalysis = analysis

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
                    if let analysisError = error as? DTCAnalysisService.AnalysisError,
                       case .networkError = analysisError {
                        nav.currentScanData.aiNetworkError = true
                    }
                }

                nav.isAILoading = false
                nav.currentScreen = .results
            }
        }
    }
}

enum ScanFlowStep: CaseIterable {
    case engineOn
    case enterVin
    case vehicleDetails
    case locatePort
    case connectWifi
    case scanning
    case unplugDevice
    case disconnectWifi
    case analyzingResults
    case results
    
    var previous: ScanFlowStep? {
        return ScanFlowStep.allCases.first { $0.order == self.order - 1 }
    }
    
    /// Unique order (1–10) for step sequence. Single source of truth for previous/next.
    private var order: Int {
        switch self {
        case .engineOn: return 1
        case .enterVin: return 2
        case .vehicleDetails: return 3
        case .locatePort: return 4
        case .connectWifi: return 5
        case .scanning: return 6
        case .unplugDevice: return 7
        case .disconnectWifi: return 8
        case .analyzingResults: return 9
        case .results: return 10
        }
    }
    
    /// Display step (1–6) for progress bar and "Step X of 6"; post-scan steps show as 6.
    private var displayStep: Int {
        min(order, 6)
    }
    
    var showsProgressHeader: Bool {
        switch self {
        case .analyzingResults, .results:
            return false
        default:
            return true
        }
    }
    
    var progressFraction: CGFloat {
        let total = 6.0
        let current = Double(displayStep)
        return CGFloat(current / total)
    }
    
    var progressLabel: String {
        switch self {
        case .engineOn: return "Turn on engine"
        case .enterVin: return "Enter VIN"
        case .vehicleDetails: return "Vehicle details"
        case .locatePort: return "Locate OBD-II port"
        case .connectWifi: return "Connect Wi-Fi"
        case .scanning: return "Scanning"
        case .unplugDevice: return "Unplug scanner"
        case .disconnectWifi: return "Disconnect Wi-Fi"
        case .analyzingResults: return "Analyzing results"
        case .results: return "Results"
        }
    }
    
    var stepCountLabel: String {
        "Step \(displayStep) of 6"
    }
}

struct LocatePortStepView: View {
    let onHelp: () -> Void
    let onContinue: () -> Void
    let onNoScanner: () -> Void
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Locate the OBD‑II port in the vehicle, and plug in your scanner.")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Image("obd-port")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    
                    Text("It’s usually under the dashboard on the driver’s side. Use the light on your phone to help locate.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    
                    Button(action: onHelp) {
                        Text("Help me find the OBD‑II port on this vehicle.")
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                    
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        
                        Text("The MintCheck app is not compatible with Bluetooth/BLE scanners.")
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(.top, 8)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "It’s Plugged In",
                    action: onContinue
                )
                
                Button(action: onNoScanner) {
                    Text("I don’t have a Wi‑Fi scanner")
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textSecondary)
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
    }
}

struct ConnectWifiStepView: View {
    let onOpenSettings: () -> Void
    let onStartScan: () -> Void
    let onCheckInternet: () async -> Bool
    var onReportIssue: (() -> Void)? = nil
    var onReportConnectFailed: ((Int) -> Void)? = nil
    var onHavingTroubleConnecting: (() -> Void)? = nil
    var isOffline: Bool = false
    @ObservedObject var wifiManager: WiFiConnectionManager
    
    @State private var showEarlyOBDAlert = false
    @State private var isChecking = true
    @State private var pollTimer: Timer?
    @State private var detectedOBD = false
    @State private var showTroubleshootSheet = false
    
    /// Whether the user is on an OBD scanner network
    private var isOnScannerWifi: Bool {
        detectedOBD || wifiManager.isConnectedToOBDNetwork
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Early OBD warning (connected before plugging in)
                    if showEarlyOBDAlert {
                        InlineAlert(
                            type: .warning,
                            title: "Scanner connected too soon",
                            message: "Your phone is on the scanner's Wi‑Fi but has no internet. Unplug the scanner or switch Wi‑Fi, then try again.",
                            actions: [
                                ("Open Settings", { onOpenSettings() }),
                                ("I unplugged it", {
                                    Task {
                                        await wifiManager.fetchCurrentSSID()
                                        let hasInternet = await onCheckInternet()
                                        await MainActor.run {
                                            if !wifiManager.isConnectedToOBDNetwork || hasInternet {
                                                showEarlyOBDAlert = false
                                            }
                                        }
                                    }
                                })
                            ]
                        )
                    } else if isChecking {
                        ProgressView()
                            .scaleEffect(1.0)
                            .tint(.mintGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else if isOnScannerWifi {
                        // Successfully detected OBD scanner network
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.mintGreen)
                            
                            Text("Connected to \(wifiManager.currentSSID ?? "scanner")")
                                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            Text("You're on the scanner's Wi‑Fi. Ready to scan.")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        // Main state: guide user to connect manually
                        Text("Connect to your scanner's Wi‑Fi")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 12) {
                            InstructionRow(number: "1", text: "Open your phone's **Settings** app")
                            InstructionRow(number: "2", text: "Tap **Wi‑Fi**")
                            InstructionRow(number: "3", text: "Connect to your scanner's network")
                            InstructionRow(number: "4", text: "Come back here and tap the button below")
                        }
                        
                        // Open Wi-Fi settings button (opens Settings app; user taps Wi‑Fi there)
                        Button(action: onOpenSettings) {
                            HStack(spacing: 8) {
                                Image(systemName: "wifi")
                                    .font(.system(size: 16))
                                Text("Open Wi‑Fi settings")
                                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            }
                            .foregroundColor(.mintGreen)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.mintGreen.opacity(0.12))
                            .cornerRadius(LayoutConstants.borderRadius)
                        }
                        .buttonStyle(.plain)
                        
                        // Common network names hint (only scanners we've validated)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Common scanner network names:")
                                .font(.system(size: FontSize.bodySmall, weight: .medium))
                                .foregroundColor(.textSecondary)
                            Text("WiFi_OBDII, OBD2, ELM327")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textSecondary)
                                .italic()
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.statusInfoBg)
                        .cornerRadius(8)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 120)
            }
            
            if isOnScannerWifi {
                VStack(spacing: 12) {
                    if isOffline {
                        InfoCard(
                            text: "You're offline. Your scan will be saved locally and uploaded when you're back online.",
                            icon: "wifi.slash"
                        )
                        .padding(.horizontal, 24)
                    }
                    PrimaryButton(
                        title: "Start Scan",
                        action: onStartScan,
                        isEnabled: true
                    )
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
            } else if !isChecking && !showEarlyOBDAlert {
                // Sticky footer: I'm connected + Having trouble connecting (main state)
                VStack(spacing: 12) {
                    PrimaryButton(
                        title: "I'm connected – start scan",
                        action: onStartScan,
                        isEnabled: true
                    )
                    if let action = onHavingTroubleConnecting {
                        Button(action: action) {
                            Text("Having trouble connecting?")
                                .font(.system(size: FontSize.bodySmall, weight: .medium))
                                .foregroundColor(.textSecondary)
                                .underline()
                        }
                        .buttonStyle(.plain)
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
        }
        .onAppear {
            checkInitialState()
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
        .sheet(isPresented: $showTroubleshootSheet) {
            TroubleshootSheet(onDismiss: { showTroubleshootSheet = false })
        }
    }
    
    private func checkInitialState() {
        isChecking = true
        Task {
            await wifiManager.fetchCurrentSSID()
            let hasInternet = await onCheckInternet()
            let onOBDNoInternet = wifiManager.isConnectedToOBDNetwork && !hasInternet
            await MainActor.run {
                isChecking = false
                if onOBDNoInternet {
                    showEarlyOBDAlert = true
                } else if wifiManager.isConnectedToOBDNetwork {
                    detectedOBD = true
                }
            }
        }
    }
    
    private func startPolling() {
        pollTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
            Task {
                await wifiManager.fetchCurrentSSID()
                await MainActor.run {
                    if wifiManager.isConnectedToOBDNetwork && !showEarlyOBDAlert {
                        detectedOBD = true
                    }
                }
            }
        }
    }
    
    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }
}

/// Numbered instruction row for the connect flow
private struct InstructionRow: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.system(size: FontSize.bodySmall, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 22, height: 22)
                .background(Color.mintGreen)
                .clipShape(Circle())
            
            Text(.init(text))  // .init for markdown bold support
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textPrimary)
                .lineSpacing(4)
        }
    }
}

struct UnplugDeviceStepView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 24) {
                // Icon
                ZStack {
                    Circle()
                        .fill(Color.mintGreen.opacity(0.15))
                        .frame(width: 100, height: 100)
                    
                    Image(systemName: "cable.connector")
                        .font(.system(size: 44))
                        .foregroundColor(.mintGreen)
                }
                
                Text("Unplug your OBD-II scanner")
                    .font(.system(size: FontSize.h3, weight: .semibold))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                Text("The scan is complete. Please unplug the scanner from your vehicle's OBD-II port now.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                
                // Visual hint
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.mintGreen)
                    Text("This will disconnect your phone from the scanner's Wi-Fi")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.mintGreen.opacity(0.1))
                .cornerRadius(8)
            }
            .padding(.horizontal, 24)
            
            Spacer()
            
            VStack(spacing: 0) {
                PrimaryButton(
                    title: "I've Unplugged It",
                    action: onContinue
                )
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
    }
}

/// State for disconnect-step help message (still on scanner vs no internet).
enum DisconnectStepHelpState {
    case none
    case stillConnected  // Programmatic disconnect failed; user must switch in Settings
    case noInternet     // Disconnected but no internet yet
}

struct DisconnectWifiStepView: View {
    let isDisconnecting: Bool
    let helpState: DisconnectStepHelpState
    let retryCount: Int
    let onOpenSettings: () -> Void
    let onRetry: () -> Void
    var onContinueOffline: (() -> Void)? = nil
    @ObservedObject var wifiManager: WiFiConnectionManager
    
    private var headingText: String {
        if isDisconnecting { return "Disconnecting from scanner Wi‑Fi..." }
        switch helpState {
        case .stillConnected: return "Still connected to scanner"
        case .noInternet: return "No internet connection"
        case .none: return "Disconnect from scanner Wi‑Fi"
        }
    }
    
    private var subtitleText: String {
        if isDisconnecting {
            return "Please disconnect from the scanner Wi-Fi and connect to your regular internet."
        }
        switch helpState {
        case .stillConnected:
            return "Please disconnect from the scanner Wi-Fi and connect to your regular internet."
        case .noInternet:
            return "We need internet to finish your report. Connect to Wi‑Fi or cellular, or continue with an offline report below."
        case .none:
            return "Please disconnect from the scanner Wi-Fi and connect to your regular internet."
        }
    }
    
    var body: some View {
        VStack {
            Spacer()
            
            VStack(spacing: 16) {
                if isDisconnecting {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.mintGreen)
                }
                
                Text(headingText)
                    .font(.system(size: FontSize.bodyLarge, weight: .medium))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                
                // Only show "Connected to: SSID" when we're actually still on scanner Wi‑Fi (avoids implying scanner when it's just poor cell)
                if helpState == .stillConnected, let ssid = wifiManager.currentSSID {
                    HStack(spacing: 8) {
                        Image(systemName: "wifi")
                            .foregroundColor(.orange)
                        Text("Connected to: \(ssid)")
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange.opacity(0.15))
                    .cornerRadius(8)
                }
                
                Text(subtitleText)
                    .font(.system(size: FontSize.bodyRegular))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 24)
                
                // State-specific help when auto-disconnect failed or no internet yet
                if helpState == .stillConnected {
                    InfoCard(
                        text: "Still connected to scanner Wi‑Fi. Open Wi‑Fi Settings, switch to your usual network, then come back and tap \"I've Disconnected – Check Again\".",
                        icon: "wifi.slash"
                    )
                    .padding(.horizontal, 8)
                } else if helpState == .noInternet {
                    InfoCard(
                        text: "We still don't have internet. Connect to your home Wi‑Fi or cellular, then tap \"I've Disconnected – Check Again\". Or continue with an offline report below.",
                        icon: "wifi.slash"
                    )
                    .padding(.horizontal, 8)
                }
            }
            
            Spacer()
            
            VStack(spacing: 24) {
                PrimaryButton(
                    title: "I've Disconnected – Check Again",
                    action: onRetry
                )
                
                // After 2+ retries with no internet, offer offline report so user isn't stuck
                if helpState == .noInternet, retryCount >= 2, let continueOffline = onContinueOffline {
                    Button(action: continueOffline) {
                        Text("Continue with offline report")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textSecondary)
                            .underline()
                    }
                    .buttonStyle(.plain)
                }
                
                Button(action: onOpenSettings) {
                    Text("Open Wi-Fi Settings")
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.mintGreen)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .onAppear {
            Task {
                await wifiManager.fetchCurrentSSID()
            }
        }
    }
}
struct EngineOnStepView: View {
    let onContinue: () -> Void
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Turn on the vehicle’s engine.")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Image("start-engine")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        .padding(.vertical, 24)
                    
                    Text("This will give us a better read on the health of the car, and power your Wi‑Fi scanner.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    
                    Text("Over the next few minutes, we’ll ask you a few questions to better value the vehicle.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            
            VStack(spacing: 0) {
                PrimaryButton(
                    title: "It’s On – Let’s Get Started",
                    action: onContinue
                )
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
    }
}

struct EnterVinStepView: View {
    @Binding var vinNumber: String
    @Binding var odometerReading: String
    @Binding var showCamera: Bool
    let onContinue: () -> Void
    let onVehicleDetails: () -> Void
    var onVinHelp: (() -> Void)? = nil  // When set (e.g. Early Access), "I can't find VIN" opens VIN Help
    let showRegionHint: Bool
    let onConfirmDetails: () -> Void
    @Binding var showDecodedInfo: Bool
    @Binding var decodedInfo: VINDecodeResult?
    var isVinLocked: Bool = false  // Free user scan 2-3: VIN pre-filled and read-only
    
    private var vinCountText: String {
        "\(min(vinNumber.count, 17))/17 characters"
    }
    
    private var canContinue: Bool {
        vinNumber.count == 17
    }
    
    private var showConfirmLink: Bool {
        vinNumber.count == 17
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Enter Vehicle Identification Number.")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("The VIN is typically found on the driver’s side dashboard (visible through windshield) or on the driver’s door jamb.")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    Image("vin-location")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(isVinLocked ? "VIN" : "Scan or Enter VIN")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            if isVinLocked {
                                Image(systemName: "lock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textSecondary)
                            }
                            
                            Spacer()
                            
                            if showConfirmLink && !isVinLocked {
                                Button(action: onConfirmDetails) {
                                    Text("Confirm VIN")
                                        .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                        .foregroundColor(.mintGreen)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            TextField("1HGBH41JXMN109186", text: $vinNumber)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(isVinLocked ? .textSecondary : .textPrimary)
                                .autocapitalization(.allCharacters)
                                .disableAutocorrection(true)
                                .disabled(isVinLocked)
                            
                            if !isVinLocked {
                                Button(action: { showCamera = true }) {
                                    Image(systemName: "camera")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.textSecondary)
                                        .frame(width: 32, height: 32)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, LayoutConstants.padding3)
                        .frame(height: 44)
                        .background(isVinLocked ? Color(.systemGray6) : Color.white)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                        
                        VStack(alignment: .leading, spacing: 6) {
                            if isVinLocked {
                                Text("Free plan is limited to one vehicle. Upgrade to scan more.")
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.textSecondary)
                            } else {
                                Text(vinCountText)
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.textSecondary)
                                
                                if showRegionHint {
                                    Text("VIN lookup is optimized for U.S. vehicles and may not work in other regions.")
                                        .font(.system(size: FontSize.bodySmall))
                                        .foregroundColor(.textSecondary)
                                }
                            }
                        }
                    }
                    
                    // Decoded Vehicle Info Card (green box)
                    if showDecodedInfo, let decoded = decodedInfo {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.statusSafe)
                                Text("Vehicle Found!")
                                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                    .foregroundColor(.statusSafe)
                            }
                            
                            VStack(alignment: .leading, spacing: 8) {
                                if let year = decoded.year, let make = decoded.make, let model = decoded.model {
                                    Text("\(year) \(make) \(model)")
                                        .font(.system(size: FontSize.h4, weight: .semibold))
                                        .foregroundColor(.textPrimary)
                                }
                                
                                if let trim = decoded.trim {
                                    DecodedInfoRow(label: "Trim", value: trim)
                                }
                                if let engine = decoded.engineDescription {
                                    DecodedInfoRow(label: "Engine", value: engine)
                                }
                                if let fuel = decoded.fuelType {
                                    DecodedInfoRow(label: "Fuel", value: fuel)
                                }
                                if let trans = decoded.transmission {
                                    DecodedInfoRow(label: "Transmission", value: trans)
                                }
                                if let drive = decoded.driveType {
                                    DecodedInfoRow(label: "Drivetrain", value: drive)
                                }
                            }
                        }
                        .padding(LayoutConstants.padding4)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.statusSafeBg)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.statusSafe, lineWidth: 1)
                        )
                    }
                    
                    // Odometer Reading
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Odometer Reading")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 12) {
                            TextField("e.g. 75000", text: $odometerReading)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .keyboardType(.numberPad)
                            
                            Text("Miles")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, LayoutConstants.padding3)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 24)
            }
            
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Continue",
                    action: onContinue,
                    isEnabled: canContinue
                )
                
                Button(action: { if let onVinHelp = onVinHelp { onVinHelp() } else { onVehicleDetails() } }) {
                    Text("I can’t find the VIN number")
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textSecondary)
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
    }
}

struct VehicleDetailsStepView: View {
    @Binding var make: String
    @Binding var model: String
    @Binding var year: String
    @Binding var odometerReading: String
    let onContinue: () -> Void
    
    private var canContinue: Bool {
        !make.trimmingCharacters(in: .whitespaces).isEmpty &&
        !model.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Select your vehicle’s details.")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("Tell us the make, model, and year of the vehicle you’re checking. Year is optional.")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }

                    // Make picker
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Make")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            Text("*")
                                .foregroundColor(.statusDanger)
                        }

                        Menu {
                            ForEach(VehicleData.makes, id: \.self) { carMake in
                                Button(carMake) {
                                    make = carMake
                                    model = ""
                                }
                            }
                        } label: {
                            HStack {
                                Text(make.isEmpty ? "Select make" : make)
                                    .foregroundColor(make.isEmpty ? .textMuted : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                            }
                            .font(.system(size: FontSize.bodyLarge))
                            .padding(.horizontal, LayoutConstants.padding3)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        }
                    }

                    // Model picker
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Model")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            Text("*")
                                .foregroundColor(.statusDanger)
                        }

                        Menu {
                            let models = VehicleData.models(for: make)
                            if !models.isEmpty {
                                ForEach(models, id: \.self) { carModel in
                                    Button(carModel) {
                                        model = carModel
                                    }
                                }
                                Divider()
                                Button("Other") {
                                    model = "Other"
                                }
                            } else {
                                Button("Other") {
                                    model = "Other"
                                }
                            }
                        } label: {
                            HStack {
                                Text(model.isEmpty ? (make.isEmpty ? "Select make first" : "Select model") : model)
                                    .foregroundColor(model.isEmpty ? .textMuted : .textPrimary)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.textSecondary)
                            }
                            .font(.system(size: FontSize.bodyLarge))
                            .padding(.horizontal, LayoutConstants.padding3)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        }
                        .disabled(make.isEmpty)
                    }

                    // Year picker (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Year")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Text("Optional - leave blank if unknown")
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textMuted)

                        Picker("Year", selection: $year) {
                            Text("Unknown")
                                .foregroundColor(.textPrimary)
                                .tag("")
                            ForEach(VehicleYears.years, id: \.self) { yearOption in
                                Text(yearOption)
                                    .foregroundColor(.textPrimary)
                                    .tag(yearOption)
                            }
                        }
                        .pickerStyle(.wheel)
                        .colorScheme(.light)
                        .frame(height: 120)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                    
                    // Odometer Reading
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Odometer Reading")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        HStack(spacing: 12) {
                            TextField("e.g. 75000", text: $odometerReading)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .keyboardType(.numberPad)
                            
                            Text("Miles")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.horizontal, LayoutConstants.padding3)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
            
            VStack(spacing: 0) {
                PrimaryButton(
                    title: "Continue",
                    action: onContinue,
                    isEnabled: canContinue
                )
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
    }
}
struct PlaceholderStepView: View {
    let title: String
    let onContinue: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            Text(title)
                .font(.system(size: FontSize.h3, weight: .semibold))
                .foregroundColor(.textPrimary)
            Spacer()
            PrimaryButton(title: "Continue", action: onContinue)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
        }
    }
}

struct AnalyzingResultsView: View {
    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.4)
                .tint(.mintGreen)
            
            Text("We’re analyzing your results. Just a few more seconds.")
                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.deepBackground)
        .ignoresSafeArea(edges: .all)
    }
}

// MARK: - VIN Help Sheet (static article: what VIN looks like, why we need it, where to find it)
struct VINHelpSheet: View {
    let onDismiss: () -> Void
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("What is a VIN?")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("The Vehicle Identification Number (VIN) is a 17-character code that uniquely identifies your vehicle. It contains no letters I, O, or Q to avoid confusion with 1 and 0.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    
                    Text("Why does MintCheck need it?")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    Text("MintCheck uses your VIN to confirm the vehicle you're scanning matches the one you entered, and to look up recalls and safety information.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                        .lineSpacing(4)
                    
                    Text("Where to find your VIN")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    VStack(alignment: .leading, spacing: 12) {
                        BulletRow(text: "Driver's side dashboard — visible through the windshield (most common)")
                        BulletRow(text: "Driver's door jamb — on the sticker when you open the door")
                        BulletRow(text: "Engine bay — on a label or stamped on the block")
                    }
                    
                    Image("vin-location")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle("Find your VIN")
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

private struct BulletRow: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
            Text(text)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
        }
    }
}
