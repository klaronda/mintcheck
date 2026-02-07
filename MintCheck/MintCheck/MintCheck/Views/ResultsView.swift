//
//  ResultsView.swift
//  MintCheck
//
//  Comprehensive scan results screen
//

import SwiftUI

struct ResultsView: View {
    let vehicleInfo: VehicleInfo
    let recommendation: RecommendationType
    let scanResults: OBDScanResults?
    let historyReport: VehicleHistoryReport?
    let valuationResult: ValuationService.ValuationResult?
    let askingPrice: Int?
    let dtcAnalysis: DTCAnalysisService.AnalysisResponse?
    let aiNetworkError: Bool
    let scanDate: Date?
    var reportStorage: ReportStorage = .uploaded
    var scanMode: ScanMode = .online_scan
    let onViewDetails: (String) -> Void
    let onShare: () -> Void
    let onClose: () -> Void
    let onDelete: () -> Void
    var onUploadNow: (() -> Void)? = nil
    var onReportIssue: (() -> Void)? = nil
    var onOpenDeepCheckReport: ((String) -> Void)? = nil
    var vinVerified: Bool? = nil
    var vinMismatch: Bool? = nil
    
    @Environment(\.openURL) private var openURL
    @State private var expandedSections: Set<String> = []
    @State private var showDeleteAlert = false
    @State private var enteredVINForDeepCheck: String? = nil
    @State private var deepCheckPurchaseForVIN: DeepCheckPurchase? = nil
    
    private var scanFreshness: ScanFreshness {
        computeScanFreshness(scanCompletedAt: scanDate)
    }
    
    private var reportStorageStatus: ReportStorageStatus {
        switch reportStorage {
        case .local_only: return .localOnly
        case .pending_upload: return .pendingUpload
        case .uploaded: return .uploaded
        }
    }

    /// VIN used for Deep Check block: from scan or user entry.
    private var effectiveDeepCheckVIN: String {
        (enteredVINForDeepCheck ?? vehicleInfo.vin ?? "").trimmingCharacters(in: .whitespaces)
    }

    private func loadDeepCheckPurchaseForVIN() async {
        if effectiveDeepCheckVIN.isEmpty || !effectiveDeepCheckVIN.isValidVIN {
            await MainActor.run { deepCheckPurchaseForVIN = nil }
            return
        }
        let list = (try? await DeepCheckService.shared.getMyDeepChecks()) ?? []
        let match = list.first { $0.vin.uppercased() == effectiveDeepCheckVIN.uppercased() && $0.status == "report_ready" }
        await MainActor.run { deepCheckPurchaseForVIN = match }
    }
    
