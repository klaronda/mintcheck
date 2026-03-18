//
//  OneTimeScanService.swift
//  MintCheck
//
//  StoreKit 2 one-time scan purchase ($3.99 consumable IAP).
//  Handles product loading, purchasing, server verification, and credit management.
//

import Foundation
import StoreKit
import Combine
import Supabase

enum OneTimeScanError: Error {
    case notAuthenticated
    case productNotFound
    case purchaseFailed(String?)
    case verificationFailed(String?)
    case networkError

    var message: String {
        switch self {
        case .notAuthenticated: return "Please sign in to continue."
        case .productNotFound: return "This product is not available right now."
        case .purchaseFailed(let detail): return detail ?? "Purchase could not be completed."
        case .verificationFailed(let detail): return detail ?? "Could not verify your purchase."
        case .networkError: return "Connection error. Please try again."
        }
    }
}

@MainActor
final class OneTimeScanService: ObservableObject {
    static let shared = OneTimeScanService()

    static let productID = "com.mintcheck.onetimescan"

    private let functionsURL = "https://iawkgqbrxoctatfrjpli.supabase.co/functions/v1"
    private let anonKey = SupabaseConfig.shared.anonKey

    @Published var product: Product?
    @Published var scanCredits: Int = 0
    @Published var isPurchasing: Bool = false

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProduct() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: - Product Loading

    func loadProduct() async {
        do {
            let products = try await Product.products(for: [Self.productID])
            product = products.first
            if let p = product {
                print("OneTimeScanService: loaded product '\(p.displayName)' at \(p.displayPrice)")
            } else {
                print("OneTimeScanService: WARNING — no product found for ID '\(Self.productID)'. Is the StoreKit config set in your scheme?")
            }
        } catch {
            print("OneTimeScanService: failed to load product:", error)
        }
    }

    // MARK: - Credits

    func loadCredits() async {
        guard let session = try? await SupabaseConfig.shared.client.auth.session else { return }
        do {
            struct ProfileCredits: Decodable {
                let scan_credits: Int
            }
            let result: ProfileCredits = try await SupabaseConfig.shared.client
                .from("profiles")
                .select("scan_credits")
                .eq("id", value: session.user.id.uuidString)
                .single()
                .execute()
                .value
            scanCredits = result.scan_credits
        } catch {
            print("OneTimeScanService: failed to load credits:", error)
        }
    }

    /// Decrement one credit after a purchased scan saves successfully.
    func consumeCredit() async {
        guard let session = try? await SupabaseConfig.shared.client.auth.session else { return }
        do {
            let result: Int? = try await SupabaseConfig.shared.client
                .rpc("decrement_scan_credits", params: ["p_user_id": session.user.id.uuidString])
                .execute()
                .value
            scanCredits = result ?? max(scanCredits - 1, 0)
        } catch {
            print("OneTimeScanService: failed to consume credit:", error)
            scanCredits = max(scanCredits - 1, 0)
        }
    }

    #if DEBUG
    /// Debug-only: increment credits directly via Supabase RPC (bypasses Edge Function for StoreKit Testing).
    private func incrementCreditsDirectly() async throws -> Int {
        guard let session = try? await SupabaseConfig.shared.client.auth.session else {
            print("OneTimeScanService: incrementCreditsDirectly — no auth session")
            throw OneTimeScanError.notAuthenticated
        }
        print("OneTimeScanService: incrementCreditsDirectly — calling RPC for user \(session.user.id)")
        do {
            let result: Int? = try await SupabaseConfig.shared.client
                .rpc("increment_scan_credits", params: ["p_user_id": session.user.id.uuidString])
                .execute()
                .value
            print("OneTimeScanService: incrementCreditsDirectly — success, credits = \(result ?? -1)")
            return result ?? (scanCredits + 1)
        } catch {
            print("OneTimeScanService: incrementCreditsDirectly — RPC failed: \(error)")
            throw error
        }
    }
    #endif

