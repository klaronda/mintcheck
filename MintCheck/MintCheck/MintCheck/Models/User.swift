//
//  User.swift
//  MintCheck
//
//  User and profile models
//

import Foundation

/// User profile data
struct UserProfile: Codable, Identifiable, Equatable {
    let id: UUID
    var firstName: String?
    var lastName: String?
    var email: String?
    var createdAt: Date?
    var role: String?
    var earlyAccessGrantedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case firstName = "first_name"
        case lastName = "last_name"
        case email
        case createdAt = "created_at"
        case role
        case earlyAccessGrantedAt = "early_access_granted_at"
    }
    
    var displayName: String {
        if let first = firstName, !first.isEmpty {
            return first
        }
        return email?.components(separatedBy: "@").first ?? "User"
    }
    
    var fullName: String {
        [firstName, lastName]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
    
    var isEarlyAccess: Bool { role == "early_access" }
    var isTester: Bool { role == "tester" }
}

/// Sign up request data
struct SignUpData {
    var email: String
    var password: String
    var firstName: String
    var lastName: String
    var birthdate: Date?
}

/// Sign in request data
struct SignInData {
    var email: String
    var password: String
}
