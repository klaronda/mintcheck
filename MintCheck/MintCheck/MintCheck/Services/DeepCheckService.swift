//
//  DeepCheckService.swift
//  MintCheck
//
//  Creates Stripe Checkout sessions for Deep Vehicle Check and fetches purchase status.
//

import Foundation
import Supabase

/// Response from get-my-deep-check
struct DeepCheckStatus {
    let vin: String
    let status: String  // pending | paid | report_ready | report_failed
    let reportUrl: String?
    let reportError: String?
}

/// Single purchase from list-deep-check-purchases
struct DeepCheckPurchase: Identifiable {
    let id: UUID
    let vin: String
    let status: String  // pending | paid | report_ready | report_failed
    let reportUrl: String?
    let reportError: String?
    /// problems_reported | history_available when status == report_ready
    let recommendationStatus: String?
    /// Year Make Model from report when available (e.g. "2020 Honda Accord")
    let yearMakeModel: String?
    /// When the report was emailed to the purchaser (for "Emailed to you on ..." on My Deep Vehicle Checks)
    let reportEmailedAt: Date?
    let createdAt: Date
}

enum DeepCheckError: Error {
    case notAuthenticated
    case invalidVin
    case createSessionFailed(String?)
    case networkError
    case listLoadFailed(String?)

    var message: String {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .invalidVin: return "Please enter a valid VIN."
        case .createSessionFailed(let detail): return detail ?? "Could not start checkout."
        case .networkError: return "Connection error. Please try again."
        case .listLoadFailed: return "Couldn't load your reports. Pull down to try again."
        }
    }
}

enum DeepCheckEmailError: Error {
    case notAuthenticated
    case invalidCode
    case sendFailed(String?)

    var message: String {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .invalidCode: return "Invalid report."
        case .sendFailed(let detail): return detail ?? "Could not send email. Try again."
        }
    }
}

@MainActor
final class DeepCheckService {
    static let shared = DeepCheckService()

    private let functionsURL = "https://iawkgqbrxoctatfrjpli.supabase.co/functions/v1"
    private let anonKey = SupabaseConfig.shared.anonKey

    private init() {}

    /// Create a Stripe Checkout session for Deep Vehicle Check. Returns the checkout URL to open.
    func createSession(vin: String) async throws -> URL {
        let trimmed = vin.trimmingCharacters(in: .whitespaces).uppercased()
        guard trimmed.count == 17 else { throw DeepCheckError.invalidVin }

        var session = try await SupabaseConfig.shared.client.auth.session
        var token = session.accessToken

        func performRequest() async throws -> (Data, HTTPURLResponse) {
            let url = URL(string: "\(functionsURL)/create-deep-check-session")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.httpBody = try JSONEncoder().encode(["vin": trimmed])
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else { throw DeepCheckError.createSessionFailed("Invalid response") }
            return (data, http)
        }

        var (data, http) = try await performRequest()

        // Retry once with refreshed session if we get 401 (stale token)
        if http.statusCode == 401 {
            _ = try? await SupabaseConfig.shared.client.auth.refreshSession()
            session = try await SupabaseConfig.shared.client.auth.session
            token = session.accessToken
            (data, http) = try await performRequest()
        }

        if http.statusCode == 401 {
            throw DeepCheckError.notAuthenticated
        }
        if http.statusCode == 400 {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "VIN not recognized. We can't run a report for this VIN."
            throw DeepCheckError.createSessionFailed(message)
        }
        if http.statusCode != 200 {
            let message = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? "Checkout unavailable"
            throw DeepCheckError.createSessionFailed(message)
        }

        struct CreateResponse: Decodable {
            let url: String
        }
        let decoded = try JSONDecoder().decode(CreateResponse.self, from: data)
        guard let checkoutURL = URL(string: decoded.url) else {
            throw DeepCheckError.createSessionFailed("Invalid checkout URL")
        }
        return checkoutURL
    }

