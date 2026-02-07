//
//  SignInView.swift
//  MintCheck
//
//  Sign in and create account screen
//

import SwiftUI

struct SignInView: View {
    let onBack: () -> Void
    let onSignIn: (UserProfile, Bool) -> Void  // Bool = true for new signup, false for signin
    var startInCreateMode: Bool = false
    
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    
    @State private var isCreatingAccount: Bool
    
    init(onBack: @escaping () -> Void, onSignIn: @escaping (UserProfile, Bool) -> Void, startInCreateMode: Bool = false) {
        self.onBack = onBack
        self.onSignIn = onSignIn
        self.startInCreateMode = startInCreateMode
        self._isCreatingAccount = State(initialValue: startInCreateMode)
    }
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthdate: Date? = defaultBirthdate
    @State private var showAgeDisclaimer = false
    @State private var errorMessage: String?
    @State private var showEmailConfirmation = false
    @State private var showForgotPassword = false
    
    // Default birthdate: January 1, 1996 (OBD-II requirement date)
    private static var defaultBirthdate: Date {
        var components = DateComponents()
        components.year = 1996
        components.month = 1
        components.day = 1
        return Calendar.current.date(from: components) ?? Date()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            ScreenHeader(
                title: isCreatingAccount ? "Create Account" : "Sign In",
                showBackButton: true,
                backAction: onBack
            )
            
            // Form
            ScrollView {
                VStack(spacing: 20) {
                    if isCreatingAccount {
                        InputField(
                            label: "First Name",
                            text: $firstName,
                            placeholder: "John"
                        )
                        
                        InputField(
                            label: "Last Name",
                            text: $lastName,
                            placeholder: "Smith"
                        )
                    }
                    
                    InputField(
                        label: "Email",
                        text: $email,
                        placeholder: "john@example.com",
                        keyboardType: .emailAddress
                    )
                    
                    InputField(
                        label: "Password",
                        text: $password,
                        placeholder: "••••••••",
                        isSecure: true
                    )
                    
                    if !isCreatingAccount {
                        Button(action: { showForgotPassword = true }) {
                            Text("Forgot password?")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.mintGreen)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                    
                    if isCreatingAccount {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Birthdate")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { birthdate ?? Self.defaultBirthdate },
                                    set: { birthdate = $0 }
                                ),
                                displayedComponents: .date
                            )
                            .datePickerStyle(.compact)
                            .labelsHidden()
                            
                            if showAgeDisclaimer {
                                Text("We recommend having an adult assist with your vehicle inspection. You can continue, but please involve a parent or guardian in your decision.")
                                    .font(.system(size: FontSize.bodySmall))
                                    .foregroundColor(.statusDanger)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Email confirmation success message
                    if showEmailConfirmation {
                        VStack(spacing: 8) {
                            Image(systemName: "envelope.badge.fill")
                                .font(.system(size: 32))
                                .foregroundColor(.statusSafe)
                            
                            Text("Check your email!")
                                .font(.system(size: FontSize.h4, weight: .semibold))
                                .foregroundColor(.textPrimary)
                            
                            Text("We sent a confirmation link to \(email). Click the link to activate your account, then come back and sign in.")
                                .font(.system(size: FontSize.bodyRegular))
                                .foregroundColor(.textSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(LayoutConstants.padding4)
                        .background(Color.statusSafeBg)
                        .cornerRadius(LayoutConstants.borderRadius)
                        .overlay(
                            RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                .stroke(Color.statusSafe, lineWidth: 1)
                        )
                        .padding(.vertical, 8)
                    }
                    
                    if let error = errorMessage ?? authService.error {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(error)
                                .font(.system(size: FontSize.bodySmall))
                                .foregroundColor(.statusDanger)
                            Button(action: {
                                nav.feedbackSource = .error_cta
                                nav.feedbackPrefillMessage = "Sign in / Create account failed."
                                nav.feedbackErrorCode = ErrorEventCode.ERR_AUTH_FAIL.rawValue
                                nav.feedbackErrorMessage = error
                                nav.feedbackScanStep = "signIn"
                                nav.showFeedbackModal = true
                            }) {
                                Text("Report this issue")
                                    .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                    .foregroundColor(.mintGreen)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    
                    // Submit button (hide if showing confirmation)
                    if !showEmailConfirmation {
                        PrimaryButton(
                            title: isCreatingAccount ? "Create Account" : "Sign In",
                            action: handleSubmit,
                            isEnabled: isFormValid,
                            isLoading: authService.isLoading
                        )
                        .padding(.top, 8)
                    } else {
                        // Show sign in button after confirmation
                        PrimaryButton(
                            title: "Sign In",
                            action: {
                                withAnimation {
                                    showEmailConfirmation = false
                                    isCreatingAccount = false
                                    password = ""
                                }
                            }
                        )
                        .padding(.top, 8)
                    }
                    
                    // Toggle mode (hide when showing confirmation)
                    if !showEmailConfirmation {
                        Button(action: { 
                            withAnimation {
                                isCreatingAccount.toggle()
                                errorMessage = nil
                            }
                        }) {
                            Text(isCreatingAccount
                                ? "Already have an account? Sign in"
                                : "No account yet? Create one")
                                .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                                .foregroundColor(.textSecondary)
                        }
                        .padding(.top, 8)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
        }
        .background(Color.deepBackground)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView(onDismiss: { showForgotPassword = false })
                .environmentObject(authService)
                .environmentObject(nav)
        }
    }
    
    private var isFormValid: Bool {
        if isCreatingAccount {
            return !email.isEmpty && !password.isEmpty && !firstName.isEmpty && !lastName.isEmpty && password.count >= 6
        }
        return !email.isEmpty && !password.isEmpty
    }
    
    private func handleSubmit() {
        // Check age for new accounts
        if isCreatingAccount, let birth = birthdate {
            let age = Calendar.current.dateComponents([.year], from: birth, to: Date()).year ?? 0
            if age < 16 {
                showAgeDisclaimer = true
            }
        }
        
        Task {
            do {
                if isCreatingAccount {
                    let signUpData = SignUpData(
                        email: email,
                        password: password,
                        firstName: firstName,
                        lastName: lastName,
                        birthdate: birthdate
                    )
                    let user = try await authService.signUp(data: signUpData)
                    onSignIn(user, true)  // true = new signup
                } else {
                    let signInData = SignInData(email: email, password: password)
                    let user = try await authService.signIn(data: signInData)
                    onSignIn(user, false)  // false = existing signin
                }
            } catch let authError as AuthError where authError.isEmailConfirmation {
                // Show success message for email confirmation
                showEmailConfirmation = true
                errorMessage = nil
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignInView(onBack: {}, onSignIn: { _, _ in })
        .environmentObject(AuthService())
        .environmentObject(NavigationManager())
}
