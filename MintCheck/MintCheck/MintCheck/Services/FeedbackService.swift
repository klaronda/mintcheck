//
//  FeedbackService.swift
//  MintCheck
//
//  Submits feedback to Supabase; queues when offline and flushes when back online.
//

import Foundation
import Combine
import Supabase

/// Result of submitting feedback
enum FeedbackSubmitResult {
    case sent(feedbackId: UUID)
    case queued
    case failure
}

/// Single queued feedback payload for offline retry
struct QueuedFeedbackPayload: Codable {
    let category: String
    let message: String?
    let email: String?
    let source: String
    let userId: String?
    let contextJson: Data
    let createdAt: Date
}

@MainActor
final class FeedbackService: ObservableObject {
    static let shared = FeedbackService()
    
    private let queueKey = "mintcheck_pending_feedback"
    private let supabaseURL = "https://iawkgqbrxoctatfrjpli.supabase.co"
    private let anonKey = SupabaseConfig.shared.anonKey
    private let functionsURL = "https://iawkgqbrxoctatfrjpli.supabase.co/functions/v1"
    
    private init() {}
    
    // MARK: - Queue persistence
    
    private func loadQueue() -> [QueuedFeedbackPayload] {
        guard let data = UserDefaults.standard.data(forKey: queueKey),
              let decoded = try? JSONDecoder().decode([QueuedFeedbackPayload].self, from: data) else {
            return []
        }
        return decoded
    }
    
    private func saveQueue(_ queue: [QueuedFeedbackPayload]) {
        guard let data = try? JSONEncoder().encode(queue) else { return }
        UserDefaults.standard.set(data, forKey: queueKey)
    }
    
    private func enqueue(payload: QueuedFeedbackPayload) {
        var q = loadQueue()
        q.append(payload)
        saveQueue(q)
    }
    
    // MARK: - Submit (online or queue)
    
    /// Submit feedback. On success returns .sent(id); on offline/network error queues and returns .queued; else .failure.
    func submitFeedback(
        category: FeedbackCategory,
        message: String?,
        email: String?,
        source: FeedbackSource,
        context: [String: Any],
        authService: AuthService
    ) async -> FeedbackSubmitResult {
        guard let contextData = try? JSONSerialization.data(withJSONObject: context) else {
            return .failure
        }
        
        let userId = authService.currentUser?.id.uuidString
        
        do {
            let id = try await insertFeedback(
                category: category.rawValue,
                message: message,
                email: email,
                source: source.rawValue,
                userId: userId,
                contextData: contextData
            )
            if let id = id {
                _ = try? await notifyFeedback(id: id)
                return .sent(feedbackId: id)
            }
            return .failure
        } catch {
            // Queue for later
            let payload = QueuedFeedbackPayload(
                category: category.rawValue,
                message: message,
                email: email,
                source: source.rawValue,
                userId: userId,
                contextJson: contextData,
                createdAt: Date()
            )
            enqueue(payload: payload)
            return .queued
        }
    }
    
    /// Insert one feedback row via Supabase REST (so we can send raw JSON context)
    private func insertFeedback(
        category: String,
        message: String?,
        email: String?,
        source: String,
        userId: String?,
        contextData: Data
    ) async throws -> UUID? {
        var body: [String: Any] = [
            "category": category,
            "message": message as Any,
            "email": email as Any,
            "source": source,
            "status": "received"
        ]
        if let uid = userId {
            body["user_id"] = uid
        }
        // Decode context JSON so we can merge into body
        if let contextObj = try? JSONSerialization.jsonObject(with: contextData) as? [String: Any] {
            body["context"] = contextObj
        }
        
        let url = URL(string: "\(supabaseURL)/rest/v1/feedback")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Add auth session if available
        if let session = try? await SupabaseConfig.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw NSError(domain: "FeedbackService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Insert failed"])
        }
        
        struct FeedbackRow: Decodable {
            let id: UUID
        }
        let decoded = try JSONDecoder().decode([FeedbackRow].self, from: data)
        return decoded.first?.id
    }
    
    /// Call notify-feedback Edge Function
    private func notifyFeedback(id: UUID) async throws {
        let url = URL(string: "\(functionsURL)/notify-feedback")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(anonKey, forHTTPHeaderField: "apikey")
        if let session = try? await SupabaseConfig.shared.client.auth.session {
            request.setValue("Bearer \(session.accessToken)", forHTTPHeaderField: "Authorization")
        }
        request.httpBody = try JSONSerialization.data(withJSONObject: ["feedbackId": id.uuidString])
        
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            // Non-fatal: feedback was saved
            return
        }
    }
    
    // MARK: - Flush queue (call when back online)
    
    /// Flush pending feedback. Call on app launch and when connectivity is restored.
    func flushQueueIfOnline(connectionManager: ConnectionManagerService?) async {
        guard connectionManager?.internetStatus == .online else { return }
        var queue = loadQueue()
        guard !queue.isEmpty else { return }
        
        var remaining: [QueuedFeedbackPayload] = []
        for payload in queue {
            do {
                if let id = try await insertFeedback(
                    category: payload.category,
                    message: payload.message,
                    email: payload.email,
                    source: payload.source,
                    userId: payload.userId,
                    contextData: payload.contextJson
                ) {
                    Task { _ = try? await self.notifyFeedback(id: id) }
                }
            } catch {
                remaining.append(payload)
            }
        }
        saveQueue(remaining)
    }
    
}
