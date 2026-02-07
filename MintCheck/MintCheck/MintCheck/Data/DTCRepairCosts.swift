//
//  DTCRepairCosts.swift
//  MintCheck
//
//  DTC (Diagnostic Trouble Code) to repair cost mapping
//

import Foundation

/// Maps common DTCs to estimated repair cost ranges
struct DTCRepairCosts {
    
    /// Repair cost estimate with description
    struct RepairEstimate {
        let lowCost: Int
        let highCost: Int
        let description: String
        let severity: Severity
        
        enum Severity: String {
            case minor = "Minor"
            case moderate = "Moderate"
            case major = "Major"
            case critical = "Critical"
        }
        
        /// Average cost for valuation deduction
        var averageCost: Int {
            return (lowCost + highCost) / 2
        }
    }
    
    // MARK: - Common DTC Repair Costs
    
    /// Dictionary of common DTCs with their repair estimates
    /// Organized by category: P = Powertrain, B = Body, C = Chassis, U = Network
    static let costs: [String: RepairEstimate] = [
        // MARK: - Engine Misfires (P030x)
        "P0300": RepairEstimate(lowCost: 500, highCost: 1500, description: "Random/multiple cylinder misfire - could be spark plugs, coils, fuel injectors, or major engine issue", severity: .moderate),
        "P0301": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 1 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0302": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 2 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0303": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 3 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0304": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 4 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0305": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 5 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0306": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 6 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0307": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 7 misfire - likely spark plug or ignition coil", severity: .minor),
        "P0308": RepairEstimate(lowCost: 200, highCost: 800, description: "Cylinder 8 misfire - likely spark plug or ignition coil", severity: .minor),
        
        // MARK: - Fuel System (P017x)
        "P0171": RepairEstimate(lowCost: 100, highCost: 500, description: "System too lean (Bank 1) - vacuum leak, MAF sensor, or fuel pressure issue", severity: .minor),
        "P0172": RepairEstimate(lowCost: 100, highCost: 500, description: "System too rich (Bank 1) - fuel injector or oxygen sensor issue", severity: .minor),
        "P0174": RepairEstimate(lowCost: 100, highCost: 500, description: "System too lean (Bank 2) - vacuum leak, MAF sensor, or fuel pressure issue", severity: .minor),
        "P0175": RepairEstimate(lowCost: 100, highCost: 500, description: "System too rich (Bank 2) - fuel injector or oxygen sensor issue", severity: .minor),
        
        // MARK: - Oxygen Sensors (P013x, P015x)
        "P0130": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor circuit malfunction (Bank 1, Sensor 1)", severity: .minor),
        "P0131": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor low voltage (Bank 1, Sensor 1)", severity: .minor),
        "P0132": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor high voltage (Bank 1, Sensor 1)", severity: .minor),
        "P0133": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor slow response (Bank 1, Sensor 1)", severity: .minor),
        "P0134": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor no activity detected (Bank 1, Sensor 1)", severity: .minor),
        "P0135": RepairEstimate(lowCost: 150, highCost: 350, description: "O2 sensor heater circuit malfunction (Bank 1, Sensor 1)", severity: .minor),
        "P0136": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor circuit malfunction (Bank 1, Sensor 2)", severity: .minor),
        "P0141": RepairEstimate(lowCost: 150, highCost: 350, description: "O2 sensor heater circuit malfunction (Bank 1, Sensor 2)", severity: .minor),
        "P0150": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor circuit malfunction (Bank 2, Sensor 1)", severity: .minor),
        "P0155": RepairEstimate(lowCost: 150, highCost: 350, description: "O2 sensor heater circuit malfunction (Bank 2, Sensor 1)", severity: .minor),
        "P0156": RepairEstimate(lowCost: 200, highCost: 400, description: "O2 sensor circuit malfunction (Bank 2, Sensor 2)", severity: .minor),
        "P0161": RepairEstimate(lowCost: 150, highCost: 350, description: "O2 sensor heater circuit malfunction (Bank 2, Sensor 2)", severity: .minor),
        
        // MARK: - Catalytic Converter (P042x, P043x)
        "P0420": RepairEstimate(lowCost: 500, highCost: 2500, description: "Catalytic converter efficiency below threshold (Bank 1) - may need replacement", severity: .major),
        "P0421": RepairEstimate(lowCost: 500, highCost: 2500, description: "Warm up catalytic converter efficiency below threshold (Bank 1)", severity: .major),
        "P0430": RepairEstimate(lowCost: 500, highCost: 2500, description: "Catalytic converter efficiency below threshold (Bank 2) - may need replacement", severity: .major),
        "P0431": RepairEstimate(lowCost: 500, highCost: 2500, description: "Warm up catalytic converter efficiency below threshold (Bank 2)", severity: .major),
        
        // MARK: - EVAP System (P044x, P045x, P046x)
        "P0440": RepairEstimate(lowCost: 100, highCost: 600, description: "EVAP system malfunction - could be gas cap, purge valve, or vent valve", severity: .minor),
        "P0441": RepairEstimate(lowCost: 100, highCost: 500, description: "EVAP system incorrect purge flow", severity: .minor),
        "P0442": RepairEstimate(lowCost: 100, highCost: 400, description: "EVAP system small leak detected - often gas cap or hose", severity: .minor),
        "P0443": RepairEstimate(lowCost: 150, highCost: 400, description: "EVAP purge control valve circuit malfunction", severity: .minor),
        "P0446": RepairEstimate(lowCost: 150, highCost: 500, description: "EVAP vent control circuit malfunction", severity: .minor),
        "P0455": RepairEstimate(lowCost: 50, highCost: 300, description: "EVAP system large leak detected - often loose gas cap", severity: .minor),
        "P0456": RepairEstimate(lowCost: 50, highCost: 300, description: "EVAP system very small leak detected", severity: .minor),
        
        // MARK: - Thermostat/Cooling (P0125, P0128)
        "P0125": RepairEstimate(lowCost: 150, highCost: 400, description: "Insufficient coolant temperature for closed loop fuel control", severity: .minor),
        "P0128": RepairEstimate(lowCost: 150, highCost: 400, description: "Coolant thermostat below regulating temperature - stuck open thermostat", severity: .minor),
        
        // MARK: - MAF Sensor (P0100-P0104)
        "P0100": RepairEstimate(lowCost: 150, highCost: 400, description: "Mass air flow (MAF) sensor circuit malfunction", severity: .minor),
        "P0101": RepairEstimate(lowCost: 150, highCost: 400, description: "MAF sensor range/performance problem - may need cleaning or replacement", severity: .minor),
        "P0102": RepairEstimate(lowCost: 150, highCost: 400, description: "MAF sensor low input", severity: .minor),
        "P0103": RepairEstimate(lowCost: 150, highCost: 400, description: "MAF sensor high input", severity: .minor),
        "P0104": RepairEstimate(lowCost: 150, highCost: 400, description: "MAF sensor intermittent", severity: .minor),
        
        // MARK: - Throttle Position (P012x)
        "P0120": RepairEstimate(lowCost: 200, highCost: 600, description: "Throttle position sensor circuit malfunction", severity: .moderate),
        "P0121": RepairEstimate(lowCost: 200, highCost: 600, description: "Throttle position sensor range/performance problem", severity: .moderate),
        "P0122": RepairEstimate(lowCost: 200, highCost: 600, description: "Throttle position sensor low input", severity: .moderate),
        "P0123": RepairEstimate(lowCost: 200, highCost: 600, description: "Throttle position sensor high input", severity: .moderate),
        
        // MARK: - Camshaft/Crankshaft Position (P034x, P033x)
        "P0335": RepairEstimate(lowCost: 150, highCost: 400, description: "Crankshaft position sensor A circuit malfunction", severity: .moderate),
        "P0336": RepairEstimate(lowCost: 150, highCost: 400, description: "Crankshaft position sensor A range/performance", severity: .moderate),
        "P0340": RepairEstimate(lowCost: 150, highCost: 400, description: "Camshaft position sensor circuit malfunction", severity: .moderate),
        "P0341": RepairEstimate(lowCost: 150, highCost: 400, description: "Camshaft position sensor range/performance", severity: .moderate),
        "P0345": RepairEstimate(lowCost: 150, highCost: 400, description: "Camshaft position sensor A circuit (Bank 2)", severity: .moderate),
        
        // MARK: - Variable Valve Timing (P001x, P001x)
        "P0010": RepairEstimate(lowCost: 300, highCost: 800, description: "Intake camshaft position actuator circuit (Bank 1)", severity: .moderate),
        "P0011": RepairEstimate(lowCost: 300, highCost: 800, description: "Intake camshaft position timing over-advanced (Bank 1)", severity: .moderate),
        "P0012": RepairEstimate(lowCost: 300, highCost: 800, description: "Intake camshaft position timing over-retarded (Bank 1)", severity: .moderate),
        "P0013": RepairEstimate(lowCost: 300, highCost: 800, description: "Exhaust camshaft position actuator circuit (Bank 1)", severity: .moderate),
        "P0014": RepairEstimate(lowCost: 300, highCost: 800, description: "Exhaust camshaft position timing over-advanced (Bank 1)", severity: .moderate),
        "P0020": RepairEstimate(lowCost: 300, highCost: 800, description: "Intake camshaft position actuator circuit (Bank 2)", severity: .moderate),
        "P0021": RepairEstimate(lowCost: 300, highCost: 800, description: "Intake camshaft position timing over-advanced (Bank 2)", severity: .moderate),
        "P0022": RepairEstimate(lowCost: 300, highCost: 800, description: "Intake camshaft position timing over-retarded (Bank 2)", severity: .moderate),
        
        // MARK: - EGR System (P040x)
        "P0400": RepairEstimate(lowCost: 200, highCost: 600, description: "Exhaust gas recirculation (EGR) flow malfunction", severity: .minor),
        "P0401": RepairEstimate(lowCost: 200, highCost: 600, description: "EGR insufficient flow detected - may need cleaning", severity: .minor),
        "P0402": RepairEstimate(lowCost: 200, highCost: 600, description: "EGR excessive flow detected", severity: .minor),
        "P0403": RepairEstimate(lowCost: 200, highCost: 600, description: "EGR circuit malfunction", severity: .minor),
        "P0404": RepairEstimate(lowCost: 200, highCost: 600, description: "EGR circuit range/performance", severity: .minor),
        
        // MARK: - Knock Sensor (P032x)
        "P0325": RepairEstimate(lowCost: 200, highCost: 500, description: "Knock sensor circuit malfunction (Bank 1)", severity: .moderate),
        "P0326": RepairEstimate(lowCost: 200, highCost: 500, description: "Knock sensor range/performance (Bank 1)", severity: .moderate),
        "P0327": RepairEstimate(lowCost: 200, highCost: 500, description: "Knock sensor low input (Bank 1)", severity: .moderate),
        "P0328": RepairEstimate(lowCost: 200, highCost: 500, description: "Knock sensor high input (Bank 1)", severity: .moderate),
        "P0330": RepairEstimate(lowCost: 200, highCost: 500, description: "Knock sensor circuit malfunction (Bank 2)", severity: .moderate),
        
        // MARK: - Ignition System (P035x)
        "P0350": RepairEstimate(lowCost: 150, highCost: 400, description: "Ignition coil primary/secondary circuit malfunction", severity: .minor),
        "P0351": RepairEstimate(lowCost: 150, highCost: 400, description: "Ignition coil A primary/secondary circuit malfunction", severity: .minor),
        "P0352": RepairEstimate(lowCost: 150, highCost: 400, description: "Ignition coil B primary/secondary circuit malfunction", severity: .minor),
        "P0353": RepairEstimate(lowCost: 150, highCost: 400, description: "Ignition coil C primary/secondary circuit malfunction", severity: .minor),
        "P0354": RepairEstimate(lowCost: 150, highCost: 400, description: "Ignition coil D primary/secondary circuit malfunction", severity: .minor),
        
        // MARK: - Fuel Injector (P020x)
        "P0200": RepairEstimate(lowCost: 200, highCost: 600, description: "Fuel injector circuit malfunction", severity: .moderate),
        "P0201": RepairEstimate(lowCost: 200, highCost: 500, description: "Fuel injector circuit malfunction - Cylinder 1", severity: .moderate),
        "P0202": RepairEstimate(lowCost: 200, highCost: 500, description: "Fuel injector circuit malfunction - Cylinder 2", severity: .moderate),
        "P0203": RepairEstimate(lowCost: 200, highCost: 500, description: "Fuel injector circuit malfunction - Cylinder 3", severity: .moderate),
        "P0204": RepairEstimate(lowCost: 200, highCost: 500, description: "Fuel injector circuit malfunction - Cylinder 4", severity: .moderate),
        "P0205": RepairEstimate(lowCost: 200, highCost: 500, description: "Fuel injector circuit malfunction - Cylinder 5", severity: .moderate),
        "P0206": RepairEstimate(lowCost: 200, highCost: 500, description: "Fuel injector circuit malfunction - Cylinder 6", severity: .moderate),
        
        // MARK: - Transmission (P07xx)
        "P0700": RepairEstimate(lowCost: 100, highCost: 3000, description: "Transmission control system malfunction - diagnosis needed", severity: .major),
        "P0705": RepairEstimate(lowCost: 200, highCost: 800, description: "Transmission range sensor circuit malfunction", severity: .moderate),
        "P0715": RepairEstimate(lowCost: 200, highCost: 600, description: "Input/turbine speed sensor circuit malfunction", severity: .moderate),
        "P0720": RepairEstimate(lowCost: 200, highCost: 600, description: "Output speed sensor circuit malfunction", severity: .moderate),
        "P0730": RepairEstimate(lowCost: 500, highCost: 3000, description: "Incorrect gear ratio - could indicate transmission failure", severity: .critical),
        "P0740": RepairEstimate(lowCost: 300, highCost: 1500, description: "Torque converter clutch circuit malfunction", severity: .major),
        "P0741": RepairEstimate(lowCost: 300, highCost: 1500, description: "Torque converter clutch circuit stuck off", severity: .major),
        "P0750": RepairEstimate(lowCost: 200, highCost: 1000, description: "Shift solenoid A malfunction", severity: .moderate),
        "P0755": RepairEstimate(lowCost: 200, highCost: 1000, description: "Shift solenoid B malfunction", severity: .moderate),
        "P0760": RepairEstimate(lowCost: 200, highCost: 1000, description: "Shift solenoid C malfunction", severity: .moderate),
        "P0765": RepairEstimate(lowCost: 200, highCost: 1000, description: "Shift solenoid D malfunction", severity: .moderate),
        "P0770": RepairEstimate(lowCost: 200, highCost: 1000, description: "Shift solenoid E malfunction", severity: .moderate),
        
        // MARK: - Battery/Charging (P056x)
        "P0560": RepairEstimate(lowCost: 100, highCost: 400, description: "System voltage malfunction - alternator or battery issue", severity: .minor),
        "P0562": RepairEstimate(lowCost: 100, highCost: 500, description: "System voltage low - alternator or battery issue", severity: .moderate),
        "P0563": RepairEstimate(lowCost: 100, highCost: 500, description: "System voltage high - voltage regulator issue", severity: .moderate),
        
        // MARK: - ABS System (C codes)
        "C0035": RepairEstimate(lowCost: 200, highCost: 600, description: "Left front wheel speed sensor circuit", severity: .moderate),
        "C0040": RepairEstimate(lowCost: 200, highCost: 600, description: "Right front wheel speed sensor circuit", severity: .moderate),
        "C0045": RepairEstimate(lowCost: 200, highCost: 600, description: "Left rear wheel speed sensor circuit", severity: .moderate),
        "C0050": RepairEstimate(lowCost: 200, highCost: 600, description: "Right rear wheel speed sensor circuit", severity: .moderate),
        "C0265": RepairEstimate(lowCost: 500, highCost: 1500, description: "ABS/TCS pump motor circuit malfunction", severity: .major),
        
        // MARK: - Airbag System (B codes)
        "B0001": RepairEstimate(lowCost: 200, highCost: 800, description: "Driver frontal airbag circuit", severity: .major),
        "B0002": RepairEstimate(lowCost: 200, highCost: 800, description: "Passenger frontal airbag circuit", severity: .major),
        "B0100": RepairEstimate(lowCost: 200, highCost: 600, description: "Driver frontal airbag squib circuit resistance low", severity: .major),
        
        // MARK: - Network/Communication (U codes)
        "U0100": RepairEstimate(lowCost: 100, highCost: 500, description: "Lost communication with ECM/PCM", severity: .moderate),
        "U0101": RepairEstimate(lowCost: 100, highCost: 500, description: "Lost communication with TCM", severity: .moderate),
        "U0121": RepairEstimate(lowCost: 100, highCost: 400, description: "Lost communication with ABS module", severity: .moderate),
        "U0140": RepairEstimate(lowCost: 100, highCost: 400, description: "Lost communication with body control module", severity: .moderate),
        "U0155": RepairEstimate(lowCost: 100, highCost: 400, description: "Lost communication with cluster/instrument panel", severity: .minor),
    ]
    
