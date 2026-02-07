//
//  BuyerPassService.swift
//  MintCheck
//
//  Creates Stripe Checkout sessions for Buyer Pass and queries active subscription status.
//

import Foundation
import Combine
import Supabase

/// Represents an active (or expired) Buyer Pass subscription
struct BuyerPassSubscription: Codable {
    let id: UUID
    let status: String      // pending | active | inactive | canceled | expired
    let startedAt: Date?
    let endedAt: Date?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case status
        case startedAt = "started_at"
        case endedAt = "ended_at"
        case createdAt = "created_at"
    }

    var isActive: Bool {
        status == "active" && !isExpired
    }

    var isExpired: Bool {
        guard let end = endedAt else { return false }
        return end < Date()
    }

    var daysRemaining: Int {
        guard let end = endedAt else { return 0 }
        let remaining = Calendar.current.dateComponents([.day], from: Date(), to: end).day ?? 0
        return max(remaining, 0)
    }
}

enum BuyerPassError: Error {
    case notAuthenticated
    case alreadyActive(String?)
    case createSessionFailed(String?)
    case networkError

    var message: String {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .alreadyActive(let detail): return detail ?? "You already have an active Buyer Pass."
        case .createSessionFailed(let detail): return detail ?? "Could not start checkout."
        case .networkError: return "Connection error. Please try again."
        }
    }
}

@MainActor
final class BuyerPassService: ObservableObject {
    static let shared = BuyerPassService()

    private let functionsURL = "https://iawkgqbrxoctatfrjpli.supabase.co/functions/v1"
    private let anonKey = SupabaseConfig.shared.anonKey

    @Published var activeBuyerPass: BuyerPassSubscription?

    private init() {}

    // MARK: - Create Checkout Session

    /// Create a Stripe Checkout session for Buyer Pass. Returns the checkout URL to open.
    func createCheckoutSession() async throws -> URL {
        var session = try await SupabaseConfig.shared.client.auth.session
        var token = session.accessToken

        func performRequest() async throws -> (Data, HTTPURLResponse) {
            let url = URL(string: "\(functionsURL)/create-buyer-pass-session")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = "{}".data(using: .utf8)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw BuyerPassError.createSessionFailed("Invalid response")
            }
            return (data, http)
        }

        var (data, http) = try await performRequest()

        // Retry once with refreshed session if we get 401
        if http.statusCode == 401 {
            _ = try? await SupabaseConfig.shared.client.auth.refreshSession()
            session = try await SupabaseConfig.shared.client.auth.session
            token = session.accessToken
            (data, http) = try await performRequest()
        }

        if http.statusCode == 401 {
            throw BuyerPassError.notAuthenticated
        }
        if http.statusCode == 400 {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw BuyerPassError.alreadyActive(message)
        }
        if http.statusCode != 200 {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw BuyerPassError.createSessionFailed(message)
        }

        struct CreateResponse: Decodable {
            let url: String
        }
        let decoded = try JSONDecoder().decode(CreateResponse.self, from: data)
        guard let checkoutURL = URL(string: decoded.url) else {
            throw BuyerPassError.createSessionFailed("Invalid checkout URL")
        }
        return checkoutURL
    }

    // MARK: - Load Active Buyer Pass

    /// Check for an active buyer pass subscription for the current user.
    /// Updates `activeBuyerPass` and returns whether one is active.
    @discardableResult
    func loadActiveBuyerPass() async -> Bool {
        guard let userId = try? await SupabaseConfig.shared.client.auth.session.user.id else {
            activeBuyerPass = nil
            return false
        }

        do {
            let subs: [BuyerPassSubscription] = try await SupabaseConfig.shared.client
                .from("subscriptions")
                .select("id, status, started_at, ended_at, created_at")
                .eq("user_id", value: userId.uuidString)
                .eq("plan", value: "buyer_pass")
                .order("created_at", ascending: false)
                .limit(1)
                .execute()
                .value

            if let sub = subs.first, sub.isActive {
                activeBuyerPass = sub
                return true
            } else {
                activeBuyerPass = nil
                return false
            }
        } catch {
            print("BuyerPassService: failed to load buyer pass: \(error)")
            activeBuyerPass = nil
            return false
        }
    }
}
