//
//  ForgotPasswordView.swift
//  MintCheck
//
//  Request password reset email (no auth required)
//

import SwiftUI

struct ForgotPasswordView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    let onDismiss: () -> Void
    
    @State private var email = ""
    @State private var errorMessage: String?
    @State private var isLoading = false
    @State private var didSubmit = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    InputField(
                        label: "Email",
                        text: $email,
                        placeholder: "john@example.com",
                        keyboardType: .emailAddress
                    )
                    
                    if didSubmit {
                        Text("If an account exists, we sent a link.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                    }
                    
                    if let error = errorMessage ?? authService.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.statusDanger)
                            Button(action: {
                                nav.feedbackSource = .error_cta
                                nav.feedbackPrefillMessage = "Forgot password / Send reset link failed."
                                nav.feedbackErrorCode = ErrorEventCode.ERR_AUTH_FAIL.rawValue
                                nav.feedbackErrorMessage = error
                                nav.feedbackScanStep = "forgotPassword"
                                nav.showFeedbackModal = true
                            }) {
                                Text("Report this issue")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.mintGreen)
                            }
                        }
                    }
                    
                    PrimaryButton(
                        title: "Send reset link",
                        action: submit,
                        isEnabled: !email.isEmpty,
                        isLoading: isLoading
                    )
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle("Forgot Password")
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
            email = authService.currentUser?.email ?? ""
        }
    }
    
    private func submit() {
        errorMessage = nil
        authService.error = nil
        guard !email.isEmpty else { return }
        
        isLoading = true
        Task {
            do {
                try await authService.requestPasswordReset(email: email)
                await MainActor.run {
                    didSubmit = true
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

#Preview {
    ForgotPasswordView(onDismiss: {})
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
