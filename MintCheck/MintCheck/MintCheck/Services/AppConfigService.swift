//
//  AppConfigService.swift
//  MintCheck
//
//  Fetches app config (feature flags) for Early Access and new user default role.
//

import Foundation
import Combine

/// App config / feature flags from backend
@MainActor
class AppConfigService: ObservableObject {
    static let shared = AppConfigService()
    
    @Published var earlyAccessEnabled: Bool = false
    @Published var newUserDefaultRole: String = "free"
    @Published var lastFetchedAt: Date?
    
    private init() {}
    
    /// Fetch config from Edge Function (call on launch and after login)
    func fetch() async {
        let baseURL = SupabaseConfig.shared.baseURL
        guard let url = URL(string: "\(baseURL.absoluteString)/functions/v1/app-config") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(SupabaseConfig.shared.anonKey, forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, http.statusCode == 200 else { return }
            let decoded = try JSONDecoder().decode(AppConfigResponse.self, from: data)
            earlyAccessEnabled = decoded.early_access_enabled
            newUserDefaultRole = decoded.new_user_default_role
            lastFetchedAt = Date()
        } catch {
            print("AppConfigService fetch failed: \(error)")
        }
    }
}

private struct AppConfigResponse: Codable {
    let early_access_enabled: Bool
    let new_user_default_role: String
}
