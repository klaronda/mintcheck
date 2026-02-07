//
//  SelectionButton.swift
//  MintCheck
//
//  Selection buttons for forms (single/multi select)
//

import SwiftUI

struct SelectionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                .foregroundColor(isSelected ? .white : .textPrimary)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(isSelected ? Color.mintGreen : Color.white)
                .cornerRadius(LayoutConstants.borderRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .stroke(isSelected ? Color.mintGreen : Color.borderColor, lineWidth: 1)
                )
        }
    }
}

// MARK: - Icon Selection Button (for warning lights)
struct IconSelectionButton: View {
    let icon: String
    let label: String
    let isSelected: Bool
    var iconSize: CGFloat = 32
    let action: () -> Void
    
    // Icon color: #1A1A1A when not selected, white when selected
    private var iconColor: Color {
        isSelected ? .white : Color(red: 0.1, green: 0.1, blue: 0.1)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(icon)
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: iconSize, height: iconSize)
                    .foregroundColor(iconColor)
                
                Text(label)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 90)
            .background(isSelected ? Color.mintGreen : Color.white)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(isSelected ? Color.mintGreen : Color.borderColor, lineWidth: 1)
            )
        }
    }
}

// MARK: - Option Card (for device type selection)
struct OptionCard: View {
    let icon: String
    let title: String
    let description: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                        .fill(isSelected ? Color.mintGreen : Color.deepBackground)
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(isSelected ? .white : .textSecondary)
                }
                
                // Text
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                        .foregroundColor(.textPrimary)
                    
                    Text(description)
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                Spacer()
            }
            .padding(LayoutConstants.padding4)
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(isSelected ? Color.mintGreen : Color.borderColor, lineWidth: 2)
            )
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            SelectionButton(title: "Good", isSelected: true, action: {})
            SelectionButton(title: "Worn", isSelected: false, action: {})
            SelectionButton(title: "Poor", isSelected: false, action: {})
        }
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 3), spacing: 12) {
            IconSelectionButton(icon: "icon-oil", label: "Oil", isSelected: true, action: {})
            IconSelectionButton(icon: "icon-check-engine", label: "Check Engine", isSelected: false, action: {})
            IconSelectionButton(icon: "icon-tire-pressure", label: "Tire Pressure", isSelected: false, action: {})
        }
        
        OptionCard(
            icon: "wifi",
            title: "Wi-Fi Scanner",
            description: "Recommended. Connect to the scanner's Wi-Fi network.",
            isSelected: true,
            action: {}
        )
        
        OptionCard(
            icon: "antenna.radiowaves.left.and.right",
            title: "Bluetooth Scanner",
            description: "Pair with your scanner via Bluetooth settings.",
            isSelected: false,
            action: {}
        )
    }
    .padding()
    .background(Color.deepBackground)
}
