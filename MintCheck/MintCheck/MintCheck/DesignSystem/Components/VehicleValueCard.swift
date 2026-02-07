//
//  VehicleValueCard.swift
//  MintCheck
//
//  Market value check card with Cars.com deep link
//

import SwiftUI

/// Simplified card for checking market value on Cars.com
struct MarketValueCard: View {
    let vehicleYear: String
    let vehicleMake: String
    let vehicleModel: String
    let askingPrice: Int?
    let carsComURL: URL?
    let onCheckCarsCom: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            Text("Market Value")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            // Asking price if provided
            if let asking = askingPrice, asking > 0 {
                HStack {
                    Text("Asking Price:")
                        .font(.system(size: FontSize.bodyLarge))
                        .foregroundColor(.textSecondary)
                    
                    Spacer()
                    
                    Text(formatCurrency(asking))
                        .font(.system(size: FontSize.h3, weight: .bold))
                        .foregroundColor(.textPrimary)
                }
            }
            
            // Description
            Text("Check current market prices for this \(vehicleYear) \(vehicleMake) \(vehicleModel) on Cars.com")
                .font(.system(size: FontSize.bodyRegular))
                .foregroundColor(.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
            
            // CTA Button
            Button(action: onCheckCarsCom) {
                HStack(spacing: 8) {
                    Text("Check Price on Cars.com")
                        .font(.system(size: FontSize.bodyRegular, weight: .semibold))
                    Image(systemName: "arrow.up.right")
                        .font(.system(size: 14))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.mintGreen)
                .cornerRadius(LayoutConstants.borderRadius)
            }
            
            // Compact disclaimer
            Text("Prices vary by trim, mileage, condition, and region.")
                .font(.system(size: FontSize.bodySmall))
                .foregroundColor(.textMuted)
        }
        .padding(LayoutConstants.padding6)
        .background(Color.white)
        .cornerRadius(LayoutConstants.borderRadius)
        .overlay(
            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                .stroke(Color.borderColor, lineWidth: 1)
        )
    }
    
    private func formatCurrency(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.maximumFractionDigits = 0
        return formatter.string(from: NSNumber(value: value)) ?? "$\(value)"
    }
}

// MARK: - Preview

#Preview {
    MarketValueCard(
        vehicleYear: "2020",
        vehicleMake: "Subaru",
        vehicleModel: "Outback",
        askingPrice: 4500,
        carsComURL: URL(string: "https://www.cars.com/research/subaru-outback-2020/"),
        onCheckCarsCom: {}
    )
    .padding()
    .background(Color.deepBackground)
}