    // MARK: - Purchase

    /// Initiate a StoreKit 2 purchase and verify with the server.
    /// Returns the new credit count on success.
    @discardableResult
    func purchase() async throws -> Int {
        guard let product else {
            print("OneTimeScanService: purchase() — product is nil, cannot proceed")
            throw OneTimeScanError.productNotFound
        }

        print("OneTimeScanService: purchase() — starting purchase for \(product.id)")
        isPurchasing = true
        defer { isPurchasing = false }

        let result: Product.PurchaseResult
        do {
            result = try await product.purchase()
        } catch {
            print("OneTimeScanService: purchase() — StoreKit error: \(error)")
            throw OneTimeScanError.purchaseFailed(error.localizedDescription)
        }

        switch result {
        case .success(let verification):
            print("OneTimeScanService: purchase() — StoreKit success, verifying...")
            let transaction = try checkVerification(verification)

            #if DEBUG
            print("OneTimeScanService: purchase() — DEBUG mode, incrementing credits directly")
            let credits = try await incrementCreditsDirectly()
            #else
            let jwsString = verification.jwsRepresentation
            let credits = try await verifyWithServer(transaction: transaction, jws: jwsString)
            #endif

            await transaction.finish()
            print("OneTimeScanService: purchase() — complete, credits = \(credits)")
            scanCredits = credits
            return credits

        case .userCancelled:
            print("OneTimeScanService: purchase() — user cancelled")
            throw OneTimeScanError.purchaseFailed("Purchase was cancelled.")

        case .pending:
            print("OneTimeScanService: purchase() — pending approval")
            throw OneTimeScanError.purchaseFailed("Purchase is pending approval.")

        @unknown default:
            print("OneTimeScanService: purchase() — unknown result")
            throw OneTimeScanError.purchaseFailed("Unexpected purchase result.")
        }
    }

    // MARK: - Transaction Verification

    private func checkVerification<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified(_, let error):
            throw OneTimeScanError.verificationFailed(error.localizedDescription)
        case .verified(let safe):
            return safe
        }
    }

    /// Send the signed transaction to our Edge Function for server-side verification and credit increment.
    private func verifyWithServer(transaction: StoreKit.Transaction, jws: String) async throws -> Int {
        var session = try await SupabaseConfig.shared.client.auth.session
        var token = session.accessToken

        func performRequest() async throws -> (Data, HTTPURLResponse) {
            let url = URL(string: "\(functionsURL)/verify-scan-purchase")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.setValue(anonKey, forHTTPHeaderField: "apikey")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

            let body: [String: Any] = [
                "transactionId": String(transaction.id),
                "jwsRepresentation": jws
            ]
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse else {
                throw OneTimeScanError.verificationFailed("Invalid response")
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

        guard http.statusCode == 200 else {
            let errorMsg = (try? JSONDecoder().decode([String: String].self, from: data))?["error"]
            throw OneTimeScanError.verificationFailed(errorMsg)
        }

        struct VerifyResponse: Decodable {
            let success: Bool
            let credits: Int?
        }
        let decoded = try JSONDecoder().decode(VerifyResponse.self, from: data)
        return decoded.credits ?? (scanCredits + 1)
    }

    // MARK: - Transaction Listener

    /// Listen for unfinished transactions (e.g. interrupted purchases).
    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in StoreKit.Transaction.updates {
                guard let self else { return }
                if case .verified(let transaction) = result,
                   transaction.productID == Self.productID {
                    do {
                        #if DEBUG
                        let credits = try await self.incrementCreditsDirectly()
                        #else
                        let jwsString = result.jwsRepresentation
                        let credits = try await self.verifyWithServer(transaction: transaction, jws: jwsString)
                        #endif
                        await transaction.finish()
                        await MainActor.run { self.scanCredits = credits }
                    } catch {
                        print("OneTimeScanService: transaction listener error:", error)
                    }
                }
            }
        }
    }
}