    private var disclaimerText: String {
        var text = ""
        if let scanDate = scanDate {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM d, yyyy"
            let dateString = formatter.string(from: scanDate)
            text = "MintCheck scan was run on this vehicle on \(dateString) and is valid for 14 days. "
        }
        text += "This check reviews the car's systems. Other inspections may be needed."
        return text
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ResultsHeader(
                title: "Vehicle Scan Report",
                subtitle: vehicleInfo.displayName,
                onShare: onShare,
                onClose: onClose
            )
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Scan freshness + report status
                    HStack {
                        ScanFreshnessBadge(
                            freshness: scanFreshness,
                            showExpiryDate: true,
                            scannedAt: scanDate
                        )
                        Spacer()
                        ReportStatusBadge(status: reportStorageStatus)
                    }
                    
                    // Not uploaded yet + Upload now (when pending or local only)
                    if reportStorage == .pending_upload || reportStorage == .local_only {
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.clockwise.circle")
                                    .foregroundColor(.statusCaution)
                                Text(reportStorage == .local_only ? "Scan completed offline. We'll upload when you're back online." : "Not uploaded yet.")
                                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                    .foregroundColor(.textSecondary)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.statusCautionBg)
                            .cornerRadius(LayoutConstants.borderRadius)
                            if let upload = onUploadNow {
                                PrimaryButton(title: "Upload now", action: upload)
                            }
                        }
                    }
                    
                    // VIN mismatch warning (blocks future scans until resolved)
                    if vinMismatch == true {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.statusCaution)
                            Text("The VIN from the vehicle doesn't match what you entered. Future scans are blocked until this is resolved. Please contact support.")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.statusCautionBg)
                        .cornerRadius(LayoutConstants.borderRadius)
                    }
                    
                    // VIN unverified prompt (post-scan)
                    if vinVerified == false && vinMismatch != true {
                        HStack(alignment: .top, spacing: 8) {
                            Image(systemName: "info.circle.fill")
                                .foregroundColor(.textSecondary)
                            Text("We couldn't confirm this VIN. To continue using MintCheck, you'll need to verify your vehicle's VIN.")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.deepBackground)
                        .cornerRadius(LayoutConstants.borderRadius)
                    }
                    
                    // 1. Recommendation badge
                    RecommendationBadge(
                        recommendation: recommendation,
                        aiExplanation: dtcAnalysis?.summary
                    )
                    
                    // 2. What We Found (merged with pricing)
                    FindingsWithPricingCard(
                        recommendation: recommendation,
                        findings: keyFindings,
                        repairEstimate: repairEstimate,
                        vehicleInfo: vehicleInfo,
                        askingPrice: askingPrice,
                        valuationResult: valuationResult,
                        aiNetworkError: aiNetworkError,
                        onCheckGoogle: openGoogleSearch,
                        onReportIssue: onReportIssue
                    )
                    
                    // 3. System details
                    SystemDetailsCard(
                        systems: systemDetails,
                        expandedSections: $expandedSections
                    )
                    
                    // 3b. Deep Vehicle Check: VIN entry, result card, or upsell
                    DeepCheckBlockView(
                        effectiveVIN: effectiveDeepCheckVIN,
                        vehicleInfoVIN: vehicleInfo.vin,
                        enteredVIN: $enteredVINForDeepCheck,
                        purchase: deepCheckPurchaseForVIN,
                        onOpenReport: onOpenDeepCheckReport
                    )
                    .task(id: effectiveDeepCheckVIN) {
                        await loadDeepCheckPurchaseForVIN()
                    }
                    
                    // 4. More Model Details (NHTSA data) - if available
                    if let history = historyReport {
                        MoreModelDetailsCard(report: history)
                    }
                    
                    // 5. Vehicle details
                    VehicleDetailsCard(vehicleInfo: vehicleInfo)
                    
                    // Disclaimer with scan date
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        
                        Text(disclaimerText)
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Delete scan link
                    Button(action: { showDeleteAlert = true }) {
                        Text("Delete this car scan")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.statusDanger)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 40)
            }
        }
        .background(Color.deepBackground)
        .alert("Delete Scan?", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) { onDelete() }
        } message: {
            Text("This scan will be permanently removed.")
        }
    }
    
    // MARK: - Helpers
    
    private func openGoogleSearch() {
        // Build Google search query: "{year} {make} {model} {trim?} value"
        var queryComponents: [String] = []
        
        // Add year
        queryComponents.append(vehicleInfo.year)
        
        // Add make
        queryComponents.append(vehicleInfo.make)
        
        // Add model
        queryComponents.append(vehicleInfo.model)
        
        // Add trim if available
        if let trim = vehicleInfo.trim, !trim.isEmpty, trim != "Unknown" {
            queryComponents.append(trim)
        }
        
        // Add "US national average value" keywords
        queryComponents.append("US national average value")
        
        let query = queryComponents.joined(separator: " ")
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        let urlString = "https://www.google.com/search?q=\(encodedQuery)"
        
        if let url = URL(string: urlString) {
            openURL(url)
        }
    }
    
    // MARK: - Computed Properties
    
    private var keyFindings: [String] {
        if let results = scanResults {
            return results.keyFindings
        }
        
        // Default findings based on recommendation
        switch recommendation {
        case .safe:
            return [
                "No trouble codes found",
                "Engine temperature normal",
                "Fuel system operating correctly",
                "Emissions system functioning properly"
            ]
        case .caution:
            return [
                "Some systems haven't completed self-checks yet",
                "Fuel system compensating more than expected",
                "One emissions monitor not ready"
            ]
        case .notRecommended:
            return [
                "Multiple engine trouble codes detected",
                "Fuel system showing irregular patterns",
                "Emissions system not functioning properly",
                "Temperature controls showing concerns"
            ]
        }
    }
    
    private var repairEstimate: String? {
        // Only show repair estimates if there are actual DTCs
        let hasDTCs = !(scanResults?.dtcs ?? []).isEmpty
        
        if !hasDTCs {
            // No repair estimate if only issue is "recently cleared codes" or human checks
            return nil
        }
        
        switch recommendation {
        case .safe: return nil
        case .caution: return "Issues like these typically cost $800 - $2,500 to repair."
        case .notRecommended: return "Issues like these typically cost $2,500 - $5,000+ to repair."
        }
    }
    
    private static let unknownSystemMessage = "We weren't able to scan any data for this system. This can be an issue with the car or scanner. We recommend getting a professional inspection."
    
    private var systemDetails: [SystemDetail] {
        // Use actual scan data when available
        let dtcs = scanResults?.dtcs ?? []
        let hasDTCs = !dtcs.isEmpty
        let emissionsDTCs = dtcs.filter { $0.hasPrefix("P04") || $0.hasPrefix("P044") }
        
        // Engine - need at least rpm or coolantTemp, or DTCs (DTCs mean we have engine data)
        let hasEngineData = (scanResults?.rpm != nil || scanResults?.coolantTemp != nil) || hasDTCs
        let engineStatus: String
        let engineColor: Color
        var engineDetails: [String] = []
        var engineExplanation: String
        
        if !hasEngineData {
            engineStatus = "Unknown"
            engineColor = Color.gray
            engineDetails = ["No engine data was reported by the vehicle", "Scanner attempted a second read"]
            engineExplanation = Self.unknownSystemMessage
        } else if hasDTCs {
            engineStatus = "Needs Attention"
            engineColor = Color.statusCaution
            engineDetails.append("\(dtcs.count) trouble code\(dtcs.count == 1 ? "" : "s") detected")
            for dtc in dtcs.prefix(3) { engineDetails.append(dtc) }
            if dtcs.count > 3 { engineDetails.append("+ \(dtcs.count - 3) more codes") }
            engineExplanation = "The engine has trouble codes that need attention. These may affect performance or reliability."
        } else {
            engineStatus = "Good"
            engineColor = Color.statusSafe
            engineDetails = ["No trouble codes detected", "All sensors responding correctly", "Timing and performance normal"]
            engineExplanation = "The engine is operating normally with no issues detected."
        }
        
        // Fuel System - need at least one of fuelLevel or trims
        let hasFuelData = scanResults?.fuelLevel != nil || scanResults?.shortTermFuelTrim != nil || scanResults?.longTermFuelTrim != nil
        let fuelOK = (scanResults?.fuelLevel ?? 50) > 10
        let fuelStatus: String
        let fuelColor: Color
        let fuelDetails: [String]
        let fuelExplanation: String
        
        if !hasFuelData {
            fuelStatus = "Unknown"
            fuelColor = Color.gray
            fuelDetails = ["No fuel system data was reported by the vehicle", "Scanner attempted a second read"]
            fuelExplanation = Self.unknownSystemMessage
        } else if fuelOK {
            fuelStatus = "Good"
            fuelColor = Color.statusSafe
            fuelDetails = ["Fuel system operating normally", "No leaks detected", "Injectors responding correctly"]
            fuelExplanation = "The fuel system is delivering the correct amount of fuel and maintaining proper pressure."
        } else {
            fuelStatus = "Low"
            fuelColor = Color.statusCaution
            fuelDetails = ["Fuel level low", "Check fuel system if recently filled"]
            fuelExplanation = "The fuel level is low. If you recently filled up, there may be a fuel system issue."
        }
        
        // Emissions - need emissions DTCs or barometricPressure
        let hasEmissionsData = !emissionsDTCs.isEmpty || scanResults?.barometricPressure != nil
        let emissionsOK = emissionsDTCs.isEmpty
        let emissionsStatus: String
        let emissionsColor: Color
        let emissionsDetails: [String]
        let emissionsExplanation: String
        
        if !hasEmissionsData {
            emissionsStatus = "Unknown"
            emissionsColor = Color.gray
            emissionsDetails = ["No emissions data was reported by the vehicle", "Scanner attempted a second read"]
            emissionsExplanation = Self.unknownSystemMessage
        } else if emissionsOK {
            emissionsStatus = "Good"
            emissionsColor = Color.statusSafe
            emissionsDetails = ["Catalytic converter functioning normally", "All emissions monitors ready", "Should pass emissions testing"]
            emissionsExplanation = "All emissions systems are functioning correctly."
        } else {
            emissionsStatus = "Needs Attention"
            emissionsColor = Color.statusCaution
            emissionsDetails = ["Emissions-related codes detected"] + emissionsDTCs.prefix(2).map { $0 }
            emissionsExplanation = "Some emissions systems may need attention. This could affect emissions testing."
        }
        
        // Electrical - need battery voltage
        let hasElectricalData = scanResults?.batteryVoltage != nil
        let voltage = scanResults?.batteryVoltage ?? 0
        let electricalOK = voltage >= 12.4 && voltage <= 14.8
        let electricalStatus: String
        let electricalColor: Color
        var electricalDetails: [String] = []
        let electricalExplanation: String
        
        if !hasElectricalData {
            electricalStatus = "Unknown"
            electricalColor = Color.gray
            electricalDetails = ["No battery/electrical data was reported by the vehicle", "Scanner attempted a second read"]
            electricalExplanation = Self.unknownSystemMessage
        } else if electricalOK {
            electricalStatus = "Good"
            electricalColor = Color.statusSafe
            electricalDetails = ["Battery voltage: \(String(format: "%.1f", voltage))V", "Charging system normal", "All electrical sensors responding"]
            electricalExplanation = "The electrical system is functioning properly."
        } else {
            electricalStatus = "Needs Attention"
            electricalColor = Color.statusCaution
            electricalDetails = ["Battery voltage: \(String(format: "%.1f", voltage))V", "Voltage outside normal range"]
            electricalExplanation = "Battery voltage is outside the normal range (12.4V - 14.8V). The battery or alternator may need attention."
        }
        
        return [
            SystemDetail(
                name: "Engine",
                status: engineStatus,
                color: engineColor,
                details: engineDetails,
                explanation: engineExplanation
            ),
            SystemDetail(
                name: "Fuel System",
                status: fuelStatus,
                color: fuelColor,
                details: fuelDetails,
                explanation: fuelExplanation
            ),
            SystemDetail(
                name: "Emissions",
                status: emissionsStatus,
                color: emissionsColor,
                details: emissionsDetails,
                explanation: emissionsExplanation
            ),
            SystemDetail(
                name: "Electrical",
                status: electricalStatus,
                color: electricalColor,
                details: electricalDetails,
                explanation: electricalExplanation
            )
        ]
    }
}

