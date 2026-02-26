//
//  Vehicle.swift
//  MintCheck
//
//  Vehicle information models
//

import Foundation

/// Vehicle information collected during scan setup (also "car" for Monitor)
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
    var vinLocked: Bool?
    /// Friendly name (e.g. Daily Driver) for Monitor cars
    var name: String?
    /// Odometer when car was added (optional)
    var odometerBaseline: Int?
    /// Normalized VIN for uniqueness (uppercase, no spaces)
    var vinHash: String?
    
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
        case vinLocked = "vin_locked"
        case name
        case odometerBaseline = "odometer_baseline"
        case vinHash = "vin_hash"
    }
    
    /// Display string like "2018 Honda Accord" or car name if set
    var displayName: String {
        if let name = name, !name.trimmingCharacters(in: .whitespaces).isEmpty {
            return "\(name) (\(year) \(make) \(model))"
        }
        return "\(year) \(make) \(model)"
    }
    
    /// Short display (year make model only)
    var shortDisplayName: String {
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
    
    /// True when we have non-empty year, make, and model (vehicle identified by decoder).
    var hasIdentifiedVehicle: Bool {
        let y = year?.trimmingCharacters(in: .whitespaces) ?? ""
        let m = make?.trimmingCharacters(in: .whitespaces) ?? ""
        let n = model?.trimmingCharacters(in: .whitespaces) ?? ""
        if y.isEmpty || m.isEmpty || n.isEmpty { return false }
        if y == "Unknown" || m == "Unknown" || n == "Unknown" { return false }
        return true
    }
}

/// Monitor / Buyer Pass subscription entitlement (per car)
struct SubscriptionInfo: Codable, Identifiable {
    var id: UUID
    var userId: UUID
    var vehicleId: UUID
    var plan: String  // "monitor" | "buyer_pass"
    var status: String  // "active" | "inactive" | "canceled"
    var startedAt: Date?
    var endedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case plan
        case status
        case startedAt = "started_at"
        case endedAt = "ended_at"
    }
    
    var isActive: Bool { status == "active" }
}

/// Vehicle year options for picker
struct VehicleYears {
    static let years: [String] = {
        let currentYear = Calendar.current.component(.year, from: Date())
        return (1996...currentYear + 1).reversed().map { String($0) }
    }()
}
