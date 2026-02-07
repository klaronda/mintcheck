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
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : .textPrimary)
                
                Text(label)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
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
                }
                
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
        
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
            IconSelectionButton(icon: "drop.fill", label: "Oil", isSelected: true, action: {})
            IconSelectionButton(icon: "exclamationmark.triangle.fill", label: "Check Engine", isSelected: false, action: {})
            IconSelectionButton(icon: "wind", label: "Tire Pressure", isSelected: false, action: {})
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
