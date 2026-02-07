//
//  EmailConfirmationView.swift
//  MintCheck
//
//  Shown when deep link confirms email (signup or email change)
//

import SwiftUI

struct EmailConfirmationView: View {
    @EnvironmentObject var authService: AuthService
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: "Email Confirmed",
                showBackButton: false,
                backAction: {}
            )
            
            VStack(spacing: 24) {
                Spacer()
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 56))
                    .foregroundColor(.statusSafe)
                
                Text("Email confirmed! You can now use all MintCheck features.")
                    .font(.system(size: FontSize.bodyLarge))
                    .foregroundColor(.textPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                
                PrimaryButton(title: "Continue to Dashboard", action: onContinue)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                
                Spacer()
            }
        }
        .background(Color.deepBackground)
    }
}

#Preview {
    EmailConfirmationView(onContinue: {})
        .environmentObject(AuthService())
}
