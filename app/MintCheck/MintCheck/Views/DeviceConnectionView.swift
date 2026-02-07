//
//  DeviceConnectionView.swift
//  MintCheck
//
//  OBD device connection screen
//

import SwiftUI

struct DeviceConnectionView: View {
    let onBack: () -> Void
    let onConnect: (DeviceType) -> Void
    
    @State private var selectedType: DeviceType?
    @State private var showOBDHelp = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(
                title: "Connect Scanner",
                showBackButton: true,
                backAction: onBack
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Headline
                    Text("Plug in your vehicle scanner.")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    // OBD port image
                    Image("obd-port")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    
                    // Instructions
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Connect your OBD-II device into the vehicle's port (usually under the dashboard on the driver's side).")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                        
                        Button(action: { showOBDHelp = true }) {
                            Text("Help me find the OBD-II port on this vehicle.")
                                .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Device type selection
                    VStack(spacing: 10) {
                        OptionCard(
                            icon: "wifi",
                            title: "Wi-Fi Scanner",
                            description: "Recommended. Connect to the scanner's Wi-Fi network.",
                            isSelected: selectedType == .wifi,
                            action: { selectedType = .wifi }
                        )
                        
                        OptionCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Bluetooth Scanner",
                            description: "Pair with your scanner via Bluetooth settings.",
                            isSelected: selectedType == .bluetooth,
                            action: { selectedType = .bluetooth }
                        )
                    }
                    
                    // Connection instructions
                    if let type = selectedType {
                        ConnectionInstructions(deviceType: type)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            
            // Sticky bottom
            VStack {
                PrimaryButton(
                    title: "I'm Connected – Start Scan",
                    action: {
                        if let type = selectedType {
                            onConnect(type)
                        }
                    },
                    isEnabled: selectedType != nil
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
        .sheet(isPresented: $showOBDHelp) {
            OBDHelpSheet()
        }
    }
}

// MARK: - Connection Instructions
struct ConnectionInstructions: View {
    let deviceType: DeviceType
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Connection Steps:")
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 8) {
                ForEach(Array(instructions.enumerated()), id: \.offset) { index, instruction in
                    HStack(alignment: .top, spacing: 12) {
                        Text("\(index + 1).")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                            .frame(width: 20, alignment: .leading)
                        
                        Text(instruction)
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                    }
                }
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
    
    private var instructions: [String] {
        switch deviceType {
        case .wifi:
            return [
                "Turn on the vehicle's ignition",
                "Go to your phone's Wi-Fi settings",
                "Connect to your scanner's Wi-Fi network",
                "Return to this app"
            ]
        case .bluetooth:
            return [
                "Turn on the vehicle's ignition",
                "Go to your phone's Bluetooth settings",
                "Pair with your OBD-II scanner",
                "Return to this app"
            ]
        }
    }
}

// MARK: - OBD Help Sheet
struct OBDHelpSheet: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Image
                    Image("obd-port")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.borderColor, lineWidth: 1)
                        )
                    
                    // Where is it
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Where is the OBD-II Port?")
                            .font(.system(size: FontSize.h5, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        Text("The OBD-II port is a standardized 16-pin connector found in all cars manufactured after 1996. It's typically located under the dashboard on the driver's side, near the steering column.")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Common locations
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Common Locations")
                            .font(.system(size: FontSize.h5, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        LocationItem(title: "Most Common", description: "Under the dashboard, left of the steering wheel")
                        LocationItem(title: "Alternative", description: "Under the dashboard, right of the steering wheel")
                        LocationItem(title: "Less Common", description: "Near the center console or behind the ashtray area")
                        LocationItem(title: "Rare", description: "Under the hood near the engine bay")
                    }
                    
                    // Tips
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Tips for Finding It")
                            .font(.system(size: FontSize.h5, weight: .semibold))
                            .foregroundColor(.textPrimary)
                        
                        BulletPoint(text: "Use a flashlight to look under the dashboard")
                        BulletPoint(text: "It's usually within arm's reach of the driver's seat")
                        BulletPoint(text: "Check your vehicle's owner manual for the exact location")
                        BulletPoint(text: "Some vehicles have a protective cover that needs to be removed")
                    }
                    
                    // Note
                    InfoCard(
                        text: "If you're having trouble locating the port, ask the seller or check online resources for your specific vehicle make and model.",
                        icon: "info.circle"
                    )
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle("Finding Your OBD-II Port")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.mintGreen)
                }
            }
        }
    }
}

struct LocationItem: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.textSecondary)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title + ":")
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(description)
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

struct BulletPoint: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("•")
                .foregroundColor(.textSecondary)
            
            Text(text)
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
        }
    }
}

#Preview {
    DeviceConnectionView(onBack: {}, onConnect: { _ in })
}
