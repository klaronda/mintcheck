//
//  QuickCheck.swift
//  MintCheck
//
//  Quick visual inspection models
//

import Foundation
import SwiftUI

/// Quick visual check data collected from user
struct QuickCheckData {
    var interiorCondition: String = ""
    var tireCondition: String = ""
    var dashboardLights: Bool = false
    var warningLightTypes: [WarningLightType] = []
    var engineSounds: Bool = false
    var fluidLeaks: String? = nil
    var bodyDamage: Bool? = nil
    
    /// Check if all required questions are answered
    var isComplete: Bool {
        !interiorCondition.isEmpty &&
        !tireCondition.isEmpty &&
        (!dashboardLights || !warningLightTypes.isEmpty)
    }
    
    /// Convert to JSON for storage
    func toJSON() -> QuickCheckJSON {
        QuickCheckJSON(
            interiorCondition: interiorCondition,
            tireCondition: tireCondition,
            dashboardLights: dashboardLights,
            warningLightTypes: warningLightTypes.map { $0.rawValue },
            engineSounds: engineSounds,
            fluidLeaks: fluidLeaks,
            bodyDamage: bodyDamage
        )
    }
}

/// Warning light types that can be selected
enum WarningLightType: String, CaseIterable, Identifiable {
    case oil = "oil"
    case checkEngine = "check-engine"
    case tirePressure = "tire-pressure"
    case washerFluid = "washer-fluid"
    case abs = "abs"
    case radiator = "radiator"
    case battery = "battery"
    case airbag = "airbag"
    case other = "other"
    
    var id: String { rawValue }
    
    var label: String {
        switch self {
        case .oil: return "Oil"
        case .checkEngine: return "Check Engine"
        case .tirePressure: return "Tire Pressure"
        case .washerFluid: return "Washer Fluid"
        case .abs: return "ABS"
        case .radiator: return "Radiator"
        case .battery: return "Battery"
        case .airbag: return "AirBag"
        case .other: return "Other"
        }
    }
    
    var iconName: String {
        switch self {
        case .oil: return "drop.fill"
        case .checkEngine: return "exclamationmark.triangle.fill"
        case .tirePressure: return "wind"
        case .washerFluid: return "drop.triangle.fill"
        case .abs: return "circlebadge.fill"
        case .radiator: return "thermometer"
        case .battery: return "battery.100"
        case .airbag: return "shield.fill"
        case .other: return "ellipsis"
        }
    }
}

/// Condition options for visual checks
enum ConditionOption: String, CaseIterable {
    case good = "Good"
    case worn = "Worn"
    case poor = "Poor"
    case bare = "Bare"
}
