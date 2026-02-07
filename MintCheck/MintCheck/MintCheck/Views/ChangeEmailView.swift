//
//  ChangeEmailView.swift
//  MintCheck
//
//  Change email flow: new email + current password (reauth), then request confirmation
//

import SwiftUI

struct ChangeEmailView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    let onDismiss: () -> Void
    
    @State private var newEmail = ""
    @State private var currentPassword = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var successMessage: String?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("We'll email you a link to confirm your new address.")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                    
                    InputField(
                        label: "New email",
                        text: $newEmail,
                        placeholder: "new@example.com",
                        keyboardType: .emailAddress
                    )
                    
                    InputField(
                        label: "Current password",
                        text: $currentPassword,
                        placeholder: "••••••••",
                        isSecure: true
                    )
                    
                    if let error = errorMessage ?? authService.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.statusDanger)
                            Button(action: {
                                nav.feedbackSource = .error_cta
                                nav.feedbackPrefillMessage = "Change email failed."
                                nav.feedbackErrorCode = ErrorEventCode.ERR_AUTH_FAIL.rawValue
                                nav.feedbackErrorMessage = error
                                nav.feedbackScanStep = "changeEmail"
                                nav.showFeedbackModal = true
                            }) {
                                Text("Report this issue")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.mintGreen)
                            }
                        }
                    }
                    
                    if let success = successMessage {
                        Text(success)
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.statusSafe)
                    }
                    
                    PrimaryButton(
                        title: "Send confirmation email",
                        action: submit,
                        isEnabled: isFormValid,
                        isLoading: isLoading
                    )
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle("Change Email")
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
    }
    
    private var isFormValid: Bool {
        !newEmail.isEmpty && !currentPassword.isEmpty
    }
    
    private func submit() {
        errorMessage = nil
        authService.error = nil
        guard isFormValid else { return }
        
        isLoading = true
        Task {
            do {
                try await authService.requestEmailChange(newEmail: newEmail, currentPassword: currentPassword)
                await MainActor.run {
                    successMessage = "Check your new email for a confirmation link."
                    isLoading = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        onDismiss()
                    }
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
    ChangeEmailView(onDismiss: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
