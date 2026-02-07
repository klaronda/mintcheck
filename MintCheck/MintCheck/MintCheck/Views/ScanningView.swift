//
//  ScanningView.swift
//  MintCheck
//
//  Active scan progress screen with mid-scan drop recovery.
//

import SwiftUI

struct ScanningView: View {
    let onComplete: (OBDScanResults) -> Void
    let onStartOver: (() -> Void)?  // Return to connect step when scan interrupted
    @ObservedObject var obdService: OBDService
    var onReportIssue: ((String?) -> Void)? = nil  // Optional "Report this issue" with current error message
    @State private var currentStatusIndex = 0
    @State private var hasError = false
    @State private var errorMessage: String?
    @State private var isInterrupted = false  // Show recovery UI: Retry / Start Over / Troubleshoot
    @State private var showTroubleshootSheet = false
    
    private let statuses: [(icon: String, text: String)] = [
        ("waveform.path.ecg", "Connecting to vehicle..."),
        ("doc.text.magnifyingglass", "Reading vehicle data..."),
        ("gauge.with.dots.needle.bottom.50percent", "Checking engine health..."),
        ("drop.fill", "Analyzing fuel system..."),
        ("wind", "Checking emissions..."),
        ("thermometer", "Reviewing temperature controls..."),
        ("bolt.fill", "Finalizing scan...")
    ]
    
    private let statusDisplayInterval: TimeInterval = 4.0
    
    var body: some View {
        VStack {
            Spacer()
            
            // Loader
            ZStack {
                // Outer progress ring (background track)
                Circle()
                    .stroke(Color.borderColor, lineWidth: 4)
                    .frame(width: 100, height: 100)
                
                // Icon (no background)
                Image(systemName: statuses[currentStatusIndex].icon)
                    .font(.system(size: 36))
                    .foregroundColor(.mintGreen)
            }
            .padding(.bottom, 32)
            
            // Status text
            VStack(spacing: 8) {
                Text("Scanning Vehicle")
                    .font(.system(size: FontSize.h4, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text(obdService.currentStatus.isEmpty ? statuses[currentStatusIndex].text : obdService.currentStatus)
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
            }
            .padding(.bottom, 32)
            
            // Progress bar
            VStack(spacing: 12) {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Track
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.borderColor)
                            .frame(height: 4)
                        
                        // Fill
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.mintGreen)
                            .frame(width: geometry.size.width * obdService.scanProgress, height: 4)
                            .animation(.easeInOut(duration: 0.5), value: obdService.scanProgress)
                    }
                }
                .frame(height: 4)
                
                Text("This usually takes 15-30 seconds")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
            }
            .padding(.horizontal, 48)
            
            Spacer()
            
            // Info card
            InfoCard(
                text: "Keep your phone nearby. The vehicle's ignition should stay on during the scan.",
                icon: "info.circle"
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.deepBackground)
        .onAppear {
            if !isInterrupted { startScan() }
        }
        .overlay {
            if isInterrupted {
                scanInterruptedRecoveryOverlay
            }
        }
        .alert("Scan Error", isPresented: $hasError) {
            Button("Try Again") {
                isInterrupted = false
                startScan()
            }
            Button("Cancel", role: .cancel) {
                onStartOver?()
            }
            if onReportIssue != nil {
                Button("Report this issue") {
                    onReportIssue?(errorMessage)
                }
            }
        } message: {
            Text(errorMessage ?? "An error occurred during the scan.")
        }
        .sheet(isPresented: $showTroubleshootSheet) {
            TroubleshootSheet(onDismiss: { showTroubleshootSheet = false })
        }
    }
    
    private var scanInterruptedRecoveryOverlay: some View {
        VStack(spacing: 24) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.statusCaution)
            Text("Connection lost")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            Text("The connection to your scanner was lost. You can retry the connection or start over.")
                .font(.system(size: FontSize.bodyLarge))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            VStack(spacing: 12) {
                PrimaryButton(title: "Retry Connection", action: {
                    isInterrupted = false
                    startScan()
                })
                Button(action: { onStartOver?() }) {
                    Text("Start Over")
                        .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                        .foregroundColor(.mintGreen)
                }
                Button(action: { showTroubleshootSheet = true }) {
                    Text("Troubleshoot")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.deepBackground)
    }
    
    private func startScan() {
        hasError = false
        errorMessage = nil
        isInterrupted = false
        
        Task {
            do {
                try await obdService.connect()
                startStatusAnimation()
                let results = try await obdService.performScan()
                obdService.disconnect()
                await MainActor.run { onComplete(results) }
            } catch {
                if let e = error as? OBDError, case .scanInterrupted = e {
                    await MainActor.run { isInterrupted = true }
                    return
                }
                print("Scan failed: \(error)")
                obdService.disconnect()
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    hasError = true
                }
            }
        }
    }
    
    private func startStatusAnimation() {
        Timer.scheduledTimer(withTimeInterval: statusDisplayInterval, repeats: true) { timer in
            if currentStatusIndex < statuses.count - 1 {
                currentStatusIndex += 1
            } else {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    ScanningView(onComplete: { _ in }, onStartOver: nil, obdService: OBDService())
}