// MARK: - Recommendation Badge
struct RecommendationBadge: View {
    let recommendation: RecommendationType
    var aiExplanation: String? = nil
    
    /// The text to display - AI explanation if available, otherwise static summary
    private var displayText: String {
        if let explanation = aiExplanation, !explanation.isEmpty {
            return explanation
        }
        return recommendation.summary
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .fill(recommendation.color)
                        .frame(width: 48, height: 48)
                    
                    Image(systemName: recommendation.iconName)
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                Text(recommendation.title)
                    .font(.system(size: FontSize.h2, weight: .semibold))
                    .foregroundColor(recommendation.color)
            }
            
            Text(displayText)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textPrimary)
                .lineSpacing(4)
        }
        .padding(LayoutConstants.padding6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(recommendation.backgroundColor)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(recommendation.color, lineWidth: 2)
        )
    }
}

// MARK: - Findings with Pricing Card (merged)
struct FindingsWithPricingCard: View {
    let recommendation: RecommendationType
    let findings: [String]
    let repairEstimate: String?
    let vehicleInfo: VehicleInfo
    let askingPrice: Int?
    let valuationResult: ValuationService.ValuationResult?
    let aiNetworkError: Bool
    let onCheckGoogle: () -> Void
    var onReportIssue: (() -> Void)? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Key findings section
            VStack(alignment: .leading, spacing: 16) {
                Text("What We Found")
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(findings, id: \.self) { finding in
                        HStack(alignment: .top, spacing: 10) {
                            Circle()
                                .fill(recommendation.color)
                                .frame(width: 6, height: 6)
                                .padding(.top, 6)
                            
                            Text(finding)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .lineSpacing(4)
                        }
                    }
                }
                
