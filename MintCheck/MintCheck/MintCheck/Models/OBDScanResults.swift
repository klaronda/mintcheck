//
//  OBDScanResults.swift
//  MintCheck
//
//  OBD-II scan results from vehicle
//

import Foundation

/// Results from OBD-II scan
struct OBDScanResults: Codable {
    // Vehicle identification
    var vin: String?
    var fuelType: String?
    var obdStandard: String?
    
    // Diagnostic trouble codes
    var dtcs: [String] = []
    var hasDTCs: Bool { !dtcs.isEmpty }
    
    // Engine data
    var rpm: Double?
    var engineLoad: Double?
    var coolantTemp: Double?
    var intakeTemp: Double?
    var timingAdvance: Double?
    var mafAirFlow: Double?
    var intakePressure: Double?
    
    // Fuel system
    var fuelLevel: Double?
    var fuelSystemStatus: String?
    var shortTermFuelTrim: Double?
    var longTermFuelTrim: Double?
    var barometricPressure: Double?
    
    // Electrical
    var batteryVoltage: Double?
    var throttlePosition: Double?
    var relativeThrottlePos: Double?
    
    // Environmental
    var ambientAirTemp: Double?
    var vehicleSpeed: Double?
    
    // Maintenance
    var distanceWithMIL: Double?
    var distanceSinceCleared: Double?
    var warmupsSinceCleared: Int?
    var timeWithMIL: Double?
    var timeSinceCleared: Double?
    var engineRunTime: Double?
    
    // Scan metadata
    var scanTime: Date = Date()
    var deviceType: String?
    var protocol_: String?
    
    /// Convert to JSON for storage
    func toJSON() -> OBDDataJSON {
        OBDDataJSON(
            vin: vin,
            dtcs: dtcs,
            rpm: rpm,
            coolantTemp: coolantTemp,
            batteryVoltage: batteryVoltage,
            fuelLevel: fuelLevel,
            engineLoad: engineLoad,
            intakeTemp: intakeTemp,
            throttlePosition: throttlePosition,
            vehicleSpeed: vehicleSpeed,
            distanceSinceCleared: distanceSinceCleared,
            warmupCycles: warmupsSinceCleared,
            fuelType: fuelType,
            obdStandard: obdStandard
        )
    }
}

// MARK: - Health Assessment Helpers
extension OBDScanResults {
    /// Check if battery voltage indicates alternator issue
    var hasAlternatorIssue: Bool {
        guard let voltage = batteryVoltage else { return false }
        // With engine running, voltage should be 13.5-14.5V
        return voltage < 13.0
    }
    
    /// Check if coolant temp indicates overheating
    var isOverheating: Bool {
        guard let temp = coolantTemp else { return false }
        return temp > 105 // °C
    }
    
    /// Check if fuel trims are out of range
    var hasFuelTrimIssue: Bool {
        let threshold = 10.0 // ±10%
        if let st = shortTermFuelTrim, abs(st) > threshold { return true }
        if let lt = longTermFuelTrim, abs(lt) > threshold { return true }
        return false
    }
    
    /// Check if codes were recently cleared (suspicious)
    var recentlyCleared: Bool {
        if let distance = distanceSinceCleared, distance < 50 {
            return true
        }
        if let warmups = warmupsSinceCleared, warmups < 5 {
            return true
        }
        return false
    }
    
    /// Generate key findings list
    var keyFindings: [String] {
        var findings: [String] = []
        
        // DTCs
        if hasDTCs {
            findings.append("⚠️ \(dtcs.count) trouble code(s) found")
        } else {
            findings.append("✅ No trouble codes found")
        }
        
        // Coolant
        if isOverheating {
            findings.append("⚠️ Engine temperature high (\(Int(coolantTemp ?? 0))°C)")
        } else if coolantTemp != nil {
            findings.append("✅ Engine temperature normal")
        }
        
        // Battery
        if hasAlternatorIssue {
            findings.append("⚠️ Low battery voltage (\(String(format: "%.1f", batteryVoltage ?? 0))V)")
        } else if batteryVoltage != nil {
            findings.append("✅ Battery/charging system healthy")
        }
        
        // Fuel trims
        if hasFuelTrimIssue {
            findings.append("⚠️ Fuel system compensating abnormally")
        }
        
        // Recently cleared
        if recentlyCleared {
            findings.append("⚠️ Diagnostic data recently cleared")
        }
        
        return findings
    }
}

// MARK: - PID Definitions
/// OBD-II PID codes and their formulas
enum OBDPID: String, CaseIterable {
    case supportedPIDs = "0100"
    case monitorStatus = "0101"
    case fuelSystemStatus = "0103"
    case engineLoad = "0104"
    case coolantTemp = "0105"
    case shortTermFuelTrimB1 = "0106"
    case longTermFuelTrimB1 = "0107"
    case fuelPressure = "010A"
    case intakePressure = "010B"
    case rpm = "010C"
    case vehicleSpeed = "010D"
    case timingAdvance = "010E"
    case intakeAirTemp = "010F"
    case mafAirFlow = "0110"
    case throttlePosition = "0111"
    case obdStandard = "011C"
    case engineRunTime = "011F"
    case distanceWithMIL = "0121"
    case fuelLevel = "012F"
    case warmupsSinceCleared = "0130"
    case distanceSinceCleared = "0131"
    case barometricPressure = "0133"
    case batteryVoltage = "0142"
    case relativeThrottlePos = "0145"
    case ambientAirTemp = "0146"
    case timeWithMIL = "014D"
    case timeSinceCleared = "014E"
    case fuelType = "0151"
    case dtc = "03"
    case vin = "0902"
    
    var name: String {
        switch self {
        case .supportedPIDs: return "Supported PIDs"
        case .monitorStatus: return "Monitor Status"
        case .fuelSystemStatus: return "Fuel System Status"
        case .engineLoad: return "Engine Load"
        case .coolantTemp: return "Coolant Temperature"
        case .shortTermFuelTrimB1: return "Short Term Fuel Trim B1"
        case .longTermFuelTrimB1: return "Long Term Fuel Trim B1"
        case .fuelPressure: return "Fuel Pressure"
        case .intakePressure: return "Intake Manifold Pressure"
        case .rpm: return "Engine RPM"
        case .vehicleSpeed: return "Vehicle Speed"
        case .timingAdvance: return "Timing Advance"
        case .intakeAirTemp: return "Intake Air Temperature"
        case .mafAirFlow: return "MAF Air Flow"
        case .throttlePosition: return "Throttle Position"
        case .obdStandard: return "OBD Standard"
        case .engineRunTime: return "Engine Run Time"
        case .distanceWithMIL: return "Distance with MIL On"
        case .fuelLevel: return "Fuel Level"
        case .warmupsSinceCleared: return "Warmups Since Cleared"
        case .distanceSinceCleared: return "Distance Since Cleared"
        case .barometricPressure: return "Barometric Pressure"
        case .batteryVoltage: return "Battery Voltage"
        case .relativeThrottlePos: return "Relative Throttle Position"
        case .ambientAirTemp: return "Ambient Air Temperature"
        case .timeWithMIL: return "Time with MIL On"
        case .timeSinceCleared: return "Time Since Cleared"
        case .fuelType: return "Fuel Type"
        case .dtc: return "Diagnostic Trouble Codes"
        case .vin: return "Vehicle Identification Number"
        }
    }
}
