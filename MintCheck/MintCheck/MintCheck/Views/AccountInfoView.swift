//
//  AccountInfoView.swift
//  MintCheck
//
//  Account info: profile, email, password, and security helpers
//

import SwiftUI

struct AccountInfoView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    
    @State private var firstName: String = ""
    @State private var lastName: String = ""
    @State private var isEditingName: Bool = false
    @State private var showSavedToast = false
    @State private var showChangeEmail = false
    @State private var showChangePassword = false
    @State private var showPasswordUpdatedToast = false
    @State private var showResendSuccess = false
    @State private var isEmailConfirmed: Bool = true
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Account Information")
                .font(.system(size: FontSize.h4, weight: .semibold))
                .foregroundColor(.textPrimary)
            
            // A) Profile Section (collapsed by default, expandable on Edit)
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Name")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.textSecondary)
                        if !isEditingName {
                            Text(displayName)
                                .font(.system(size: FontSize.bodyLarge, weight: .medium))
                                .foregroundColor(.textPrimary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                        }
                    }
                    Spacer()
                    if !isEditingName {
                        Button(action: { isEditingName = true }) {
                            Text("Edit")
                                .font(.system(size: FontSize.bodySmall, weight: .semibold))
                                .foregroundColor(.mintGreen)
                        }
                        .buttonStyle(.plain)
                    }
                }
                
                if isEditingName {
                    VStack(alignment: .leading, spacing: 12) {
                        InputField(label: "First Name", text: $firstName, placeholder: "John")
                        InputField(label: "Last Name", text: $lastName, placeholder: "Smith")
                        
                        HStack(spacing: 12) {
                            SecondaryButton(
                                title: "Cancel",
                                action: {
                                    // Reset to current profile values
                                    firstName = authService.currentUser?.firstName ?? ""
                                    lastName = authService.currentUser?.lastName ?? ""
                                    isEditingName = false
                                },
                                style: .outlined
                            )
                            
                            PrimaryButton(
                                title: "Save",
                                action: {
                                    saveProfile()
                                    isEditingName = false
                                },
                                isEnabled: hasProfileChanges
                            )
                        }
                    }
                }
            }
            .padding(LayoutConstants.padding4)
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            
            // B) Email Section
            VStack(spacing: 0) {
                HStack {
                    Text("Email")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textSecondary)
                    Spacer()
                    Text(authService.currentUser?.email ?? "Not set")
                        .font(.system(size: FontSize.bodyRegular))
                        .foregroundColor(.textPrimary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                
                Divider()
                    .padding(.leading, 16)
                
                Button(action: { showChangeEmail = true }) {
                    HStack {
                        Text("Change email")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.mintGreen)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.mintGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            
            // C) Password Section
            VStack(spacing: 0) {
                Button(action: { showChangePassword = true }) {
                    HStack {
                        Text("Change password")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.right")
                            .font(.system(size: 12))
                            .foregroundColor(.textSecondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(Color.white)
            .cornerRadius(LayoutConstants.borderRadiusLarge)
            .overlay(
                RoundedRectangle(cornerRadius: LayoutConstants.borderRadiusLarge)
                    .stroke(Color.borderColor, lineWidth: 1)
            )
            
            // D) Security helpers
            VStack(alignment: .leading, spacing: 8) {
                if !isEmailConfirmed {
                    Button(action: resendConfirmation) {
                        Text("Resend confirmation email")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.mintGreen)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .onAppear {
            firstName = authService.currentUser?.firstName ?? ""
            lastName = authService.currentUser?.lastName ?? ""
            Task { await refreshEmailConfirmed() }
        }
        .onChange(of: authService.currentUser?.id) { _, _ in
            firstName = authService.currentUser?.firstName ?? ""
            lastName = authService.currentUser?.lastName ?? ""
        }
        .sheet(isPresented: $showChangeEmail) {
            ChangeEmailView(onDismiss: {
                showChangeEmail = false
            })
            .environmentObject(authService)
            .environmentObject(nav)
        }
        .sheet(isPresented: $showChangePassword) {
            ChangePasswordView(onDismiss: {
                showChangePassword = false
                showPasswordUpdatedToast = true
            })
            .environmentObject(authService)
            .environmentObject(nav)
        }
        .overlay(toastOverlay)
    }
    
    private var displayName: String {
        let trimmedFirst = firstName.trimmingCharacters(in: .whitespaces)
        let trimmedLast = lastName.trimmingCharacters(in: .whitespaces)
        let combined = "\(trimmedFirst) \(trimmedLast)".trimmingCharacters(in: .whitespaces)
        return combined.isEmpty ? "Not set" : combined
    }
    
    private var hasProfileChanges: Bool {
        let currentFirst = authService.currentUser?.firstName ?? ""
        let currentLast = authService.currentUser?.lastName ?? ""
        return firstName != currentFirst || lastName != currentLast
    }
    
    private func saveProfile() {
        Task {
            do {
                try await authService.updateProfile(firstName: firstName, lastName: lastName)
                showSavedToast = true
            } catch {
                // Error shown via authService.error
            }
        }
    }
    
    private func refreshEmailConfirmed() async {
        isEmailConfirmed = await authService.isEmailConfirmed()
    }
    
    private func resendConfirmation() {
        Task {
            do {
                try await authService.resendConfirmationEmail()
                showResendSuccess = true
            } catch {
                // Error shown via authService
            }
        }
    }
    
    @ViewBuilder
    private var toastOverlay: some View {
        Group {
            if showSavedToast {
                Text("Saved")
                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.textPrimary)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSavedToast = false
                        }
                    }
            } else if showPasswordUpdatedToast {
                Text("Password updated")
                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.textPrimary)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showPasswordUpdatedToast = false
                        }
                    }
            } else if showResendSuccess {
                Text("Confirmation email sent")
                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.textPrimary)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showResendSuccess = false
                        }
                    }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showSavedToast)
        .animation(.easeInOut(duration: 0.2), value: showPasswordUpdatedToast)
        .animation(.easeInOut(duration: 0.2), value: showResendSuccess)
    }
}

#Preview {
    AccountInfoView()
        .environmentObject(AuthService())
}