                if let repair = repairEstimate {
                    Text(repair)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.statusWarning)
                        .padding(.top, 4)
                }
            }
            .padding(LayoutConstants.padding6)
            
            Divider()
            
            // Price context section
            VStack(alignment: .leading, spacing: 12) {
                Text("Price Context")
                    .font(.system(size: FontSize.h5, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                // Asking price if provided (compact)
                if let asking = askingPrice, asking > 0 {
                    HStack {
                        Text("Asking Price:")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                        
                        Text(formatCurrency(asking))
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                }
                
                // Show AI valuation if available
                if let valuation = valuationResult, valuation.lowEstimate > 0, valuation.highEstimate > 0 {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("US National Average Value:")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                        
                        Text(valuation.formattedRange)
                            .font(.system(size: FontSize.h4, weight: .bold))
                            .foregroundColor(.textPrimary)
                    }
                    .padding(.top, 4)
                } else if aiNetworkError {
                    // Network error - show specific message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estimated value not available. You are not connected to the internet.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                        if let report = onReportIssue {
                            Button(action: report) {
                                Text("Report this issue")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.mintGreen)
                            }
                        }
                    }
                    .padding(.top, 4)
                }
                
                Text("Current market prices for a \(vehicleInfo.year) \(vehicleInfo.make) \(vehicleInfo.model) may vary by trim, condition and region.")
                    .font(.system(size: FontSize.bodyRegular))
                    .foregroundColor(.textSecondary)
                
                // Google search fallback button (always show if no valuation or as additional option)
                Button(action: onCheckGoogle) {
                    HStack(spacing: 8) {
                        Text("Check Value on Google")
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.mintGreen)
                    .cornerRadius(LayoutConstants.borderRadius)
                }
                .padding(.top, 8)
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
    
    private func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Vehicle Details Card
