//
//  QuickHumanCheckView.swift
//  MintCheck
//
//  Quick visual inspection questions
//

import SwiftUI

struct QuickHumanCheckView: View {
    let onComplete: (QuickCheckData) -> Void
    
    @State private var interiorCondition = ""
    @State private var tireCondition = ""
    @State private var dashboardLights: Bool?
    @State private var selectedWarningLights: Set<WarningLightType> = []
    @State private var engineSounds: Bool?
    @State private var odometerReading = ""
    @State private var askingPrice = ""
    @FocusState private var focusedField: Field?
    
    private enum Field {
        case odometer, askingPrice
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(
                title: "Quick Check",
                showBackButton: false
            )
            
            // Content
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    // Car interior illustration at top
                    Image("car-interior")
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .cornerRadius(LayoutConstants.borderRadius)
                    
                    Text("Answer a few quick questions about the vehicle's current condition.")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                    
                    // Interior condition
                    QuestionSection(title: "How would you rate the interior condition?") {
                        HStack(spacing: 8) {
                            ForEach(["Good", "Worn", "Poor"], id: \.self) { option in
                                SelectionButton(
                                    title: option,
                                    isSelected: interiorCondition == option,
                                    action: { interiorCondition = option }
                                )
                            }
                        }
                    }
                    
                    // Tire condition
                    QuestionSection(title: "What is the tire tread condition?") {
                        HStack(spacing: 8) {
                            ForEach(["Good", "Worn", "Bare"], id: \.self) { option in
                                SelectionButton(
                                    title: option,
                                    isSelected: tireCondition == option,
                                    action: { tireCondition = option }
                                )
                            }
                        }
                    }
                    
                    // Odometer reading
                    QuestionSection(title: "What is the odometer reading?") {
                        HStack(spacing: 8) {
                            TextField("e.g., 45000", text: $odometerReading)
                                .keyboardType(.numberPad)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(LayoutConstants.borderRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                )
                                .focused($focusedField, equals: .odometer)
                            
                            Text("miles")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                        }
                    }
                    
                    // Asking price (optional)
                    QuestionSection(title: "What is the asking price? (optional)") {
                        HStack(spacing: 8) {
                            Text("$")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textSecondary)
                            
                            TextField("e.g., 18500", text: $askingPrice)
                                .keyboardType(.numberPad)
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 12)
                                .background(Color.white)
                                .cornerRadius(LayoutConstants.borderRadius)
                                .overlay(
                                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                        .stroke(Color.borderColor, lineWidth: 1)
                                )
                                .focused($focusedField, equals: .askingPrice)
                        }
                    }
                    
                    // Dashboard lights
                    QuestionSection(title: "Any warning lights on the dashboard?") {
                        HStack(spacing: 8) {
                            SelectionButton(
                                title: "Yes",
                                isSelected: dashboardLights == true,
                                action: { dashboardLights = true }
                            )
                            SelectionButton(
                                title: "No",
                                isSelected: dashboardLights == false,
                                action: { 
                                    dashboardLights = false
                                    selectedWarningLights.removeAll()
                                }
                            )
                        }
                    }
                    
                    // Warning light types (conditional)
                    if dashboardLights == true {
                        QuestionSection(title: "Which warning lights are on?") {
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
                                ForEach(WarningLightType.allCases) { light in
                                    IconSelectionButton(
                                        icon: light.iconName,
                                        label: light.label,
                                        isSelected: selectedWarningLights.contains(light),
                                        iconSize: light.iconSize,
                                        action: {
                                            if selectedWarningLights.contains(light) {
                                                selectedWarningLights.remove(light)
                                            } else {
                                                selectedWarningLights.insert(light)
                                            }
                                        }
                                    )
                                }
                            }
                        }
                    }
                    
                    // Engine sounds
                    QuestionSection(title: "Any unusual engine sounds or vibrations?") {
                        HStack(spacing: 8) {
                            SelectionButton(
                                title: "Yes",
                                isSelected: engineSounds == true,
                                action: { engineSounds = true }
                            )
                            SelectionButton(
                                title: "No / Not Sure",
                                isSelected: engineSounds == false,
                                action: { engineSounds = false }
                            )
                        }
                    }
                    
                    // Disclaimer
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 14))
                            .foregroundColor(.textSecondary)
                        
                        Text("These details help refine the value, but the vehicle data is what matters most.")
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.textSecondary)
                            .lineSpacing(4)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)
                .padding(.bottom, 140)
            }
            
            // Sticky bottom
            VStack(spacing: 12) {
                PrimaryButton(
                    title: "Continue",
                    action: handleSubmit,
                    isEnabled: isFormComplete
                )
                
                TextButton(title: "Skip this step", action: handleSkip)
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
        .onTapGesture {
            focusedField = nil
        }
    }
    
    private var isFormComplete: Bool {
        // Only need ONE answer to continue (not all required)
        let hasInterior = !interiorCondition.isEmpty
        let hasTires = !tireCondition.isEmpty
        let hasDashboardLights = dashboardLights != nil
        let hasEngineSounds = engineSounds != nil
        let hasOdometer = !odometerReading.isEmpty
        let hasAskingPrice = !askingPrice.isEmpty
        
        // At least one question answered
        return hasInterior || hasTires || hasDashboardLights || hasEngineSounds || hasOdometer || hasAskingPrice
    }
    
    private func handleSubmit() {
        let data = QuickCheckData(
            interiorCondition: interiorCondition,
            tireCondition: tireCondition,
            dashboardLights: dashboardLights ?? false,
            warningLightTypes: Array(selectedWarningLights),
            engineSounds: engineSounds ?? false,
            odometerReading: Int(odometerReading),
            askingPrice: Int(askingPrice)
        )
        onComplete(data)
    }
    
    private func handleSkip() {
        let data = QuickCheckData(
            interiorCondition: "",
            tireCondition: "",
            dashboardLights: false,
            warningLightTypes: [],
            engineSounds: false,
            odometerReading: nil,
            askingPrice: nil
        )
        onComplete(data)
    }
}

// MARK: - Question Section
struct QuestionSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            content
        }
    }
}

#Preview {
    QuickHumanCheckView(onComplete: { _ in })
}
