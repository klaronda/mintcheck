//
//  VehicleBasicsView.swift
//  MintCheck
//
//  Vehicle identification with VIN-first flow
//

import SwiftUI

enum VehicleBasicsStep {
    case vinOptions
    case vinManual
    case vinScan
    case makeModel
}

struct VehicleBasicsView: View {
    let onBack: () -> Void
    let onNext: (VehicleInfo) -> Void
    
    @EnvironmentObject var nav: NavigationManager
    @State private var currentStep: VehicleBasicsStep = .vinOptions
    @State private var vinNumber = ""
    @State private var year = ""
    @State private var make = ""
    @State private var model = ""
    @State private var isDecodingVIN = false
    @State private var vinError: String?
    @State private var decodedInfo: VINDecodeResult?
    @State private var showCamera = false
    @FocusState private var isVINFieldFocused: Bool
    
    private let vinDecoder = VINDecoderService()
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(
                title: "Vehicle Information",
                showBackButton: true,
                backAction: handleBack
            )
            
            // Content based on step
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    switch currentStep {
                    case .vinOptions:
                        vinOptionsContent
                    case .vinManual:
                        vinManualContent
                    case .vinScan:
                        vinManualContent // Fallback - camera is shown via sheet
                    case .makeModel:
                        makeModelContent
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
            
            // Bottom button (only for manual VIN and make/model steps)
            if currentStep == .vinManual || currentStep == .makeModel {
                VStack {
                    PrimaryButton(
                        title: "Continue",
                        action: handleContinue,
                        isEnabled: isFormValid
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
        .background(Color.deepBackground)
        .onTapGesture {
            isVINFieldFocused = false
        }
        .sheet(isPresented: $showCamera) {
            VINCameraView(onVINScanned: { scannedVIN in
                vinNumber = scannedVIN
                showCamera = false
                // Navigate to manual entry view with scanned VIN
                currentStep = .vinManual
                // Auto-decode if valid
                if scannedVIN.isValidVIN {
                    lookupVIN()
                }
            })
        }
    }
    
    // MARK: - VIN Options Step
    
    private var vinOptionsContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Headline
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter Vehicle Identification Number")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("The fastest way to identify your vehicle is with the 17-character VIN.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            
            // VIN Location Image
            Image("vin-location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(LayoutConstants.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            // Options
            VStack(spacing: 12) {
                // Scan VIN with Camera
                VINOptionButton(
                    icon: "camera.fill",
                    title: "Scan VIN with Camera",
                    description: "Point your camera at the VIN",
                    action: {
                        showCamera = true
                    }
                )
                
                // Enter VIN Manually
                VINOptionButton(
                    icon: "keyboard",
                    title: "Enter VIN Manually",
                    description: "Type in the 17-character VIN",
                    action: { currentStep = .vinManual }
                )
                
                // Can't find VIN
                VINOptionButton(
                    icon: "questionmark.circle",
                    title: "I can't find the VIN number",
                    description: "Enter make, model, and year instead",
                    action: { currentStep = .makeModel }
                )
            }
            
            // Disclaimer
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 14))
                    .foregroundColor(.textSecondary)
                
                Text("The VIN number will tell us the exact make, model, year and trim of the car so there's no surprises later.")
                    .font(.system(size: FontSize.bodySmall))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
        }
    }
    
    // MARK: - VIN Manual Entry Step
    
    private var vinManualContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Headline
            VStack(alignment: .leading, spacing: 8) {
                Text("Enter VIN")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("The VIN is typically found on the driver's side dashboard (visible through windshield) or on the driver's door jamb.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .lineSpacing(4)
            }
            
            // VIN Location Image
            Image("vin-location")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(maxWidth: .infinity)
                .cornerRadius(LayoutConstants.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .stroke(Color.borderColor, lineWidth: 1)
                )
            
            // VIN Input
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("Vehicle Identification Number")
                        .font(.system(size: FontSize.bodyRegular, weight: .medium))
                        .foregroundColor(.textPrimary)
                    
                    Text("*")
                        .foregroundColor(.statusDanger)
                }
                
                HStack {
                    TextField("1HGBH41JXMN109186", text: $vinNumber)
                        .font(.system(size: FontSize.bodyLarge).monospaced())
                        .foregroundColor(.textPrimary)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                        .focused($isVINFieldFocused)
                        .onChange(of: vinNumber) { _, newValue in
                            let cleaned = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                            if cleaned.count <= 17 {
                                vinNumber = cleaned
                            }
                            vinError = nil
                            decodedInfo = nil
                        }
                    
                    if isDecodingVIN {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                .padding(.horizontal, LayoutConstants.padding3)
                .frame(height: 44)
                .background(Color.white)
                .cornerRadius(LayoutConstants.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .stroke(vinError != nil ? Color.statusDanger : (decodedInfo != nil ? Color.statusSafe : Color.borderColor), lineWidth: 1)
                )
                
                HStack {
                    Text("\(vinNumber.count)/17 characters")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    if vinNumber.count == 17 && decodedInfo == nil && !isDecodingVIN {
                        Button("Lookup VIN") {
                            lookupVIN()
                        }
                        .font(.system(size: FontSize.bodySmall, weight: .semibold))
                        .foregroundColor(.mintGreen)
                    }
                }
                
                if let error = vinError {
                    Text(error)
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.statusDanger)
                }
            }
            