struct VehicleDetailsCard: View {
    let vehicleInfo: VehicleInfo
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Vehicle Details")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
                .padding(.bottom, 16)
                .padding(.horizontal, LayoutConstants.padding6)
                .padding(.top, LayoutConstants.padding6)
            
            Divider()
            
            VStack(spacing: 12) {
                if let vin = vehicleInfo.vin {
                    DetailRow(label: "VIN", value: vin, isMonospace: true)
                }
                DetailRow(label: "Year", value: vehicleInfo.year)
                DetailRow(label: "Make", value: vehicleInfo.make)
                DetailRow(label: "Model", value: vehicleInfo.model)
                if let trim = vehicleInfo.trim {
                    DetailRow(label: "Trim", value: trim)
                }
                if let fuel = vehicleInfo.fuelType {
                    DetailRow(label: "Fuel Type", value: fuel)
                }
                if let engine = vehicleInfo.engine {
                    DetailRow(label: "Engine", value: engine)
                }
                if let trans = vehicleInfo.transmission {
                    DetailRow(label: "Transmission", value: trans)
                }
                if let drive = vehicleInfo.drivetrain {
                    DetailRow(label: "Drivetrain", value: drive)
                }
            }
            .padding(.horizontal, LayoutConstants.padding6)
            .padding(.vertical, LayoutConstants.padding4)
            