    /// Fetch the latest Deep Check purchase for the current user. If sessionId is provided, fetches that specific purchase.
    /// Returns nil if none or error.
    func getMyDeepCheck(sessionId: String? = nil) async -> DeepCheckStatus? {
        guard let session = try? await SupabaseConfig.shared.client.auth.session else { return nil }

        var urlString = "\(functionsURL)/get-my-deep-check"
        if let sid = sessionId {
            urlString += "?session_id=\(sid)"
        }
        guard let url = URL(string: urlString) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            return nil
        }

        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            return nil
        }

        struct GetResponse: Decodable {
            let vin: String
            let status: String
            let report_url: String?
            let report_error: String?
        }
        guard let decoded = try? JSONDecoder().decode(GetResponse.self, from: data) else {
            return nil
        }
        return DeepCheckStatus(
            vin: decoded.vin,
            status: decoded.status,
            reportUrl: decoded.report_url,
            reportError: decoded.report_error
        )
    }

    /// Fetch all Deep Check purchases for the current user (for "My Deep Vehicle Checks" list). Throws on auth/network/server error. Calls list-deep-check-purchases.
    func getMyDeepChecks() async throws -> [DeepCheckPurchase] {
        var session = try await SupabaseConfig.shared.client.auth.session
        var token = session.accessToken

        func performRequest() async throws -> (Data, HTTPURLResponse) {
            let url = URL(string: "\(functionsURL)/list-deep-check-purchases")!
            var request = URLRequest(url: url)
            request.httpMethod = "GET"
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw DeepCheckError.listLoadFailed(nil)
            }
            return (data, http)
        }

        var (data, http) = try await performRequest()

        if http.statusCode == 401 {
            _ = try? await SupabaseConfig.shared.client.auth.refreshSession()
            session = try await SupabaseConfig.shared.client.auth.session
            token = session.accessToken
            (data, http) = try await performRequest()
        }

        if http.statusCode == 401 {
            throw DeepCheckError.notAuthenticated
        }
        if http.statusCode != 200 {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? nil
            throw DeepCheckError.listLoadFailed(msg)
        }

        struct PurchaseRow: Decodable {
            let id: String
            let vin: String
            let status: String
            let report_url: String?
            let report_error: String?
            let recommendation_status: String?
            let year_make_model: String?
            let report_emailed_at: String?
            let created_at: String
        }
        struct ListResponse: Decodable {
            let purchases: [PurchaseRow]
        }
        let decoded: ListResponse
        do {
            decoded = try JSONDecoder().decode(ListResponse.self, from: data)
        } catch {
            throw DeepCheckError.listLoadFailed(nil)
        }
        let formatterWithFractional = ISO8601DateFormatter()
        formatterWithFractional.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let formatterStandard = ISO8601DateFormatter()
        formatterStandard.formatOptions = [.withInternetDateTime]
        return decoded.purchases.compactMap { row in
            guard let uuid = UUID(uuidString: row.id) else { return nil }
            let date = formatterWithFractional.date(from: row.created_at)
                ?? formatterStandard.date(from: row.created_at)
                ?? Date()
            let emailedAt: Date? = {
                guard let s = row.report_emailed_at, !s.isEmpty else { return nil }
                return formatterWithFractional.date(from: s) ?? formatterStandard.date(from: s)
            }()
            return DeepCheckPurchase(
                id: uuid,
                vin: row.vin,
                status: row.status,
                reportUrl: row.report_url,
                reportError: row.report_error,
                recommendationStatus: row.recommendation_status,
                yearMakeModel: row.year_make_model,
                reportEmailedAt: emailedAt,
                createdAt: date
            )
        }
    }

    /// Request that the report link be emailed to the purchaser. Report code is the last path component of report_url (e.g. from .../report/ABC123).
    func emailReport(reportCode: String) async throws {
        let code = reportCode.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else { throw DeepCheckEmailError.invalidCode }

        let session = try await SupabaseConfig.shared.client.auth.session
        let url = URL(string: "\(functionsURL)/email-deep-check-report")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONEncoder().encode(["code": code])

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw DeepCheckEmailError.sendFailed(nil) }
        if http.statusCode == 401 { throw DeepCheckEmailError.notAuthenticated }
        if http.statusCode != 200 {
            let msg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"] ?? nil
            throw DeepCheckEmailError.sendFailed(msg)
        }
    }
}