            // Decoded Vehicle Info Card
            if let decoded = decodedInfo {
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
        }
    }
    
    private func lookupVIN() {
        guard vinNumber.isValidVIN else {
            vinError = "Invalid VIN format"
            return
        }
        
        isDecodingVIN = true
        vinError = nil
        
        Task {
            do {
                let result = try await vinDecoder.decodeVIN(vinNumber)
                await MainActor.run {
                    decodedInfo = result
                    isDecodingVIN = false
                }
            } catch {
                await MainActor.run {
                    vinError = "Could not decode VIN. You can still continue."
                    isDecodingVIN = false
                }
            }
        }
    }
    
    // MARK: - Make/Model Step
    
    private var makeModelContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            // Headline
            VStack(alignment: .leading, spacing: 8) {
                Text("Vehicle Details")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("Tell us the make and model of the vehicle you're checking. Year is optional.")
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
                            model = "" // Reset model when make changes
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
        }
    }
    
    // MARK: - Helpers
    
    private var isFormValid: Bool {
        switch currentStep {
        case .vinOptions:
            return false
        case .vinManual, .vinScan:
            return vinNumber.count == 17
        case .makeModel:
            // Year is optional, only make and model are required
            return !make.isEmpty && !model.isEmpty
        }
    }
    
    private func handleBack() {
        switch currentStep {
        case .vinOptions:
            onBack()
        case .vinManual, .vinScan, .makeModel:
            currentStep = .vinOptions
        }
    }
    
    private func handleContinue() {
        switch currentStep {
        case .vinManual, .vinScan:
            // Decode VIN and proceed
            decodeVINAndProceed()
        case .makeModel:
            // Create vehicle info from manual entry
            // Use "(Year N/A)" if year is not provided
            var vehicleInfo = VehicleInfo(
                year: year.isEmpty ? "(Year N/A)" : year,
                make: make,
                model: model
            )
            vehicleInfo.vin = vinNumber.isEmpty ? nil : vinNumber
            onNext(vehicleInfo)
        case .vinOptions:
            break
        }
    }
    
    private func decodeVINAndProceed() {
        guard vinNumber.isValidVIN else {
            vinError = "Invalid VIN format"
            return
        }
        
        // If we already have decoded info, check if make and model are valid
        if let decoded = decodedInfo {
            // If make or model are missing/Unknown, redirect to manual entry
            let decodedMake = decoded.make ?? ""
            let decodedModel = decoded.model ?? ""
            
            if decodedMake.isEmpty || decodedMake == "Unknown" || 
               decodedModel.isEmpty || decodedModel == "Unknown" {
                // Pre-populate with any data we have and go to manual entry
                if !decodedMake.isEmpty && decodedMake != "Unknown" {
                    make = decodedMake
                }
                if !decodedModel.isEmpty && decodedModel != "Unknown" {
                    model = decodedModel
                }
                if let decodedYear = decoded.year, !decodedYear.isEmpty && decodedYear != "Unknown" {
                    year = decodedYear
                }
                vinError = "Could not identify vehicle. Please enter details manually."
                currentStep = .makeModel
                return
            }
            
            // Make and model are valid, proceed
            var vehicleInfo = VehicleInfo(
                year: decoded.year ?? "(Year N/A)",
                make: decodedMake,
                model: decodedModel
            )
            vehicleInfo.vin = vinNumber
            vehicleInfo.trim = decoded.trim
            vehicleInfo.fuelType = decoded.fuelType
            vehicleInfo.engine = decoded.engineDescription
            vehicleInfo.transmission = decoded.transmission
            vehicleInfo.drivetrain = decoded.driveType
            onNext(vehicleInfo)
            return
        }
        
        // Otherwise decode first
        isDecodingVIN = true
        vinError = nil
        
        Task {
            do {
                let result = try await vinDecoder.decodeVIN(vinNumber)
                await MainActor.run {
                    decodedInfo = result
                    isDecodingVIN = false
                    
                    let decodedMake = result.make ?? ""
                    let decodedModel = result.model ?? ""
                    
                    // If make or model are missing/Unknown, redirect to manual entry
                    if decodedMake.isEmpty || decodedMake == "Unknown" || 
                       decodedModel.isEmpty || decodedModel == "Unknown" {
                        // Pre-populate with any data we have
                        if !decodedMake.isEmpty && decodedMake != "Unknown" {
                            make = decodedMake
                        }
                        if !decodedModel.isEmpty && decodedModel != "Unknown" {
                            model = decodedModel
                        }
                        if let decodedYear = result.year, !decodedYear.isEmpty && decodedYear != "Unknown" {
                            year = decodedYear
                        }
                        vinError = "Could not identify vehicle. Please enter details manually."
                        currentStep = .makeModel
                        return
                    }
                    
                    // Make and model are valid, proceed
                    var vehicleInfo = VehicleInfo(
                        year: result.year ?? "(Year N/A)",
                        make: decodedMake,
                        model: decodedModel
                    )
                    vehicleInfo.vin = vinNumber
                    vehicleInfo.trim = result.trim
                    vehicleInfo.fuelType = result.fuelType
                    vehicleInfo.engine = result.engineDescription
                    vehicleInfo.transmission = result.transmission
                    vehicleInfo.drivetrain = result.driveType
                    
                    onNext(vehicleInfo)
                }
            } catch {
                await MainActor.run {
                    // Decode failed - redirect to manual entry
                    isDecodingVIN = false
                    vinError = "Could not decode VIN. Please enter vehicle details manually."
                    currentStep = .makeModel
                }
            }
        }
    }
}

// MARK: - VIN Option Button

struct VINOptionButton: View {
    let icon: String
    let title: String
    let description: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .fill(Color.deepBackground)
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.textPrimary)
                }
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                }
                
                Spacer()
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
}

// MARK: - Decoded Info Row

struct DecodedInfoRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                .foregroundColor(.textPrimary)
        }
    }
}

#Preview {
    VehicleBasicsView(onBack: {}, onNext: { _ in })
        .environmentObject(NavigationManager())
}
