//
//  ScanResult.swift
//  MintCheck
//
//  Scan results and recommendation models
//

import Foundation
import SwiftUI

/// Recommendation type based on scan results
enum RecommendationType: String, Codable, CaseIterable {
    case safe = "safe"
    case lowData = "low-data"
    case caution = "caution"
    case notRecommended = "not-recommended"
    
    /// Full title for results page
    var title: String {
        switch self {
        case .safe: return "Car is Healthy"
        case .lowData: return "Not Enough Data"
        case .caution: return "Proceed with Caution"
        case .notRecommended: return "Not Recommended"
        }
    }
    
    /// Short badge text for dashboard cards
    var badgeText: String {
        switch self {
        case .safe: return "Healthy"
        case .lowData: return "Low Results"
        case .caution: return "Caution"
        case .notRecommended: return "Walk Away"
        }
    }
    
    var summary: String {
        switch self {
        case .safe:
            return "Based on the scan, this vehicle's engine and core systems appear to be in good condition. No major concerns were found."
        case .lowData:
            return "The scan couldn't read enough systems on this vehicle to give a full health assessment. What we did get looks okay, but we recommend a follow-up scan or professional inspection."
        case .caution:
            return "The scan found some items that need attention. Review the details below and consider having a mechanic inspect the vehicle before buying."
        case .notRecommended:
            return "The scan found significant concerns with this vehicle's systems. We recommend looking at other options or getting a professional inspection before proceeding."
        }
    }
    
    var iconName: String {
        switch self {
        case .safe: return "checkmark.circle.fill"
        case .lowData: return "info.circle.fill"
        case .caution: return "exclamationmark.circle.fill"
        case .notRecommended: return "xmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .safe: return .statusSafe
        case .lowData: return .statusInfo
        case .caution: return .statusCaution
        case .notRecommended: return .statusDanger
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .safe: return .statusSafeBg
        case .lowData: return .statusInfoBg
        case .caution: return .statusCautionBg
        case .notRecommended: return .statusDangerBg
        }
    }
}

/// Complete scan result stored in database
struct ScanResult: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var vehicleId: UUID?
    var recommendation: RecommendationType
    var scanData: ScanDataJSON?
    var quickCheck: QuickCheckJSON?
    var obdData: OBDDataJSON?
    var nhtsaData: NHTSADataJSON?
    var odometerReading: Int?
    var askingPrice: Int?
    var estimatedValue: ValuationJSON?
    var createdAt: Date?
    var shareCode: String?  // Share link code if report has been shared
    var summary: String?  // AI-generated recommendation summary
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case recommendation
        case scanData = "scan_data"
        case quickCheck = "quick_check"
        case obdData = "obd_data"
        case nhtsaData = "nhtsa_data"
        case odometerReading = "odometer_reading"
        case askingPrice = "asking_price"
        case estimatedValue = "estimated_value"
        case createdAt = "created_at"
        case shareCode = "share_code"
        case summary
    }
}

/// JSON structure for scan metadata
struct ScanDataJSON: Codable {
    var deviceType: String?
    var scanDuration: TimeInterval?
    var keyFindings: [String]?
    var priceRange: String?
    var priceNote: String?
    var repairEstimate: String?
    var aiAnalysis: AIAnalysisJSON?
}

/// JSON structure for AI analysis results
struct AIAnalysisJSON: Codable {
    var analyses: [DTCAnalysisJSON]?
    var totalRepairCostLow: Int?
    var totalRepairCostHigh: Int?
    var overallUrgency: String?
    var summary: String?
    var vehicleValuation: VehicleValuationJSON?
}

/// JSON structure for individual DTC analysis
struct DTCAnalysisJSON: Codable {
    var code: String?
    var name: String?
    var description: String?
    var repairCostLow: Int?
    var repairCostHigh: Int?
    var urgency: String?
    var commonForVehicle: Bool?
}

/// JSON structure for vehicle valuation
struct VehicleValuationJSON: Codable {
    var lowEstimate: Int?
    var highEstimate: Int?
    var reasoning: String?
}

/// JSON structure for quick check answers
struct QuickCheckJSON: Codable {
    var interiorCondition: String?
    var tireCondition: String?
    var dashboardLights: Bool?
    var warningLightTypes: [String]?
    var engineSounds: Bool?
    var fluidLeaks: String?
    var bodyDamage: Bool?
    var odometerReading: Int?
    var askingPrice: Int?
}

/// JSON structure for OBD scan data
struct OBDDataJSON: Codable {
    var vin: String?
    var dtcs: [String]?
    var rpm: Double?
    var coolantTemp: Double?
    var batteryVoltage: Double?
    var fuelLevel: Double?
    var engineLoad: Double?
    var intakeTemp: Double?
    var throttlePosition: Double?
    var vehicleSpeed: Double?
    var distanceSinceCleared: Double?
    var warmupCycles: Int?
    var fuelType: String?
    var obdStandard: String?
}

/// System detail for expandable sections
struct SystemDetail: Identifiable {
    let id = UUID()
    let name: String
    let status: String
    let color: Color
    let details: [String]
    let explanation: String
}

/// Scan history item for dashboard display
struct ScanHistoryItem: Identifiable {
    let id: UUID
    let date: Date
    let vehicle: String
    let recommendation: RecommendationType
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}
