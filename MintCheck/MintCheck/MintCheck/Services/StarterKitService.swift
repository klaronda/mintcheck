//
//  StarterKitService.swift
//  MintCheck
//
//  Stripe Checkout for Starter Kit (Buyer Pass activates on fulfillment, not at payment).
//

import Foundation
import Supabase

enum StarterKitError: Error {
    case notAuthenticated
    case createSessionFailed(String?)
    case networkError

    var message: String {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .createSessionFailed(let detail): return detail ?? "Could not start checkout."
        case .networkError: return "Connection error. Please try again."
        }
    }
}

@MainActor
final class StarterKitService {
    static let shared = StarterKitService()

    private let functionsURL = "https://iawkgqbrxoctatfrjpli.supabase.co/functions/v1"
    private let anonKey = SupabaseConfig.shared.anonKey

    private init() {}

    /// Creates Stripe Checkout session; opens in Safari. Success URL is configured on the server.
    func createCheckoutSession() async throws -> URL {
        var session = try await SupabaseConfig.shared.client.auth.session
        var token = session.accessToken

        func performRequest() async throws -> (Data, HTTPURLResponse) {
            let url = URL(string: "\(functionsURL)/create-starter-kit-session")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = "{}".data(using: .utf8)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw StarterKitError.createSessionFailed("Invalid response")
            }
            return (data, http)
        }

        var (data, http) = try await performRequest()
        let bodyStr = String(data: data, encoding: .utf8) ?? "(no body)"
        print("StarterKitService: status \(http.statusCode) — body: \(bodyStr)")

        if http.statusCode == 401 {
            _ = try? await SupabaseConfig.shared.client.auth.refreshSession()
            session = try await SupabaseConfig.shared.client.auth.session
            token = session.accessToken
            (data, http) = try await performRequest()
            let retryBody = String(data: data, encoding: .utf8) ?? "(no body)"
            print("StarterKitService: retry status \(http.statusCode) — body: \(retryBody)")
        }

        if http.statusCode == 401 {
            throw StarterKitError.notAuthenticated
        }
        if http.statusCode != 200 {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw StarterKitError.createSessionFailed(message)
        }

        struct CreateResponse: Decodable {
            let url: String
        }
        let decoded = try JSONDecoder().decode(CreateResponse.self, from: data)
        guard let checkoutURL = URL(string: decoded.url) else {
            throw StarterKitError.createSessionFailed("Invalid checkout URL")
        }
        return checkoutURL
    }
}
