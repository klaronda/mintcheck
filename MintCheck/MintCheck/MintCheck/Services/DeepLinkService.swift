//
//  DeepLinkService.swift
//  MintCheck
//
//  Parses auth deep links (confirm, reset) and coordinates with AuthService / navigation.
//

import Foundation
import Supabase

/// Result of handling a deep link
enum DeepLinkResult {
    case emailConfirmationSuccess
    case showResetPassword
    case linkExpired
    case invalidLink
    case deepCheckSuccess(sessionId: String?)
    case buyerPassSuccess
    case ignored
}

enum DeepLinkService {
    private static var supabase: SupabaseClient {
        SupabaseConfig.shared.client
    }

    /// Handle a URL that may be an auth deep link (mintcheckapp.com/auth/confirm or /auth/reset, or mintcheck://)
    @MainActor
    static func handle(url: URL) async -> DeepLinkResult {
        let path: String
        if url.host == "mintcheckapp.com" || url.host == "www.mintcheckapp.com" {
            path = url.path
        } else if url.scheme == "mintcheck" {
            // mintcheck://deep-check/success has host "deep-check", path "/success" -> treat as "deep-check/success"
            if let host = url.host, !host.isEmpty {
                path = "/\(host)\(url.path)"
            } else {
                path = url.path
            }
        } else {
            return .ignored
        }

        // Deep Check success (Stripe redirect)
        if path == "/deep-check/success" || path == "deep-check/success" {
            let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            let sessionId = components?.queryItems?.first(where: { $0.name == "session_id" })?.value
            return .deepCheckSuccess(sessionId: sessionId)
        }

        // Buyer Pass success (Stripe redirect)
        if path == "/buyer-pass/success" || path == "buyer-pass/success" {
            return .buyerPassSuccess
        }

        guard path.hasPrefix("/auth/") else { return .ignored }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let query = components?.queryItems ?? []

        if path == "/auth/confirm" || path == "auth/confirm" {
            let token = query.first(where: { $0.name == "token" })?.value
            let type = query.first(where: { $0.name == "type" })?.value ?? "signup"
            guard let token = token, !token.isEmpty else { return .invalidLink }
            return await verifyEmailConfirmation(tokenHash: token, type: type)
        }

        if path == "/auth/reset" || path == "auth/reset" {
            let token = query.first(where: { $0.name == "token" })?.value
            guard let token = token, !token.isEmpty else { return .invalidLink }
            return await verifyPasswordRecovery(tokenHash: token)
        }

        return .ignored
    }

    /// Verify email confirmation OTP (signup or email_change). On success, session is established.
    @MainActor
    private static func verifyEmailConfirmation(tokenHash: String, type: String) async -> DeepLinkResult {
        let otpType: EmailOTPType
        switch type {
        case "email_change":
            otpType = .emailChange
        case "signup":
            otpType = .signup
        default:
            otpType = .signup
        }
        do {
            _ = try await supabase.auth.verifyOTP(
                tokenHash: tokenHash,
                type: otpType
            )
            return .emailConfirmationSuccess
        } catch {
            print("verifyOTP confirm error: \(error)")
            return .linkExpired
        }
    }

    /// Verify password recovery token. On success, session is in recovery mode and user can set new password.
    @MainActor
    private static func verifyPasswordRecovery(tokenHash: String) async -> DeepLinkResult {
        do {
            _ = try await supabase.auth.verifyOTP(
                tokenHash: tokenHash,
                type: .recovery
            )
            return .showResetPassword
        } catch {
            print("verifyOTP recovery error: \(error)")
            return .linkExpired
        }
    }
}
