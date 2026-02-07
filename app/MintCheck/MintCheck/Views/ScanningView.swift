//
//  ScanningView.swift
//  MintCheck
//
//  Active scan progress screen
//

import SwiftUI

struct ScanningView: View {
    let onComplete: () -> Void
    
    @StateObject private var obdService = OBDService()
    @State private var currentStatusIndex = 0
    @State private var hasError = false
    @State private var errorMessage: String?
    
    private let statuses: [(icon: String, text: String)] = [
        ("waveform.path.ecg", "Connecting to vehicle..."),
        ("doc.text.magnifyingglass", "Reading vehicle data..."),
        ("gauge.with.dots.needle.bottom.50percent", "Checking engine health..."),
        ("drop.fill", "Analyzing fuel system..."),
        ("wind", "Checking emissions..."),
        ("thermometer", "Reviewing temperature controls..."),
        ("bolt.fill", "Finalizing scan...")
    ]
    
    var body: some View {
        VStack {
            Spacer()
            
            // Animated loader
            ZStack {
                // Background circle
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .fill(Color.white)
                    .frame(width: 80, height: 80)
                    .overlay(
                        RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                            .stroke(Color.borderColor, lineWidth: 1)
                    )
                
                // Icon
                Image(systemName: statuses[currentStatusIndex].icon)
                    .font(.system(size: 32))
                    .foregroundColor(.textPrimary)
                
                // Spinning progress ring
                Circle()
                    .trim(from: 0, to: 0.75)
                    .stroke(Color.mintGreen, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 80, height: 80)
                    .rotationEffect(.degrees(-90))
                    .rotationEffect(.degrees(obdService.scanProgress * 360))
                    .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: obdService.scanProgress)
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
                    .animation(.easeInOut, value: currentStatusIndex)
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
            startScan()
        }
        .alert("Scan Error", isPresented: $hasError) {
            Button("Try Again") {
                startScan()
            }
            Button("Cancel", role: .cancel) {
                // Go back
            }
        } message: {
            Text(errorMessage ?? "An error occurred during the scan.")
        }
    }
    
    private func startScan() {
        hasError = false
        errorMessage = nil
        
        Task {
            do {
                // Connect to device
                try await obdService.connect()
                
                // Start status animation
                startStatusAnimation()
                
                // Perform scan
                _ = try await obdService.performScan()
                
                // Complete
                await MainActor.run {
                    onComplete()
                }
            } catch {
                // For demo/testing, simulate a successful scan
                print("Device connection failed, using simulated scan: \(error)")
                startStatusAnimation()
                _ = await obdService.simulateScan()
                await MainActor.run {
                    onComplete()
                }
            }
        }
    }
    
    private func startStatusAnimation() {
        Timer.scheduledTimer(withTimeInterval: 2.5, repeats: true) { timer in
            if currentStatusIndex < statuses.count - 1 {
                withAnimation {
                    currentStatusIndex += 1
                }
            } else {
                timer.invalidate()
            }
        }
    }
}

#Preview {
    ScanningView(onComplete: {})
}
