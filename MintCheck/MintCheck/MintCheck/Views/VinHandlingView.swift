//
//  VinHandlingView.swift
//  MintCheck
//
//  VIN confirmation/editing screen after detection
//

import SwiftUI

struct VinHandlingView: View {
    let onNext: (String?) -> Void
    let detectedVIN: String?
    let vehicleInfo: VehicleInfo
    
    @State private var vin: String
    @State private var showSkipWarning = false
    @FocusState private var isVINFieldFocused: Bool
    
    init(onNext: @escaping (String?) -> Void, detectedVIN: String?, vehicleInfo: VehicleInfo) {
        self.onNext = onNext
        self.detectedVIN = detectedVIN
        self.vehicleInfo = vehicleInfo
        self._vin = State(initialValue: detectedVIN ?? "")
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(
                title: "Vehicle Identification",
                showBackButton: false
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // VIN Detected card (only if we have a detected VIN)
                    if detectedVIN != nil {
                        VINDetectedCard()
                    } else {
                        Text("We couldn't detect the VIN automatically. You can enter it manually to help us validate the scan results.")
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                    
                    // Where to find VIN info
                    VINInfoCard()
                    
                    // VIN Input
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vehicle Identification Number (VIN)")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        TextField("1HGBH41JXMN109186", text: $vin)
                            .font(.system(size: FontSize.bodyLarge).monospaced())
                            .foregroundColor(.textPrimary)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .focused($isVINFieldFocused)
                            .onChange(of: vin) { _, newValue in
                                let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                if cleaned.count <= 17 {
                                    vin = cleaned
                                }
                                showSkipWarning = false
                            }
                            .padding(.horizontal, LayoutConstants.padding3)
                            .frame(height: 44)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                        
                        Text("Expected vehicle: \(vehicleInfo.make) \(vehicleInfo.model)\(vehicleInfo.year.isEmpty ? "" : " (\(vehicleInfo.year))")")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                    }
                    
                    // Skip warning
                    if showSkipWarning {
                        SkipWarningCard()
                    }
                    
                    // Buttons
                    VStack(spacing: 10) {
                        PrimaryButton(
                            title: "Continue",
                            action: handleContinue
                        )
                        
                        Button(action: {
                            if !vin.isEmpty {
                                handleContinue()
                            } else if showSkipWarning {
                                handleSkip()
                            } else {
                                showSkipWarning = true
                            }
                        }) {
                            Text(showSkipWarning ? "Continue Without VIN" : "Skip VIN Entry")
                                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        }
                        .frame(height: 48)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 48)
            }
        }
        .background(Color.deepBackground)
        .onTapGesture {
            isVINFieldFocused = false
        }
    }
    
    private func handleContinue() {
        if vin.trimmingCharacters(in: .whitespaces).isEmpty {
            showSkipWarning = true
        } else {
            onNext(vin.trimmingCharacters(in: .whitespaces))
        }
    }
    
    private func handleSkip() {
        onNext(nil)
    }
}

// MARK: - VIN Detected Card

struct VINDetectedCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .fill(Color.statusSafe)
                    .frame(width: 36, height: 36)
                
                Image(systemName: "checkmark.rectangle.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("VIN Detected")
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("We found the vehicle identification number. You can confirm or edit it below.")
                    .font(.system(size: FontSize.bodyRegular))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
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

// MARK: - VIN Info Card

struct VINInfoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Where to find the VIN:")
                .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            VStack(alignment: .leading, spacing: 4) {
                BulletText(text: "Driver's side dashboard (visible through windshield)")
                BulletText(text: "Driver's side door jamb sticker")
                BulletText(text: "Vehicle registration or insurance card")
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

struct BulletText: View {
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\u{2022}")
                .foregroundColor(.textSecondary)
            
            Text(text)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
        }
    }
}

// MARK: - Skip Warning Card

struct SkipWarningCard: View {
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.statusWarning)
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Lower Confidence Results")
                    .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Without the VIN, we can't fully validate the vehicle information. Results will be marked with lower confidence.")
                    .font(.system(size: FontSize.bodyRegular))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
        }
        .padding(LayoutConstants.padding4)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.statusWarning, lineWidth: 2)
        )
    }
}

#Preview {
    VinHandlingView(
        onNext: { _ in },
        detectedVIN: "1HGBH41JXMN109186",
        vehicleInfo: VehicleInfo(year: "2018", make: "Honda", model: "Accord")
    )
}
