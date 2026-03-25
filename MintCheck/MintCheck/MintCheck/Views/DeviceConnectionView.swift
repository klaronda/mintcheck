//
//  DeviceConnectionView.swift
//  MintCheck
//
//  OBD device connection screen
//

import SwiftUI
import NetworkExtension
import Combine
import CoreBluetooth

struct DeviceConnectionView: View {
    let onBack: () -> Void
    let onConnect: (DeviceType) -> Void
    
    @EnvironmentObject var connectionManager: ConnectionManagerService
    @State private var selectedType: DeviceType?
    @State private var showOBDHelp = false
    @State private var showWiFiSearching = false
    @State private var savedDevice: SavedDevice? = DeviceStorage.loadSavedDevice()
    
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
                        Text("Connect your OBD-II device into the vehicle’s port (usually under the dashboard on the driver’s side).")
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
                            description: "Recommended. Connect to the scanner’s Wi-Fi network.",
                            isSelected: selectedType == .wifi,
                            action: {
                                selectedType = .wifi
                                connectionManager.setDeviceType(.wifi)
                                // Start searching for WiFi networks
                                showWiFiSearching = true
                                Task {
                                    await connectionManager.wifiManager.connectToScanner(savedDevice: savedDevice)
                                }
                            }
                        )
                        
                        OptionCard(
                            icon: "antenna.radiowaves.left.and.right",
                            title: "Bluetooth Scanner",
                            description: "Pair with your scanner via Bluetooth settings.",
                            isSelected: selectedType == .bluetooth,
                            action: {
                                selectedType = .bluetooth
                                connectionManager.setDeviceType(.bluetooth)
                                // Initialize CoreBluetooth to trigger system prompt if Bluetooth is off
                                connectionManager.bluetoothManager.initialize()
                            }
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
                    title: "Connected - Start Scan",
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
        .overlay {
            // WiFi searching/connecting overlay
            if showWiFiSearching {
                WiFiSearchingView(
                    message: connectionManager.wifiManager.currentMessage,
                    onDismiss: {
                        showWiFiSearching = false
                        connectionManager.wifiManager.reset()
                    },
                    onRetry: {
                        Task {
                            await connectionManager.wifiManager.connectToScanner(savedDevice: savedDevice)
                        }
                    },
                    connectionState: connectionManager.wifiManager.connectionState,
                    connectedNetworkName: connectionManager.wifiManager.connectedNetworkName,
                    onConnected: { networkName in
                        // Save the device when successfully connected
                        let device = SavedDevice(
                            networkName: networkName,
                            deviceType: .wifi,
                            savedAt: Date()
                        )
                        DeviceStorage.saveDevice(device)
                        savedDevice = device
                        showWiFiSearching = false
                    }
                )
            }
        }
        .onAppear {
            // Try to auto-connect to saved device if available
            if let device = savedDevice, device.deviceType == .wifi {
                selectedType = .wifi
            }
        }
    }
}

// MARK: - Saved Device Model
struct SavedDevice: Codable {
    let networkName: String
    let deviceType: DeviceType
    let savedAt: Date
}

// MARK: - Device Storage
class DeviceStorage {
    private static let savedDeviceKey = "savedOBDDevice"
    
    static func saveDevice(_ device: SavedDevice) {
        if let encoded = try? JSONEncoder().encode(device) {
            UserDefaults.standard.set(encoded, forKey: savedDeviceKey)
        }
    }
    
    static func loadSavedDevice() -> SavedDevice? {
        guard let data = UserDefaults.standard.data(forKey: savedDeviceKey),
              let device = try? JSONDecoder().decode(SavedDevice.self, from: data) else {
            return nil
        }
        return device
    }
    
    static func clearSavedDevice() {
        UserDefaults.standard.removeObject(forKey: savedDeviceKey)
    }
}

// MARK: - WiFi Searching View
struct WiFiSearchingView: View {
    let message: String
    let onDismiss: () -> Void
    let onRetry: () -> Void
    let connectionState: WiFiConnectionState
    let connectedNetworkName: String?
    let onConnected: (String) -> Void
    
    private func openSettings() {
        if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsURL)
        }
    }
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.7)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo lockup
                Image("lockup-white")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 60)
                
                // Progress indicator
                if connectionState != .failed {
                    ProgressView()
                        .scaleEffect(1.5)
                        .tint(.white)
                }
                
                // Message
                VStack(spacing: 12) {
                    Text(message)
                        .font(.system(size: FontSize.bodyLarge, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if connectionState == .searching || connectionState == .connecting {
                        Text("Make sure your OBD-II WiFi device is plugged into the vehicle.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 40)
                
                // Action buttons
                if connectionState == .failed {
                    VStack(spacing: 12) {
                        PrimaryButton(
                            title: "Try Again",
                            action: onRetry
                        )
                        
                        Button(action: openSettings) {
                            Text("Open Settings")
                                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(0.2))
                                .cornerRadius(LayoutConstants.borderRadius)
                        }
                        .padding(.top, 8)
                        
                        Button(action: onDismiss) {
                            Text("Cancel")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.white.opacity(0.8))
                        }
                        .padding(.top, 8)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                } else if connectionState == .connected {
                    Button(action: {
                        if let networkName = connectedNetworkName {
                            onConnected(networkName)
                        } else {
                            onDismiss()
                        }
                    }) {
                        Text("Continue")
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.mintGreen)
                            .cornerRadius(LayoutConstants.borderRadius)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 8)
                } else {
                    Button(action: onDismiss) {
                        Text("Cancel")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding(.top, 8)
                }
            }
            .padding(40)
        }
        .onChange(of: connectionState) { _, newState in
            if newState == .connected, let networkName = connectedNetworkName {
                // Auto-save and dismiss when connected
                onConnected(networkName)
            }
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
                "Turn on the vehicle’s ignition",
                "Go to your phone’s Wi-Fi settings",
                "Connect to your scanner’s Wi-Fi network",
                "Return to this app"
            ]
        case .bluetooth:
            return [
                "Turn on the vehicle’s ignition",
                "Go to your phone’s Bluetooth settings",
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
                        
                        Text("The OBD-II port is a standardized 16-pin connector found in all cars manufactured after 1996. It’s typically located under the dashboard on the driver’s side, near the steering column.")
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
                        BulletPoint(text: "It’s usually within arm's reach of the driver's seat")
                        BulletPoint(text: "Check your vehicle’s owner manual for the exact location")
                        BulletPoint(text: "Some vehicles have a protective cover that needs to be removed")
                    }
                    
                    // Note
                    InfoCard(
                        text: "If you’re having trouble locating the port, ask the seller or check online resources for your specific vehicle make and model.",
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
            
            if let attributed = try? AttributedString(
                markdown: text,
                options: AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
            ) {
                Text(attributed)
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .tint(.mintGreen)
            } else {
                Text(text.replacingOccurrences(of: "**", with: ""))
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
            }
        }
    }
}

#Preview {
    DeviceConnectionView(onBack: {}, onConnect: { _ in })
}