            if !vehicleInfo.hasDecodedDetails {
                Divider()
                
                Text(vehicleInfo.vin != nil
                    ? "VIN could not be decoded. Details shown are based on user input."
                    : "VIN was not provided. Details shown are based on user input.")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                    .padding(.horizontal, LayoutConstants.padding6)
                    .padding(.vertical, LayoutConstants.padding4)
            }
        }
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    var isMonospace: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            Text(value)
                .font(isMonospace
                    ? .system(size: FontSize.bodyRegular, weight: .semibold).monospaced()
                    : .system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(.textPrimary)
        }
    }
}

// MARK: - System Details Card
struct SystemDetailsCard: View {
    let systems: [SystemDetail]
    @Binding var expandedSections: Set<String>
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            Text("System Details")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(LayoutConstants.padding5)
            
            Divider()
            
            // Systems
            ForEach(Array(systems.enumerated()), id: \.element.id) { index, system in
                SystemRow(
                    system: system,
                    isExpanded: expandedSections.contains(system.name),
                    onToggle: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            if expandedSections.contains(system.name) {
                                expandedSections.remove(system.name)
                            } else {
                                expandedSections.insert(system.name)
                            }
                        }
                    }
                )
                
                if index < systems.count - 1 {
                    Divider()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

// MARK: - Deep Check block: VIN entry, result card, or upsell
private struct DeepCheckBlockView: View {
    let effectiveVIN: String
    let vehicleInfoVIN: String?
    @Binding var enteredVIN: String?
    let purchase: DeepCheckPurchase?
    var onOpenReport: ((String) -> Void)?

    var body: some View {
        if effectiveVIN.isEmpty || !effectiveVIN.isValidVIN {
            DeepCheckVINEntryCard(
                initialVIN: vehicleInfoVIN ?? "",
                onContinue: { vin in enteredVIN = vin }
            )
        } else if let purchase = purchase,
                  purchase.status == "report_ready",
                  let reportUrl = purchase.reportUrl, !reportUrl.isEmpty {
            DeepCheckResultCard(
                reportUrl: reportUrl,
                recommendationStatus: purchase.recommendationStatus,
                onViewReport: { onOpenReport?(reportUrl) }
            )
        } else {
            DeepVehicleCheckCard(vin: effectiveVIN)
        }
    }
}

// MARK: - VIN entry for Deep Check (when scan VIN missing or invalid)
private struct DeepCheckVINEntryCard: View {
    let initialVIN: String
    let onContinue: (String) -> Void
    @State private var text: String = ""
    @State private var errorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Deep Vehicle Check")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text("Enter this vehicle's VIN to see if you already have a report or to buy one. Accident history, title status, salvage records.")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)
            TextField("VIN (17 characters)", text: $text)
                .textInputAutocapitalization(.characters)
                .autocorrectionDisabled()
                .font(.system(size: FontSize.bodyRegular, design: .monospaced))
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(LayoutConstants.borderRadius)
                .onChange(of: text) { _, _ in errorMessage = nil }
            if let err = errorMessage {
                Text(err)
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.statusDanger)
            }
            Button(action: continueTapped) {
                Text("Continue")
                    .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(Color.mintGreen)
            .cornerRadius(LayoutConstants.borderRadius)
        }
        .padding(LayoutConstants.padding6)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .onAppear {
            if text.isEmpty, !initialVIN.isEmpty {
                text = String(initialVIN.prefix(17)).uppercased()
            }
        }
    }

    private func continueTapped() {
        let trimmed = text.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count == 17 else {
            errorMessage = "VIN must be 17 characters."
            return
        }
        guard trimmed.isValidVIN else {
            errorMessage = "VIN cannot contain I, O, or Q."
            return
        }
        errorMessage = nil
        onContinue(trimmed)
    }
}

// MARK: - Deep Check result card (report already purchased)
private struct DeepCheckResultCard: View {
    let reportUrl: String
    let recommendationStatus: String?
    let onViewReport: () -> Void

    private var isProblemsReported: Bool {
        recommendationStatus == "problems_reported"
    }

    private var statusColor: Color {
        isProblemsReported ? .statusDanger : .mintGreen
    }

