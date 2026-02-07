//
//  FeedbackModalView.swift
//  MintCheck
//
//  Reusable feedback modal: category, message, email; submit / cancel.
//

import SwiftUI

struct FeedbackModalView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var nav: NavigationManager
    @EnvironmentObject var connectionManager: ConnectionManagerService
    
    @Binding var isPresented: Bool
    var defaultCategory: FeedbackCategory = .suggestion
    var defaultMessage: String = ""
    var source: FeedbackSource = .in_app
    var errorCode: String? = nil
    var errorMessage: String? = nil
    var scanStepForPrefill: String? = nil
    
    @State private var category: FeedbackCategory = .suggestion
    @State private var message: String = ""
    @State private var email: String = ""
    @State private var isSubmitting = false
    @State private var showQueuedMessage = false
    @State private var showSuccessToast = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("We may include technical details about your device and scan to help us troubleshoot.")
                        .font(.system(size: FontSize.bodySmall))
                        .foregroundColor(.textSecondary)
                        .padding(.bottom, 4)
                    
                    // Category
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Category")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        Picker("", selection: $category) {
                            ForEach(FeedbackCategory.allCases, id: \.self) { cat in
                                Text(cat.rawValue).tag(cat)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(.textPrimary)
                    }
                    
                    // Message
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What were you trying to do? (optional)")
                            .font(.system(size: FontSize.bodyRegular, weight: .medium))
                            .foregroundColor(.textPrimary)
                        TextEditor(text: $message)
                            .font(.system(size: FontSize.bodyLarge))
                            .foregroundColor(.textPrimary)
                            .frame(minHeight: 80)
                            .padding(12)
                            .background(Color.white)
                            .cornerRadius(LayoutConstants.borderRadius)
                            .overlay(
                                RoundedRectangle(cornerRadius: LayoutConstants.borderRadius)
                                    .stroke(Color.borderColor, lineWidth: 1)
                            )
                    }
                    
                    // Email
                    InputField(
                        label: "Email for follow-up (optional)",
                        text: $email,
                        placeholder: "you@example.com",
                        keyboardType: .emailAddress
                    )
                    
                    if showQueuedMessage {
                        Text("Couldn't send. We'll try again when you're back online.")
                            .font(.system(size: FontSize.bodyRegular))
                            .foregroundColor(.statusCaution)
                    }
                    
                    PrimaryButton(
                        title: "Submit",
                        action: submit,
                        isEnabled: !isSubmitting,
                        isLoading: isSubmitting
                    )
                    .padding(.top, 8)
                }
                .padding(24)
            }
            .background(Color.deepBackground)
            .navigationTitle("Send feedback")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                    .font(.system(size: FontSize.bodyLarge, weight: .medium))
                    .foregroundColor(.mintGreen)
                }
            }
        }
        .onAppear {
            category = defaultCategory
            message = defaultMessage
            email = authService.currentUser?.email ?? ""
        }
        .overlay(toastOverlay)
    }
    
    private var toastOverlay: some View {
        Group {
            if showSuccessToast {
                Text("Thanks — we got it.")
                    .font(.system(size: FontSize.bodyRegular, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.textPrimary)
                    .cornerRadius(LayoutConstants.borderRadius)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showSuccessToast = false
                            isPresented = false
                        }
                    }
            }
        }
    }
    
    private func submit() {
        isSubmitting = true
        showQueuedMessage = false
        
        var prefill: [String: Any]? = nil
        if let code = errorCode { prefill = (prefill ?? [:]); prefill?["error_code"] = code }
        if let msg = errorMessage { prefill = (prefill ?? [:]); prefill?["error_message"] = msg }
        if let step = scanStepForPrefill { prefill = (prefill ?? [:]); prefill?["scan_step"] = step }
        let context = FeedbackContextService.buildContext(
            authService: authService,
            nav: nav,
            connectionManager: connectionManager,
            prefill: prefill
        )
        
        Task {
            let result = await FeedbackService.shared.submitFeedback(
                category: category,
                message: message.isEmpty ? nil : message,
                email: email.isEmpty ? nil : email,
                source: source,
                context: context,
                authService: authService
            )
            
            await MainActor.run {
                isSubmitting = false
                switch result {
                case .sent:
                    showSuccessToast = true
                case .queued:
                    showQueuedMessage = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        isPresented = false
                    }
                case .failure:
                    showQueuedMessage = true
                }
            }
        }
    }
}
