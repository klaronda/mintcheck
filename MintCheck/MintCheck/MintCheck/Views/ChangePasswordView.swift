//
//  ChangePasswordView.swift
//  MintCheck
//
//  Change password: current password (reauth) + new + confirm
//

import SwiftUI

struct ChangePasswordView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    let onDismiss: () -> Void
    
    @State private var currentPassword = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var showForgotPassword = false
    
    private var passwordsMatch: Bool {
        !newPassword.isEmpty && newPassword == confirmPassword
    }
    
    private var isFormValid: Bool {
        !currentPassword.isEmpty && newPassword.count >= 6 && passwordsMatch
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InputField(
                        label: "Current password",
                        text: $currentPassword,
                        placeholder: "••••••••",
                        isSecure: true
                    )
                    
                    InputField(
                        label: "New password",
                        text: $newPassword,
                        placeholder: "••••••••",
                        isSecure: true
                    )
                    
                    InputField(
                        label: "Confirm new password",
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
                                nav.feedbackPrefillMessage = "Change password failed."
                                nav.feedbackErrorCode = ErrorEventCode.ERR_AUTH_FAIL.rawValue
                                nav.feedbackErrorMessage = error
                                nav.feedbackScanStep = "changePassword"
                                nav.showFeedbackModal = true
                            }) {
                                Text("Report this issue")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.mintGreen)
                            }
                        }
                    }
                    
                    PrimaryButton(
                        title: "Update password",
                        action: submit,
                        isEnabled: isFormValid,
                        isLoading: isLoading
                    )
                    .padding(.top, 8)
                    
                    Button(action: { showForgotPassword = true }) {
                        Text("Reset password / Forgot password?")
                            .font(.system(size: FontSize.bodySmall, weight: .semibold))
                            .foregroundColor(.mintGreen)
                    }
                    .buttonStyle(.plain)
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle("Change Password")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                    .foregroundColor(.mintGreen)
                }
            }
        }
        .onAppear {
            authService.error = nil
        }
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(onDismiss: { showForgotPassword = false })
                .environmentObject(authService)
                .environmentObject(nav)
        }
    }
    
    private func submit() {
        errorMessage = nil
        authService.error = nil
        guard isFormValid else { return }
        
        isLoading = true
        Task {
            do {
                try await authService.updatePassword(current: currentPassword, new: newPassword)
                await MainActor.run {
                    isLoading = false
                    onDismiss()
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

#Preview {
    ChangePasswordView(onDismiss: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
