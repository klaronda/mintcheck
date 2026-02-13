//
//  AuthService.swift
//  MintCheck
//
//  Supabase authentication service
//

import Foundation
import Combine
import Supabase

/// Authentication service managing user sign in/up and session
@MainActor
class AuthService: ObservableObject {
    @Published var currentUser: UserProfile?
    @Published var isLoading: Bool = false
    @Published var error: String?
    
    private var supabase: SupabaseClient {
        SupabaseConfig.shared.client
    }
    
    init() {
        Task {
            await checkSession()
        }
    }
    
    // MARK: - Session Management
    
    /// Check for existing session on app launch
    func checkSession() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.session
            await loadUserProfile(userId: session.user.id)
            // Check buyer pass status
            hasBuyerPass = await BuyerPassService.shared.loadActiveBuyerPass()
        } catch {
            // No active session
            currentUser = nil
            hasBuyerPass = false
        }
        await AppConfigService.shared.fetch()
    }

    /// Refresh buyer pass status (e.g. after returning from Stripe checkout)
    func refreshBuyerPassStatus() async {
        hasBuyerPass = await BuyerPassService.shared.loadActiveBuyerPass()
    }
    
    var isEarlyAccess: Bool { currentUser?.isEarlyAccess ?? false }
    var isTester: Bool { currentUser?.isTester ?? false }
    @Published var hasBuyerPass: Bool = false

    /// Full app access (dashboard, scan flow, no paywall). Tester gets same access as early_access for live testing.
    /// Buyer Pass holders also get full access for 60 days.
    var hasFullAccess: Bool { isEarlyAccess || isTester || hasBuyerPass }
    
    /// Load user profile from database
    private func loadUserProfile(userId: UUID) async {
        do {
            let profile: UserProfile = try await supabase
                .from("profiles")
                .select()
                .eq("id", value: userId.uuidString)
                .single()
                .execute()
                .value
            
            // Get email from auth user
            let session = try await supabase.auth.session
            var profileWithEmail = profile
            profileWithEmail.email = session.user.email
            
            currentUser = profileWithEmail
        } catch {
            print("Failed to load profile: \(error)")
            // Create a basic profile from auth data
            if let session = try? await supabase.auth.session {
                currentUser = UserProfile(
                    id: session.user.id,
                    email: session.user.email
                )
            }
        }
    }
    
    // MARK: - Sign Up
    
    /// Create a new account
    func signUp(data: SignUpData) async throws -> UserProfile {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            // Create auth user
            let authResponse = try await supabase.auth.signUp(
                email: data.email,
                password: data.password
            )
            
            let user = authResponse.user
            
            // Check if email confirmation is required (session will be nil)
            if authResponse.session == nil {
                // Send confirmation email via Resend (branded template)
                try? await sendConfirmationEmail(to: data.email, type: "signup")
                // Still try to update profile with name
                try? await supabase
                    .from("profiles")
                    .update([
                        "first_name": data.firstName,
                        "last_name": data.lastName
                    ])
                    .eq("id", value: user.id.uuidString)
                    .execute()
                
                throw AuthError.emailConfirmationRequired
            }
            
            // Update profile with name
            try await supabase
                .from("profiles")
                .update([
                    "first_name": data.firstName,
                    "last_name": data.lastName
                ])
                .eq("id", value: user.id.uuidString)
                .execute()
            
            // Load the full profile
            await loadUserProfile(userId: user.id)
            await AppConfigService.shared.fetch()
            
            guard let profile = currentUser else {
                throw AuthError.signUpFailed
            }
            
            return profile
        } catch let authError as AuthError {
            // Re-throw our custom errors without overwriting
            throw authError
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Sign In
    
    /// Sign in with email and password
    func signIn(data: SignInData) async throws -> UserProfile {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            let session = try await supabase.auth.signIn(
                email: data.email,
                password: data.password
            )
            
            await loadUserProfile(userId: session.user.id)
            await AppConfigService.shared.fetch()
            
            guard let profile = currentUser else {
                throw AuthError.signInFailed
            }
            
            return profile
        } catch {
            self.error = Self.friendlyMessage(forSignInError: error)
            throw error
        }
    }

    /// User-facing message for invalid credentials / wrong password.
    static let friendlySignInFailureMessage = "We couldn't sign you in. Double-check your email and password. If you use a password manager, try pasting your password again or typing it manually."

    /// Map sign-in or reauth errors to a friendly message.
    static func friendlyMessage(forSignInError error: Error) -> String {
        if let authError = error as? AuthError {
            return authError.errorDescription ?? friendlySignInFailureMessage
        }
        let msg = error.localizedDescription.lowercased()
        if msg.contains("invalid") && (msg.contains("credential") || msg.contains("login") || msg.contains("password") || msg.contains("email")),
           msg.contains("confirm") == false {
            return friendlySignInFailureMessage
        }
        if msg.contains("email not confirmed") || msg.contains("confirm your email") {
            return "Please check your email to confirm your account."
        }
        if msg.contains("user not found") || msg.contains("no user") || msg.contains("not found") {
            return "No account found with this email. Try creating an account or check for typos."
        }
        return "We couldn't sign you in. Please check your email and password."
    }
    
    // MARK: - Sign Out
    
    /// Sign out current user
    func signOut() async throws {
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            try await supabase.auth.signOut()
            currentUser = nil
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Re-authentication
    
    /// Re-authenticate with current password (required before email/password changes).
    /// Returns true if successful. Throws if session is stale or password is wrong.
    func reauthenticate(password: String) async throws -> Bool {
        guard let email = currentUser?.email else {
            throw AuthError.notAuthenticated
        }
        do {
            _ = try await supabase.auth.signIn(
                email: email,
                password: password
            )
            return true
        } catch {
            self.error = Self.friendlyMessage(forSignInError: error)
            throw error
        }
    }
    
    // MARK: - Update Profile
    
    /// Update user profile
    func updateProfile(firstName: String?, lastName: String?) async throws {
        guard let userId = currentUser?.id else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        var updates: [String: String] = [:]
        if let first = firstName { updates["first_name"] = first }
        if let last = lastName { updates["last_name"] = last }
        
        do {
            try await supabase
                .from("profiles")
                .update(updates)
                .eq("id", value: userId.uuidString)
                .execute()
            
            // Refresh profile
            await loadUserProfile(userId: userId)
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Update Password
    
    /// Update password (requires re-auth with current password first).
    func updatePassword(current: String, new: String) async throws {
        _ = try await reauthenticate(password: current)
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            try await supabase.auth.update(user: UserAttributes(password: new))
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Email Change (sends confirmation to new email via Edge Function)
    
    /// Request email change; sends confirmation link to new address. Call after reauth.
    func requestEmailChange(newEmail: String, currentPassword: String) async throws {
        _ = try await reauthenticate(password: currentPassword)
        let session = try await supabase.auth.session
        let baseURL = SupabaseConfig.shared.baseURL
        guard let url = URL(string: "\(baseURL.absoluteString)/functions/v1/send-email-change-confirmation") else {
            throw AuthError.signUpFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue(SupabaseConfig.shared.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONEncoder().encode(["new_email": newEmail])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.signUpFailed }
        guard http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Request failed"
            throw NSError(domain: "AuthService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
    
    // MARK: - Password Reset (no auth required)
    
    /// Request password reset email. Always show same message (don't reveal if email exists).
    func requestPasswordReset(email: String) async throws {
        let baseURL = SupabaseConfig.shared.baseURL
        guard let url = URL(string: "\(baseURL.absoluteString)/functions/v1/send-password-reset") else {
            throw AuthError.signUpFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.shared.anonKey, forHTTPHeaderField: "apikey")
        request.httpBody = try? JSONEncoder().encode(["email": email])
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.signUpFailed }
        if http.statusCode != 200 {
            // Still don't reveal failure - treat as success for UX
        }
    }
    
    // MARK: - Resend Confirmation Email
    
    /// Whether the current user's email is confirmed (from auth session).
    func isEmailConfirmed() async -> Bool {
        guard let session = try? await supabase.auth.session else { return false }
        return session.user.emailConfirmedAt != nil
    }
    
    /// Resend email confirmation link (for unconfirmed accounts).
    func resendConfirmationEmail() async throws {
        guard let email = currentUser?.email else { throw AuthError.notAuthenticated }
        try await sendConfirmationEmail(to: email, type: "signup")
    }

    /// Send confirmation email via Edge Function (Resend). Used for first signup and resend. No session required.
    private func sendConfirmationEmail(to email: String, type: String) async throws {
        let baseURL = SupabaseConfig.shared.baseURL
        guard let url = URL(string: "\(baseURL.absoluteString)/functions/v1/send-confirmation-email") else {
            throw AuthError.signUpFailed
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(SupabaseConfig.shared.anonKey, forHTTPHeaderField: "apikey")
        if let session = try? await supabase.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try? JSONEncoder().encode(["email": email, "type": type])
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw AuthError.signUpFailed }
        guard http.statusCode == 200 else {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Couldn't send email. Try again."
            throw NSError(domain: "AuthService", code: http.statusCode, userInfo: [NSLocalizedDescriptionKey: msg])
        }
    }
    
    // MARK: - Delete Account
    
    /// Permanently delete user account and all associated data via Edge Function
    func deleteAccount() async throws {
        guard currentUser != nil else {
            throw AuthError.notAuthenticated
        }
        
        isLoading = true
        error = nil
        defer { isLoading = false }
        
        do {
            // Get current session (refresh if needed)
            var session = try await supabase.auth.session
            
            // Try to refresh if session might be expired
            do {
                try await supabase.auth.refreshSession()
                session = try await supabase.auth.session
            } catch {
                // Session refresh failed, but try with current session
                print("Session refresh failed, using current session: \(error)")
            }
            
            // Get access token from session
            // In Supabase Swift SDK, the token is accessed via session.accessToken
            let accessToken = session.accessToken
            
            print("Attempting to delete account with token (first 20 chars): \(String(accessToken.prefix(20)))...")
            
            // Get Edge Function URL
            let baseURL = SupabaseConfig.shared.baseURL
            guard let url = URL(string: "\(baseURL.absoluteString)/functions/v1/delete-account") else {
                throw AuthError.signUpFailed
            }
            
            // Create request
            var urlRequest = URLRequest(url: url)
            urlRequest.httpMethod = "POST"
            urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
            
            // Send user's JWT token in Authorization header
            urlRequest.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
            // Also include apikey header (anon key) for Supabase
            urlRequest.setValue(SupabaseConfig.shared.anonKey, forHTTPHeaderField: "apikey")
            
            // Make request
            let (data, response) = try await URLSession.shared.data(for: urlRequest)
            
            // Check response
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AuthError.signUpFailed
            }
            
            guard httpResponse.statusCode == 200 else {
                // Try to parse error message
                let errorMessage: String
                if let errorJson = try? JSONDecoder().decode([String: String].self, from: data),
                   let error = errorJson["error"] {
                    errorMessage = error
                } else if let errorText = String(data: data, encoding: .utf8) {
                    errorMessage = "HTTP \(httpResponse.statusCode): \(errorText)"
                } else {
                    errorMessage = "HTTP \(httpResponse.statusCode): Failed to delete account"
                }
                
                self.error = errorMessage
                print("Delete account failed: \(errorMessage)")
                throw NSError(domain: "AuthService", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
            }
            
            // Clear local state (auth user is already deleted by Edge Function)
            currentUser = nil
            
        } catch {
            self.error = error.localizedDescription
            throw error
        }
    }
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case signUpFailed
    case signInFailed
    case notAuthenticated
    case profileNotFound
    case emailConfirmationRequired
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return AuthService.friendlySignInFailureMessage
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .profileNotFound:
            return "User profile not found."
        case .emailConfirmationRequired:
            return "Please check your email to confirm your account."
        }
    }
    
    var isEmailConfirmation: Bool {
        if case .emailConfirmationRequired = self { return true }
        return false
    }
}
