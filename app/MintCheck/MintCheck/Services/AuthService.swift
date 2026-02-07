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
        } catch {
            // No active session
            currentUser = nil
        }
    }
    
    /// Load user profile from database
    private func loadUserProfile(userId: UUID) async {
        do {
            let profile: UserProfile = try await supabase.database
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
            
            // Update profile with name
            try await supabase.database
                .from("profiles")
                .update([
                    "first_name": data.firstName,
                    "last_name": data.lastName
                ])
                .eq("id", value: user.id.uuidString)
                .execute()
            
            // Load the full profile
            await loadUserProfile(userId: user.id)
            
            guard let profile = currentUser else {
                throw AuthError.signUpFailed
            }
            
            return profile
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
            
            guard let profile = currentUser else {
                throw AuthError.signInFailed
            }
            
            return profile
        } catch {
            self.error = error.localizedDescription
            throw error
        }
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
            try await supabase.database
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
}

// MARK: - Auth Errors
enum AuthError: LocalizedError {
    case signUpFailed
    case signInFailed
    case notAuthenticated
    case profileNotFound
    
    var errorDescription: String? {
        switch self {
        case .signUpFailed:
            return "Failed to create account. Please try again."
        case .signInFailed:
            return "Invalid email or password."
        case .notAuthenticated:
            return "You must be signed in to perform this action."
        case .profileNotFound:
            return "User profile not found."
        }
    }
}
