//
//  SignInView.swift
//  MintCheck
//
//  Sign in and create account screen
//

import SwiftUI

struct SignInView: View {
    let onBack: () -> Void
    let onSignIn: (UserProfile) -> Void
    
    @EnvironmentObject var authService: AuthService
    
    @State private var isCreatingAccount = false
    @State private var email = ""
    @State private var password = ""
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var birthdate: Date?
    @State private var showAgeDisclaimer = false
    @State private var errorMessage: String?
    
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
                    
                    if isCreatingAccount {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Birthdate")
                                .font(.system(size: FontSize.bodyRegular, weight: .medium))
                                .foregroundColor(.textPrimary)
                            
                            DatePicker(
                                "",
                                selection: Binding(
                                    get: { birthdate ?? Date() },
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
                    
                    if let error = errorMessage ?? authService.error {
                        Text(error)
                            .font(.system(size: FontSize.bodySmall))
                            .foregroundColor(.statusDanger)
                            .padding(.vertical, 8)
                    }
                    
                    // Submit button
                    PrimaryButton(
                        title: isCreatingAccount ? "Create Account" : "Sign In",
                        action: handleSubmit,
                        isEnabled: isFormValid,
                        isLoading: authService.isLoading
                    )
                    .padding(.top, 8)
                    
                    // Toggle mode
                    Button(action: { 
                        withAnimation {
                            isCreatingAccount.toggle()
                            errorMessage = nil
                        }
                    }) {
                        Text(isCreatingAccount
                            ? "Already have an account? Sign in"
                            : "Don't have an account? Create one")
                            .font(.system(size: FontSize.bodyLarge, weight: .semibold))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
            }
        }
        .background(Color.deepBackground)
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
                    onSignIn(user)
                } else {
                    let signInData = SignInData(email: email, password: password)
                    let user = try await authService.signIn(data: signInData)
                    onSignIn(user)
                }
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

#Preview {
    SignInView(onBack: {}, onSignIn: { _ in })
        .environmentObject(AuthService())
}