    // MARK: - Lookup Functions
    
    /// Get repair estimate for a specific DTC
    static func estimateCost(dtc: String) -> RepairEstimate? {
        return costs[dtc.uppercased()]
    }
    
    /// Default cost for unknown codes
    static let unknownCodeCost = RepairEstimate(
        lowCost: 200,
        highCost: 500,
        description: "Unknown diagnostic code - requires professional diagnosis",
        severity: .moderate
    )
    
    /// Calculate total repair cost for multiple DTCs
    static func totalRepairCost(dtcs: [String]) -> (low: Int, high: Int, details: [(code: String, estimate: RepairEstimate)]) {
        var totalLow = 0
        var totalHigh = 0
        var details: [(String, RepairEstimate)] = []
        
        for dtc in dtcs {
            let estimate = estimateCost(dtc: dtc) ?? unknownCodeCost
            totalLow += estimate.lowCost
            totalHigh += estimate.highCost
            details.append((dtc, estimate))
        }
        
        return (totalLow, totalHigh, details)
    }
    
    /// Get severity level for a set of DTCs (returns highest severity)
    static func overallSeverity(dtcs: [String]) -> RepairEstimate.Severity {
        var highestSeverity = RepairEstimate.Severity.minor
        
        for dtc in dtcs {
            if let estimate = estimateCost(dtc: dtc) {
                switch estimate.severity {
                case .critical:
                    return .critical
                case .major where highestSeverity != .critical:
                    highestSeverity = .major
                case .moderate where highestSeverity == .minor:
                    highestSeverity = .moderate
                default:
                    break
                }
            }
        }
        
        return highestSeverity
    }
}
