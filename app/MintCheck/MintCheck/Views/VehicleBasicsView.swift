//
//  VehicleBasicsView.swift
//  MintCheck
//
//  Vehicle details input form
//

import SwiftUI

struct VehicleBasicsView: View {
    let onBack: () -> Void
    let onNext: (VehicleInfo) -> Void
    
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var vin = ""
    @State private var isDecodingVIN = false
    @State private var vinError: String?
    @State private var decodedInfo: VINDecodeResult?
    
    private let vinDecoder = VINDecoderService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            ProgressHeader(
                title: "Vehicle Details",
                step: 1,
                totalSteps: 3,
                backAction: onBack
            )
            
            // Form
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Year picker
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Year")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        
                        Menu {
                            ForEach(VehicleYears.years, id: \.self) { y in
                                Button(y) {
                                    year = y
                                }
                            }
                        } label: {
                            HStack {
                                Text(year.isEmpty ? "Select year" : year)
                                    .foregroundColor(year.isEmpty ? .textMuted : .textPrimary)
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
                    
                    // Make
                    InputField(
                        label: "Make",
                        text: $make,
                        placeholder: "e.g., Honda, Toyota"
                    )
                    
                    // Model
                    InputField(
                        label: "Model",
                        text: $model,
                        placeholder: "e.g., Accord, Camry"
                    )
                    
                    // VIN (optional)
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("VIN")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            Text("(optional)")
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textMuted)
                        }
                        
                        HStack {
                            TextField("17-character VIN", text: $vin)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .textInputAutocapitalization(.characters)
                                .autocorrectionDisabled()
                                .onChange(of: vin) { _, newValue in
                                    // Auto-uppercase and limit to 17 chars
                                    let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                    if cleaned.count <= 17 {
                                        vin = cleaned
                                    }
                                    
                                    // Clear any previous decode
                                    if cleaned.count < 17 {
                                        decodedInfo = nil
                                        vinError = nil
                                    }
                                }
                            
                            if isDecodingVIN {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else if vin.count == 17 {
                                Button(action: decodeVIN) {
                                    Text("Decode")
                                        .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                        .foregroundColor(.mintGreen)
                                }
                            }
                        }
                        .padding(.horizontal, LayoutConstants.padding3)
                        .frame(height: 44)
                        .background(Color.white)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(vinError != nil ? Color.statusDanger : Color.borderColor, lineWidth: 1)
                        )
                        
                        if let error = vinError {
                            Text(error)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.statusDanger)
                        } else if let decoded = decodedInfo {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.statusSafe)
                                Text("VIN decoded: \(decoded.year ?? "") \(decoded.make ?? "") \(decoded.model ?? "")")
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.statusSafe)
                            }
                        }
                    }
                    
                    // VIN info card
                    InfoCard(
                        text: "The VIN helps us decode exact trim, engine, and specs. You can skip this and enter details manually.",
                        icon: "lightbulb.fill"
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            
            // Sticky bottom
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Continue",
                    action: handleContinue,
                    isEnabled: isFormValid
                )
                
                TextButton(title: "Back", action: onBack)
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
    
    private var isFormValid: Bool {
        !year.isEmpty && make.count >= 2 && model.count >= 2
    }
    
    private func decodeVIN() {
        guard vin.isValidVIN else {
            vinError = "Invalid VIN format"
            return
        }
        
        isDecodingVIN = true
        vinError = nil
        
        Task {
            do {
                let result = try await vinDecoder.decodeVIN(vin)
                await MainActor.run {
                    decodedInfo = result
                    
                    // Auto-fill fields if empty
                    if year.isEmpty, let y = result.year { year = y }
                    if make.isEmpty, let m = result.make { make = m }
                    if model.isEmpty, let m = result.model { model = m }
                    
                    isDecodingVIN = false
                }
            } catch {
                await MainActor.run {
                    vinError = "Could not decode VIN"
                    isDecodingVIN = false
                }
            }
        }
    }
    
    private func handleContinue() {
        var vehicleInfo = VehicleInfo(
            year: year,
            make: make,
            model: model
        )
        
        if !vin.isEmpty && vin.isValidVIN {
            vehicleInfo.vin = vin
        }
        
        // Add decoded info if available
        if let decoded = decodedInfo {
            vehicleInfo.trim = decoded.trim
            vehicleInfo.fuelType = decoded.fuelType
            vehicleInfo.engine = decoded.engineDescription
            vehicleInfo.transmission = decoded.transmission
            vehicleInfo.drivetrain = decoded.driveType
        }
        
        onNext(vehicleInfo)
    }
}

#Preview {
    VehicleBasicsView(onBack: {}, onNext: { _ in })
}