    private var statusBg: Color {
        isProblemsReported ? Color(red: 1, green: 0.9, blue: 0.9) : Color(red: 0.24, green: 0.96, blue: 0.93, opacity: 0.15)
    }

    private var statusText: String {
        isProblemsReported ? "Problems Reported" : "History Available"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 10) {
                Image(systemName: isProblemsReported ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                    .foregroundColor(statusColor)
                Text("Vehicle History Report")
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(.textPrimary)
            }
            Text(statusText)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
            Button(action: onViewReport) {
                Text("View Vehicle History")
                    .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .background(Color.mintGreen)
            .cornerRadius(LayoutConstants.borderRadius)
        }
        .padding(LayoutConstants.padding6)
        .background(statusBg)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(statusColor, lineWidth: 1.5)
        )
    }
}

// MARK: - Deep Vehicle Check Upsell Card
struct DeepVehicleCheckCard: View {
    let vin: String
    @Environment(\.openURL) private var openURL
    @EnvironmentObject var authService: AuthService
    @State private var isCreatingSession = false
    @State private var showCheckoutError = false
    @State private var checkoutErrorMessage: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Get a Deep Vehicle Check")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)

            Text("Accident history, title status, salvage records, and more. Same as Carfax, but $30 less.")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .lineSpacing(4)

            HStack {
                Text("$9.99")
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                Spacer()
                Button(action: {
                    Task { await startCheckout() }
                }) {
                    if isCreatingSession {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.9)
                    } else {
                        Text("Add Now")
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.white)
                    }
                }
                .disabled(isCreatingSession)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color.mintGreen)
                .cornerRadius(LayoutConstants.borderRadius)
            }
        }
        .padding(LayoutConstants.padding6)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
        .alert("Could not start checkout", isPresented: $showCheckoutError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(checkoutErrorMessage ?? "Please try again.")
        }
    }

    private func startCheckout() async {
        guard !vin.isEmpty else { return }
        isCreatingSession = true
        defer { isCreatingSession = false }
        do {
            let url = try await DeepCheckService.shared.createSession(vin: vin)
            await MainActor.run {
                openURL(url)
            }
        } catch {
            await MainActor.run {
                checkoutErrorMessage = (error as? DeepCheckError)?.message ?? "Could not start checkout. Please try again."
                showCheckoutError = true
            }
        }
    }
}

struct SystemRow: View {
    let system: SystemDetail
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row - gray when expanded
            Button(action: onToggle) {
                HStack {
                    HStack(spacing: 10) {
                        if system.status == "Unknown" {
                            Image(systemName: "questionmark.circle.fill")
                                .font(.system(size: 18))
                                .foregroundColor(Color.gray)
                        } else {
                            Circle()
                                .fill(system.color)
                                .frame(width: 8, height: 8)
                        }
                        
                        Text(system.name)
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Text(system.status)
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(system.status == "Unknown" ? Color.gray : .textSecondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(LayoutConstants.padding4)
                .background(isExpanded ? Color.deepBackground : Color.clear)
            }
            
            // Expanded content
            if isExpanded {
                VStack(alignment: .leading, spacing: 12) {
                    Text(system.explanation)
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textPrimary)
                        .lineSpacing(4)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(system.details, id: \.self) { detail in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                    .foregroundColor(.textSecondary)
                                
                                Text(detail)
                                    .font(.system(size: FontSize.bodyRegular))
                                    .foregroundColor(.textSecondary)
                            }
                        }
                    }
                }
                .padding(.horizontal, LayoutConstants.padding4)
                .padding(.bottom, LayoutConstants.padding4)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.deepBackground)
            }
        }
    }
}

// MARK: - More Model Details Card (renamed from Vehicle History)

struct MoreModelDetailsCard: View {
    let report: VehicleHistoryReport
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundColor(.mintGreen)
                    
