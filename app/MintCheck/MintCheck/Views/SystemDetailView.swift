//
//  SystemDetailView.swift
//  MintCheck
//
//  Detailed view of a specific system
//

import SwiftUI

struct SystemDetailView: View {
    let section: String
    let status: String
    let onBack: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(
                title: section,
                showBackButton: true,
                backAction: onBack
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Status card
                    HStack {
                        Circle()
                            .fill(statusColor)
                            .frame(width: 12, height: 12)
                        
                        Text(status)
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Spacer()
                    }
                    .padding(LayoutConstants.padding4)
                    .background(statusBackgroundColor)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                            .stroke(statusColor, lineWidth: 1)
                    )
                    
                    // Overview
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Overview")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text(overviewText)
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    .padding(LayoutConstants.padding6)
                    .background(Color.white)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    
                    // Details
                    VStack(alignment: .leading, spacing: 12) {
                        Text("What We Checked")
                            .font(.system(size: FontSize.h4, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            ForEach(checkedItems, id: \.self) { item in
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.statusSafe)
                                    
                                    Text(item)
                                        .font(.system(size: FontSize.bodyLarge))
                                        .foregroundColor(.textPrimary)
                                }
                            }
                        }
                    }
                    .padding(LayoutConstants.padding6)
                    .background(Color.white)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                    
                    // Recommendations (if issues found)
                    if status == "Needs Attention" {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recommended Actions")
                                .font(.system(size: FontSize.h4, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(recommendations, id: \.self) { rec in
                                    HStack(alignment: .top, spacing: 12) {
                                        Image(systemName: "arrow.right.circle.fill")
                                            .font(.system(size: 16))
                                            .foregroundColor(.statusCaution)
                                        
                                        Text(rec)
                                            .font(.system(size: FontSize.bodyLarge))
                                            .foregroundColor(.textPrimary)
                                    }
                                }
                            }
                        }
                        .padding(LayoutConstants.padding6)
                        .background(Color.statusCautionBg)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.statusCaution, lineWidth: 1)
                        )
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.deepBackground)
    }
    
    // MARK: - Computed Properties
    
    private var statusColor: Color {
        status == "Good" ? .statusSafe : .statusCaution
    }
    
    private var statusBackgroundColor: Color {
        status == "Good" ? .statusSafeBg : .statusCautionBg
    }
    
    private var overviewText: String {
        switch section {
        case "Engine":
            return status == "Good"
                ? "The engine is operating normally with no issues detected. All sensors are responding correctly and the timing is within normal parameters."
                : "The engine has some trouble codes that need attention. These may affect performance or reliability and should be addressed before purchase."
        case "Fuel System":
            return status == "Good"
                ? "The fuel system is delivering the correct amount of fuel and maintaining proper pressure. No leaks or irregularities detected."
                : "The fuel system is compensating for an issue. This could be a vacuum leak, clogged filter, or failing sensor that should be diagnosed."
        case "Emissions":
            return status == "Good"
                ? "All emissions systems are functioning correctly. The vehicle should pass emissions testing."
                : "Some emissions systems are not functioning properly. This could cause the vehicle to fail emissions testing and may indicate underlying issues."
        case "Electrical":
            return "The electrical system is functioning properly. Battery voltage is healthy and all sensors are responding correctly."
        default:
            return "System details are not available."
        }
    }
    
    private var checkedItems: [String] {
        switch section {
        case "Engine":
            return [
                "Diagnostic trouble codes (DTCs)",
                "Engine temperature",
                "RPM and idle stability",
                "Sensor responses",
                "Timing advance"
            ]
        case "Fuel System":
            return [
                "Fuel pressure",
                "Fuel trim values",
                "Injector operation",
                "Fuel level sensor",
                "System status"
            ]
        case "Emissions":
            return [
                "Catalytic converter efficiency",
                "Oxygen sensor readings",
                "Evaporative system",
                "Monitor readiness status",
                "Emissions codes"
            ]
        case "Electrical":
            return [
                "Battery voltage",
                "Alternator charging",
                "Sensor connections",
                "Ground circuits",
                "Module communication"
            ]
        default:
            return []
        }
    }
    
    private var recommendations: [String] {
        switch section {
        case "Engine":
            return [
                "Have a mechanic diagnose the specific trouble codes",
                "Request a compression test",
                "Consider negotiating the price based on repair costs"
            ]
        case "Fuel System":
            return [
                "Check for vacuum leaks",
                "Inspect fuel filter and fuel pump",
                "Verify MAF sensor operation"
            ]
        case "Emissions":
            return [
                "Drive the vehicle to complete monitor cycles",
                "Have catalytic converter tested",
                "Check for exhaust leaks"
            ]
        default:
            return []
        }
    }
}

#Preview {
    SystemDetailView(
        section: "Engine",
        status: "Needs Attention",
        onBack: {}
    )
}
