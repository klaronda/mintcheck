//
//  DisconnectReconnectView.swift
//  MintCheck
//
//  Prompt to disconnect OBD device after scan
//

import SwiftUI

struct DisconnectReconnectView: View {
    let onComplete: () -> Void
    
    var body: some View {
        VStack {
            Spacer()
            
            // Success icon
            ZStack {
                Circle()
                    .fill(Color.statusSafeBg)
                    .frame(width: 80, height: 80)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.statusSafe)
            }
            .padding(.bottom, 24)
            
            // Message
            VStack(spacing: 12) {
                Text("Scan Complete!")
                    .font(.system(size: FontSize.h2, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                Text("You can now unplug the scanner from your vehicle.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Spacer()
            
            // Instructions
            VStack(alignment: .leading, spacing: 16) {
                Text("Before continuing:")
                    .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                    .foregroundColor(.textPrimary)
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "1.circle.fill")
                        .foregroundColor(.mintGreen)
                    Text("Remove the OBD-II scanner from the vehicle’s port")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                }
                
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "2.circle.fill")
                        .foregroundColor(.mintGreen)
                    Text("Disconnect from the scanner’s Wi-Fi network")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                }
            }
            .padding(LayoutConstants.padding4)
            .background(Color.softBackground)
            .cornerRadius(LayoutConstants.borderRadius)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            
            // Continue button
            PrimaryButton(
                title: "Continue",
                action: onComplete
            )
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
        .background(Color.deepBackground)
    }
}

#Preview {
    DisconnectReconnectView(onComplete: {})
}
