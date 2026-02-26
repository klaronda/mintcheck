//
//  PasswordValidation.swift
//  MintCheck
//
//  Shared password rules and user-facing messaging for sign-up, change password, reset password.
//

import Foundation

/// Requirement that a password can fail. Each has a short user-facing description.
enum PasswordRequirement: String, CaseIterable {
    case tooShort = "at_least_8"
    case missingUppercase = "uppercase"
    case missingLowercase = "lowercase"
    case missingNumber = "number"
    case missingSpecial = "special"

    /// Short hint for this rule (e.g. for a static requirements line).
    var hint: String {
        switch self {
        case .tooShort: return "At least 8 characters"
        case .missingUppercase: return "One uppercase letter"
        case .missingLowercase: return "One lowercase letter"
        case .missingNumber: return "One number"
        case .missingSpecial: return "One special character (e.g. !@#$%)"
        }
    }

    /// Copy for the red validation message when this rule is missing (sentence case).
    var addPrompt: String {
        switch self {
        case .tooShort: return "Use at least 8 characters"
        case .missingUppercase: return "add at least one uppercase letter"
        case .missingLowercase: return "add at least one lowercase letter"
        case .missingNumber: return "add at least one number"
        case .missingSpecial: return "add at least one special character (e.g. !@#$%)"
        }
    }
}

/// Result of validating a password: valid flag and list of failed requirements.
struct PasswordValidationResult {
    let isValid: Bool
    let failedRequirements: [PasswordRequirement]

    /// Single line listing what's missing; one sentence, only the first character capitalized.
    var failureMessage: String? {
        guard !failedRequirements.isEmpty else { return nil }
        let prompts = failedRequirements.map(\.addPrompt)
        if prompts.count == 1 {
            let first = prompts[0]
            return first.prefix(1).uppercased() + first.dropFirst() + "."
        }
        // Join with " and " — keep all segments as-is (lowercase "add") so no capital "Add" in the middle
        let combined = prompts.dropLast().joined(separator: ", ") + " and " + prompts.last! + "."
        return combined.prefix(1).uppercased() + combined.dropFirst()
    }
}

enum PasswordValidator {
    /// Minimum length.
    static let minimumLength = 8

    /// Character set for "special" (punctuation/symbols). Keep hint in sync with PasswordRequirement.missingSpecial.
    private static let specialCharacterSet = CharacterSet(charactersIn: "!@#$%^&*()_+-=[]{}|;':\",./<>?`~\\")

    /// Validate password against rules: 8+ chars, upper, lower, number, special.
    static func validate(_ password: String) -> PasswordValidationResult {
        var failed: [PasswordRequirement] = []
        if password.count < minimumLength {
            failed.append(.tooShort)
        }
        if !password.contains(where: { $0.isUppercase }) {
            failed.append(.missingUppercase)
        }
        if !password.contains(where: { $0.isLowercase }) {
            failed.append(.missingLowercase)
        }
        if !password.contains(where: { $0.isNumber }) {
            failed.append(.missingNumber)
        }
        if !password.unicodeScalars.contains(where: { specialCharacterSet.contains($0) }) {
            failed.append(.missingSpecial)
        }
        return PasswordValidationResult(
            isValid: failed.isEmpty,
            failedRequirements: failed
        )
    }

    /// Static hint for UI: "At least 8 characters, with uppercase, lowercase, a number, and a special character (e.g. !@#$%)."
    static let requirementsHint = "At least 8 characters, with uppercase, lowercase, a number, and a special character (e.g. !@#$%)."
}
