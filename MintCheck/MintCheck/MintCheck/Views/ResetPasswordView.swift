//
//  ResetPasswordView.swift
//  MintCheck
//
//  Set new password from deep link (recovery session) or show expired message
//

import SwiftUI
import Supabase

struct ResetPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    let isExpired: Bool
    let onDone: () -> Void
    let onResend: () -> Void
    
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var success = false
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }

    private var newPasswordValidationResult: PasswordValidationResult {
        PasswordValidator.validate(newPassword)
    }

    private var newPasswordValidationMessage: String? {
        guard !newPassword.isEmpty, !newPasswordValidationResult.isValid else { return nil }
        return newPasswordValidationResult.failureMessage
    }
    
    private var isFormValid: Bool {
        newPasswordValidationResult.isValid && passwordsMatch
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScreenHeader(
                title: isExpired ? "Link Expired" : "Set New Password",
                showBackButton: false,
                backAction: {}
            )
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if isExpired {
                        VStack(spacing: 16) {
                            Image(systemName: "link.badge.plus")
                                .font(.system(size: 40))
                                .foregroundColor(.textSecondary)
                            Text("This link expired. Send a new one?")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            PrimaryButton(title: "Resend", action: onResend)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else if success {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.statusSafe)
                            Text("Password updated. You can now sign in.")
                                .font(.system(size: FontSize.bodyLarge))
                                .foregroundColor(.textPrimary)
                                .multilineTextAlignment(.center)
                            PrimaryButton(title: "Sign In", action: onDone)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    } else {
                        Text("Enter a new password for your account.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                        
                        InputField(
                            label: "New password",
                            text: $newPassword,
                            placeholder: "••••••••",
                            isSecure: true,
                            errorMessage: newPasswordValidationMessage
                        )
                        if newPasswordValidationMessage == nil {
                            Text(PasswordValidator.requirementsHint)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.textSecondary)
                        }
                        InputField(
                            label: "Confirm password",
                            text: $confirmPassword,
                            placeholder: "••••••••",
                            isSecure: true,
                            errorMessage: (!confirmPassword.isEmpty && !passwordsMatch) ? "Passwords don't match" : nil
                        )
                        
                        if let error = errorMessage ?? authService.error {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(error)
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.statusDanger)
                                Button(action: {
                                    nav.feedbackSource = .error_cta
                                    nav.feedbackPrefillMessage = "Set new password failed."
                                    nav.feedbackErrorCode = ErrorEventCode.ERR_AUTH_FAIL.rawValue
                                    nav.feedbackErrorMessage = error
                                    nav.feedbackScanStep = "resetPassword"
                                    nav.showFeedbackModal = true
                                }) {
                                    Text("Report this issue")
                                        .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                        .foregroundColor(.mintGreen)
                                }
                            }
                        }
                        
                        PrimaryButton(
                            title: "Update Password",
                            action: submit,
                            isEnabled: isFormValid,
                            isLoading: isLoading
                        )
                        .padding(.top, 8)
                    }
                }
                .padding(24)
            }
        }
        .background(Color.deepBackground)
    }
    
    private func submit() {
        errorMessage = nil
        authService.error = nil
        guard isFormValid else { return }
        
        isLoading = true
        Task {
            do {
                try await SupabaseConfig.shared.client.auth.update(user: UserAttributes(password: newPassword))
                await MainActor.run {
                    success = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

#Preview("Form") {
    ResetPasswordView(isExpired: false, onDone: {}, onResend: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}

#Preview("Expired") {
    ResetPasswordView(isExpired: true, onDone: {}, onResend: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
