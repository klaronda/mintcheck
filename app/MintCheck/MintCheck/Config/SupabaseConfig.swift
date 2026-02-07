//
//  SupabaseConfig.swift
//  MintCheck
//
//  Supabase client configuration
//

import Foundation
import Supabase

/// Supabase client singleton
class SupabaseConfig {
    static let shared = SupabaseConfig()
    
    let client: SupabaseClient
    
    private init() {
        let supabaseURL = URL(string: "https://iawkgqbrxoctatfrjpli.supabase.co")!
        let supabaseKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imlhd2tncWJyeG9jdGF0ZnJqcGxpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkwMTQ0MjMsImV4cCI6MjA4NDU5MDQyM30.Fo9eKh4GjoXtqqDKol3N4hT5pOdx0UsfEWjk_Yg7NAM"
        
        client = SupabaseClient(
            supabaseURL: supabaseURL,
            supabaseKey: supabaseKey
        )
    }
}

// MARK: - Convenience Accessors
extension SupabaseConfig {
    var auth: AuthClient {
        client.auth
    }
    
    var database: PostgrestClient {
        client.database
    }
}