                    Text("More Model Details")
                        .font(.system(size: FontSize.h4, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Spacer()
                }
                
                // Summary stats - only recalls and safety (no complaints)
                HStack(spacing: 16) {
                    HistoryStatBadge(
                        icon: "exclamationmark.triangle.fill",
                        value: "\(report.recallCount)",
                        label: "Recalls",
                        color: report.hasOpenRecalls ? .statusDanger : .statusSafe
                    )
                    
                    if let stars = report.safetyRatings?.overallStars {
                        HistoryStatBadge(
                            icon: "star.fill",
                            value: "\(stars)/5",
                            label: "Safety",
                            color: stars >= 4 ? .statusSafe : (stars >= 3 ? .statusCaution : .statusDanger)
                        )
                    }
                    
                    // Spacer to balance layout if only 2 items
                    if report.safetyRatings?.overallStars == nil {
                        Spacer()
                    }
                }
            }
            .padding(LayoutConstants.padding6)
            
            // Expandable details
            if isExpanded {
                Divider()
                
                VStack(alignment: .leading, spacing: 16) {
                    // Recalls section
                    if !report.recalls.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Open Recalls")
                                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                .foregroundColor(.statusDanger)
                            
                            ForEach(report.recalls.prefix(3)) { recall in
                                HStack(alignment: .top, spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.statusDanger)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(recall.component ?? "Unknown Component")
                                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                            .foregroundColor(.textPrimary)
                                        
                                        if let summary = recall.summary {
                                            Text(summary)
                                                .font(.system(size: FontSize.bodySmall))
                                                .foregroundColor(.textSecondary)
                                                .lineLimit(2)
                                        }
                                    }
                                }
                            }
                            
                            if report.recalls.count > 3 {
                                Text("+ \(report.recalls.count - 3) more recalls")
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.textMuted)
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.statusSafe)
                            Text("No open recalls found")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.statusSafe)
                        }
                    }
                    
                    // Safety ratings
                    if let safety = report.safetyRatings {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NHTSA Safety Ratings")
                                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            if let overall = safety.overallRating {
                                SafetyRatingRow(label: "Overall", rating: overall)
                            }
                            if let frontal = safety.frontalCrashRating {
                                SafetyRatingRow(label: "Frontal Crash", rating: frontal)
                            }
                            if let side = safety.sideCrashRating {
                                SafetyRatingRow(label: "Side Crash", rating: side)
                            }
                            if let rollover = safety.rolloverRating {
                                SafetyRatingRow(label: "Rollover", rating: rollover)
                            }
                        }
                    }
                    
                    // Data source note
                    Text("Data from NHTSA (National Highway Traffic Safety Administration)")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textMuted)
                        .italic()
                }
                .padding(LayoutConstants.padding6)
                .background(Color.deepBackground)
            }
            
            // Toggle button
            Button(action: { withAnimation { isExpanded.toggle() } }) {
                HStack {
                    Spacer()
                    Text(isExpanded ? "Show Less" : "Show Details")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.mintGreen)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12))
                        .foregroundColor(.mintGreen)
                    Spacer()
                }
                .padding(.vertical, 12)
                .background(Color.deepBackground)
            }
        }
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
}

struct HistoryStatBadge: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Text(value)
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(label)
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SafetyRatingRow: View {
    let label: String
    let rating: String
    
    var stars: Int {
        Int(rating) ?? 0
    }
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
            
            Spacer()
            
            if stars > 0 {
                HStack(spacing: 2) {
                    ForEach(0..<5) { index in
                        Image(systemName: index < stars ? "star.fill" : "star")
                            .font(.system(size: 12))
                            .foregroundColor(index < stars ? .statusCaution : .borderColor)
                    }
                }
            } else {
                Text("Not Rated")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textMuted)
            }
        }
    }
}

#Preview {
    ResultsView(
        vehicleInfo: VehicleInfo(year: "2020", make: "Subaru", model: "Outback"),
        recommendation: .safe,
        scanResults: nil,
        historyReport: nil,
        valuationResult: nil,
        askingPrice: 4500,
        dtcAnalysis: nil,
        aiNetworkError: false,
        scanDate: Calendar.current.date(byAdding: .day, value: -3, to: Date()),
        onViewDetails: { _ in },
        onShare: {},
        onClose: {},
        onDelete: {},
        onUploadNow: nil
    )
}
