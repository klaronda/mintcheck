//
//  Vehicle.swift
//  MintCheck
//
//  Vehicle information models
//

import Foundation

/// Vehicle information collected during scan setup
struct VehicleInfo: Codable, Identifiable {
    var id: UUID = UUID()
    var userId: UUID?
    var vin: String?
    var year: String
    var make: String
    var model: String
    var trim: String?
    var fuelType: String?
    var engine: String?
    var transmission: String?
    var drivetrain: String?
    var createdAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vin
        case year
        case make
        case model
        case trim
        case fuelType = "fuel_type"
        case engine
        case transmission
        case drivetrain
        case createdAt = "created_at"
    }
    
    /// Display string like "2018 Honda Accord"
    var displayName: String {
        "\(year) \(make) \(model)"
    }
    
    /// Check if we have decoded VIN details
    var hasDecodedDetails: Bool {
        trim != nil || fuelType != nil || engine != nil
    }
}

/// VIN decoding result from NHTSA API
struct VINDecodeResult: Codable {
    let vin: String
    let year: String?
    let make: String?
    let model: String?
    let trim: String?
    let fuelType: String?
    let engineSize: String?
    let engineCylinders: String?
    let transmission: String?
    let driveType: String?
    let bodyClass: String?
    
    /// Formatted engine string like "2.4L 4-Cylinder"
    var engineDescription: String? {
        guard let size = engineSize else { return nil }
        if let cylinders = engineCylinders {
            return "\(size) \(cylinders)-Cylinder"
        }
        return size
    }
}

/// Vehicle year options for picker
struct VehicleYears {
    static let years: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (1996...currentYear + 1).reversed().map { String($0) }
    }()
}
