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
    let onViewDetails: (String) -> Void
    let onShare: () -> Void
    let onReturnHome: () -> Void
    
    @State private var expandedSections: Set<String> = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ResultsHeader(
                title: "Vehicle Scan Report",
                subtitle: vehicleInfo.displayName,
                onShare: onShare
            )
            
            // Content
            ScrollView {
                VStack(spacing: 24) {
                    // Recommendation badge
                    RecommendationBadge(recommendation: recommendation)
                    
                    // Vehicle details
                    VehicleDetailsCard(vehicleInfo: vehicleInfo)
                    
                    // Key findings
                    FindingsCard(
                        recommendation: recommendation,
                        findings: keyFindings,
                        priceRange: priceRange,
                        priceNote: priceNote,
                        repairEstimate: repairEstimate
                    )
                    
                    // System details
                    SystemDetailsCard(
                        systems: systemDetails,
                        expandedSections: $expandedSections
                    )
                    
                    // Disclaimer
                    InfoCard(
                        text: "This check reviews the car's systems. Other inspections may be needed.",
                        icon: "info.circle"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            
            // Fixed bottom
            VStack {
                PrimaryButton(
                    title: "Return to Dashboard",
                    action: onReturnHome
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
        .background(Color.deepBackground)
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
    
    private var priceRange: String {
        switch recommendation {
        case .safe: return "$15,000 - $17,000"
        case .caution: return "$13,000 - $15,000"
        case .notRecommended: return "$10,000 - $12,000"
        }
    }
    
    private var priceNote: String {
        switch recommendation {
        case .safe: return "The asking price appears fair for this condition."
        case .caution: return "Consider negotiating based on repair needs."
        case .notRecommended: return "The asking price appears high for this condition."
        }
    }
    
    private var repairEstimate: String? {
        switch recommendation {
        case .safe: return nil
        case .caution: return "Issues like these typically cost $800 - $2,500 to repair."
        case .notRecommended: return "Issues like these typically cost $2,500 - $5,000+ to repair."
        }
    }
    
    private var systemDetails: [SystemDetail] {
        let engineStatus = recommendation == .safe ? "Good" : "Needs Attention"
        let engineColor = recommendation == .safe ? Color.statusSafe : Color.statusCaution
        
        return [
            SystemDetail(
                name: "Engine",
                status: engineStatus,
                color: engineColor,
                details: recommendation == .safe
                    ? ["No trouble codes detected", "All sensors responding correctly", "Timing and performance normal"]
                    : ["3 trouble codes detected", "P0171 - Fuel system too lean", "P0300 - Random cylinder misfire detected"],
                explanation: recommendation == .safe
                    ? "The engine is operating normally with no issues detected."
                    : "The engine has some trouble codes that need attention. These may affect performance or reliability."
            ),
            SystemDetail(
                name: "Fuel System",
                status: recommendation == .notRecommended ? "Needs Attention" : "Good",
                color: recommendation == .notRecommended ? .statusCaution : .statusSafe,
                details: recommendation == .notRecommended
                    ? ["Fuel trim values outside normal range", "System compensating by +15%", "Possible vacuum leak or filter issue"]
                    : ["Fuel pressure within spec", "No leaks detected", "Injectors operating correctly"],
                explanation: recommendation == .notRecommended
                    ? "The fuel system is compensating for an issue. This could be a leak, clog, or sensor problem."
                    : "The fuel system is delivering the correct amount of fuel and maintaining proper pressure."
            ),
            SystemDetail(
                name: "Emissions",
                status: recommendation == .notRecommended ? "Needs Attention" : "Good",
                color: recommendation == .notRecommended ? .statusCaution : .statusSafe,
                details: recommendation == .notRecommended
                    ? ["Catalytic converter efficiency below threshold", "2 emissions monitors not ready", "May fail emissions testing"]
                    : ["Catalytic converter functioning normally", "All emissions monitors ready", "Should pass emissions testing"],
                explanation: recommendation == .notRecommended
                    ? "Some emissions systems are not functioning properly. This could cause the vehicle to fail emissions testing."
                    : "All emissions systems are functioning correctly."
            ),
            SystemDetail(
                name: "Electrical",
                status: "Good",
                color: .statusSafe,
                details: ["Battery voltage healthy", "All electrical sensors responding", "No wiring issues detected"],
                explanation: "The electrical system is functioning properly."
            )
        ]
    }
}

// MARK: - Recommendation Badge
struct RecommendationBadge: View {
    let recommendation: RecommendationType
    
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
            
            Text(recommendation.summary)
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

// MARK: - Findings Card
struct FindingsCard: View {
    let recommendation: RecommendationType
    let findings: [String]
    let priceRange: String
    let priceNote: String
    let repairEstimate: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Key findings
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
            }
            .padding(LayoutConstants.padding6)
            
            Divider()
            
            // Price context
            VStack(alignment: .leading, spacing: 12) {
                Text("Price Context")
                    .font(.system(size: FontSize.h5, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Similar vehicles typically list between ")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textPrimary)
                +
                Text(priceRange)
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                +
                Text(" in this condition.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textPrimary)
                
                Text(priceNote)
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                
                if let repair = repairEstimate {
                    Text(repair)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.statusWarning)
                }
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

struct SystemRow: View {
    let system: SystemDetail
    let isExpanded: Bool
    let onToggle: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header row
            Button(action: onToggle) {
                HStack {
                    HStack(spacing: 10) {
                        Circle()
                            .fill(system.color)
                            .frame(width: 8, height: 8)
                        
                        Text(system.name)
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.textPrimary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 10) {
                        Text(system.status)
                            .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                            .foregroundColor(.textSecondary)
                        
                        Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.textSecondary)
                    }
                }
                .padding(LayoutConstants.padding4)
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
                .background(Color.deepBackground)
            }
        }
    }
}

#Preview {
    ResultsView(
        vehicleInfo: VehicleInfo(year: "2018", make: "Honda", model: "Accord"),
        recommendation: .safe,
        scanResults: nil,
        onViewDetails: { _ in },
        onShare: {},
        onReturnHome: {}
    )
}
