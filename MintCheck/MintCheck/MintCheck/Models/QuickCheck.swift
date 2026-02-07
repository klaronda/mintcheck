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
    var odometerReading: Int? = nil
    var askingPrice: Int? = nil
    
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
            bodyDamage: bodyDamage,
            odometerReading: odometerReading,
            askingPrice: askingPrice
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
        case .oil: return "icon-oil"
        case .checkEngine: return "icon-check-engine"
        case .tirePressure: return "icon-tire-pressure"
        case .washerFluid: return "icon-washer-fluid"
        case .abs: return "icon-abs"
        case .radiator: return "icon-radiator"
        case .battery: return "icon-battery"
        case .airbag: return "icon-airbag"
        case .other: return "icon-other"
        }
    }
    
    /// Icon size - oil is 20% bigger than others
    var iconSize: CGFloat {
        switch self {
        case .oil: return 38  // 32 * 1.2 = 38.4
        default: return 32
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
