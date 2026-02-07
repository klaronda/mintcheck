//
//  ValuationService.swift
//  MintCheck
//
//  Vehicle valuation service - stores AI-generated valuations
//

import Foundation

/// Service for generating vehicle market value lookup links
struct ValuationService {
    
    // MARK: - Models
    
    /// Result containing vehicle valuation estimates
    struct ValuationResult: Codable {
        let lowEstimate: Int
        let highEstimate: Int
        let baseValue: Int
        let adjustments: [Adjustment]
        let disclaimer: String
        let kbbURL: String?
        let carsComURL: String?  // Deprecated - kept for backward compatibility, always nil
        
        /// Average estimate (kept for backward compatibility)
        var averageEstimate: Int {
            (lowEstimate + highEstimate) / 2
        }
        
        /// Formatted value range
        var formattedRange: String {
            "$\(lowEstimate.formatted()) - $\(highEstimate.formatted())"
        }
    }
    
    /// Individual adjustment (kept for backward compatibility with stored data)
    struct Adjustment: Codable {
        let description: String
        let amount: Int
        let category: AdjustmentCategory
        
        enum AdjustmentCategory: String, Codable {
            case age
            case mileage
            case condition
            case tires
            case dtc
            case other
        }
    }
    
    /// Price assessment (simplified - no longer used for dollar comparisons)
    enum PriceAssessment: String {
        case greatDeal = "Great Deal"
        case fairPrice = "Fair Price"
        case overpriced = "Overpriced"
        case noAsking = "No Asking Price"
    }
    
    // MARK: - Constants
    
    static let standardDisclaimer = "Prices vary by trim, mileage, condition, and region."
    
    // MARK: - Deprecated Methods (kept for backward compatibility)
    
    /// Assess price (no longer provides meaningful comparison)
    func assessPrice(askingPrice: Int?, valuation: ValuationResult) -> PriceAssessment {
        return .noAsking
    }
}

// MARK: - JSON Structures for Storage (backward compatibility)

/// Codable structure for storing valuation in Supabase
struct ValuationJSON: Codable {
    var lowEstimate: Int?
    var highEstimate: Int?
    var baseValue: Int?
    var adjustments: [AdjustmentJSON]?
    var disclaimer: String?
    var kbbURL: String?
    var carsComURL: String?
}

/// Codable structure for adjustments
struct AdjustmentJSON: Codable {
    var description: String?
    var amount: Int?
    var category: String?
}

// MARK: - Extensions

extension ValuationService.ValuationResult {
    /// Convert to JSON for storage
    func toJSON() -> ValuationJSON {
        ValuationJSON(
            lowEstimate: lowEstimate,
            highEstimate: highEstimate,
            baseValue: baseValue,
            adjustments: adjustments.map { AdjustmentJSON(
                description: $0.description,
                amount: $0.amount,
                category: $0.category.rawValue
            )},
            disclaimer: disclaimer,
            kbbURL: kbbURL,
            carsComURL: carsComURL
        )
    }
}
