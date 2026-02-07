//
//  OBDService.swift
//  MintCheck
//
//  OBD-II WiFi communication service
//

import Foundation
import Combine
import Network

/// Service for communicating with OBD-II WiFi adapters
class OBDService: ObservableObject {
    @Published var connectionState: OBDConnectionState = .disconnected
    @Published var scanProgress: Double = 0
    @Published var currentStatus: String = ""
    @Published var scanResults: OBDScanResults?
    
    private var connection: NWConnection?
    private let host: NWEndpoint.Host = "192.168.0.10"
    private let port: NWEndpoint.Port = 35000
    private let queue = DispatchQueue(label: "com.mintcheck.obd")
    
    // MARK: - Connection
    
    /// Connect to OBD-II WiFi adapter
    func connect() async throws {
        await MainActor.run {
            connectionState = .connecting
            currentStatus = "Connecting to scanner..."
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let parameters = NWParameters.tcp
            connection = NWConnection(host: host, port: port, using: parameters)
            
            connection?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.connectionState = .connected
                        self?.currentStatus = "Connected"
                        continuation.resume()
                    case .failed(let error):
                        self?.connectionState = .error
                        self?.currentStatus = "Connection failed"
                        continuation.resume(throwing: OBDError.connectionFailed(error.localizedDescription))
                    case .cancelled:
                        self?.connectionState = .disconnected
                    default:
                        break
                    }
                }
            }
            
            connection?.start(queue: queue)
            
            // Timeout after 10 seconds
            queue.asyncAfter(deadline: .now() + 10) { [weak self] in
                if self?.connectionState == .connecting {
                    self?.connection?.cancel()
                    continuation.resume(throwing: OBDError.timeout)
                }
            }
        }
    }
    
    /// Disconnect from OBD-II adapter
    func disconnect() {
        connection?.cancel()
        connection = nil
        connectionState = .disconnected
        currentStatus = "Disconnected"
    }
    
    // MARK: - Scanning
    
    /// Perform full vehicle scan
    func performScan() async throws -> OBDScanResults {
        guard connectionState == .connected else {
            throw OBDError.notConnected
        }
        
        var results = OBDScanResults()
        
        await MainActor.run {
            scanProgress = 0
            currentStatus = "Initializing scanner..."
        }
        
        // Initialize ELM327
        try await initializeDevice()
        await updateProgress(0.1, status: "Reading vehicle data...")
        
        // Get VIN
        if let vin = try? await queryVIN() {
            results.vin = vin
        }
        await updateProgress(0.2, status: "Checking for trouble codes...")
        
        // Get DTCs
        results.dtcs = try await queryDTCs()
        await updateProgress(0.3, status: "Reading engine data...")
        
        // Engine data
        results.rpm = try? await queryPID(.rpm)
        results.engineLoad = try? await queryPID(.engineLoad)
        results.coolantTemp = try? await queryPID(.coolantTemp)
        results.intakeTemp = try? await queryPID(.intakeAirTemp)
        results.timingAdvance = try? await queryPID(.timingAdvance)
        await updateProgress(0.5, status: "Checking fuel system...")
        
        // Fuel system
        results.fuelLevel = try? await queryPID(.fuelLevel)
        results.shortTermFuelTrim = try? await queryPID(.shortTermFuelTrimB1)
        results.longTermFuelTrim = try? await queryPID(.longTermFuelTrimB1)
        results.barometricPressure = try? await queryPID(.barometricPressure)
        await updateProgress(0.7, status: "Reading electrical systems...")
        
        // Electrical
        results.batteryVoltage = try? await queryPID(.batteryVoltage)
        results.throttlePosition = try? await queryPID(.throttlePosition)
        await updateProgress(0.85, status: "Getting maintenance info...")
        
        // Maintenance
        results.distanceSinceCleared = try? await queryPID(.distanceSinceCleared)
        results.warmupsSinceCleared = try? await queryPIDInt(.warmupsSinceCleared)
        results.fuelType = try? await queryFuelType()
        results.obdStandard = try? await queryOBDStandard()
        
        await updateProgress(1.0, status: "Scan complete!")
        
        await MainActor.run {
            self.scanResults = results
        }
        
        return results
    }
    
    // MARK: - Commands
    
    /// Initialize ELM327 device
    private func initializeDevice() async throws {
        _ = try await sendCommand("ATZ", delay: 1.5)      // Reset
        _ = try await sendCommand("ATE0", delay: 0.3)     // Echo off
        _ = try await sendCommand("ATL0", delay: 0.3)     // Linefeeds off
        _ = try await sendCommand("ATS1", delay: 0.3)     // Spaces on
        _ = try await sendCommand("ATH0", delay: 0.3)     // Headers off
        _ = try await sendCommand("ATSP0", delay: 1.0)    // Auto protocol
        _ = try await sendCommand("0100", delay: 2.0)     // Trigger protocol detection
    }
    
    /// Query VIN from vehicle
    private func queryVIN() async throws -> String? {
        let response = try await sendCommand("0902", delay: 2.0)
        return parseVIN(response)
    }
    
    /// Query diagnostic trouble codes
    private func queryDTCs() async throws -> [String] {
        let response = try await sendCommand("03", delay: 1.0)
        return parseDTCs(response)
    }
    
    /// Query a PID and return double value
    private func queryPID(_ pid: OBDPID) async throws -> Double? {
        let response = try await sendCommand(pid.rawValue, delay: 0.7)
        return parsePIDValue(pid, response: response)
    }
    
    /// Query a PID and return int value
    private func queryPIDInt(_ pid: OBDPID) async throws -> Int? {
        guard let value = try await queryPID(pid) else { return nil }
        return Int(value)
    }
    
    /// Query fuel type
    private func queryFuelType() async throws -> String? {
        let response = try await sendCommand("0151", delay: 0.7)
        return parseFuelType(response)
    }
    
    /// Query OBD standard
    private func queryOBDStandard() async throws -> String? {
        let response = try await sendCommand("011C", delay: 0.7)
        return parseOBDStandard(response)
    }
    
    // MARK: - Communication
    
    /// Send command and receive response
    private func sendCommand(_ command: String, delay: TimeInterval) async throws -> String {
        guard let connection = connection else {
            throw OBDError.notConnected
        }
        
        let commandData = (command + "\r").data(using: .ascii)!
        
        return try await withCheckedThrowingContinuation { continuation in
            connection.send(content: commandData, completion: .contentProcessed { error in
                if let error = error {
                    continuation.resume(throwing: OBDError.sendFailed(error.localizedDescription))
                    return
                }
                
                // Wait for response
                self.queue.asyncAfter(deadline: .now() + delay) {
                    connection.receive(minimumIncompleteLength: 1, maximumLength: 4096) { data, _, _, error in
                        if let error = error {
                            continuation.resume(throwing: OBDError.receiveFailed(error.localizedDescription))
                            return
                        }
                        
                        if let data = data, let response = String(data: data, encoding: .ascii) {
                            continuation.resume(returning: response)
                        } else {
                            continuation.resume(returning: "")
                        }
                    }
                }
            })
        }
    }
    
    // MARK: - Parsing
    
    /// Parse VIN from response
    private func parseVIN(_ response: String) -> String? {
        let clean = response.replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespaces)
        
        var vinChars: [Character] = []
        let parts = clean.split(separator: " ")
        
        var inVIN = false
        var skip = 0
        
        for (i, part) in parts.enumerated() {
            if skip > 0 {
                skip -= 1
                continue
            }
            
            if part == "49" && i + 1 < parts.count && parts[i + 1] == "02" {
                inVIN = true
                skip = 2
                continue
            }
            
            if inVIN {
                if let val = Int(part, radix: 16), val >= 48 && val <= 90 {
                    if (val >= 48 && val <= 57) || (val >= 65 && val <= 90) {
                        vinChars.append(Character(UnicodeScalar(val)!))
                    }
                }
            }
        }
        
        if vinChars.count >= 17 {
            return String(vinChars.prefix(17))
        }
        return nil
    }
    
    /// Parse DTCs from response
    private func parseDTCs(_ response: String) -> [String] {
        let clean = response.replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .uppercased()
        
        // Check for "no codes" response (43 00)
        if clean.contains("4300") || clean == "43" {
            return []
        }
        
        // Find 43 prefix (Mode 03 response)
        guard let start = clean.range(of: "43")?.upperBound else {
            return []
        }
        
        let dataHex = String(clean[start...])
        var dtcs: [String] = []
        var index = dataHex.startIndex
        
        while index < dataHex.endIndex {
            guard let nextIndex = dataHex.index(index, offsetBy: 4, limitedBy: dataHex.endIndex) else {
                break
            }
            
            let dtcHex = String(dataHex[index..<nextIndex])
            if dtcHex.count == 4,
               let byte1 = UInt8(String(dtcHex.prefix(2)), radix: 16),
               let byte2 = UInt8(String(dtcHex.suffix(2)), radix: 16) {
                
                // Skip "0000" (no code)
                if byte1 == 0 && byte2 == 0 {
                    index = nextIndex
                    continue
                }
                
                let typeBits = (byte1 >> 6) & 0x03
                let firstDigit = byte1 & 0x3F
                
                let typeChar: String
                switch typeBits {
                case 0: typeChar = "P" // Powertrain
                case 1: typeChar = "C" // Chassis
                case 2: typeChar = "B" // Body
                case 3: typeChar = "U" // Network
                default: typeChar = "?"
                }
                
                let dtc = String(format: "%@%X%02X", typeChar, firstDigit, byte2)
                dtcs.append(dtc)
            }
            
            index = nextIndex
        }
        
        return dtcs
    }
    
    /// Parse PID value based on formula
    private func parsePIDValue(_ pid: OBDPID, response: String) -> Double? {
        let bytes = parseHexBytes(response)
        guard bytes.count >= 3, bytes[0] == 0x41 else { return nil }
        
        switch pid {
        case .rpm:
            guard bytes.count >= 4 else { return nil }
            return Double((Int(bytes[2]) * 256) + Int(bytes[3])) / 4.0
        
        case .vehicleSpeed:
            return Double(bytes[2])
        
        case .coolantTemp, .intakeAirTemp, .ambientAirTemp:
            return Double(bytes[2]) - 40.0
        
        case .engineLoad, .throttlePosition, .relativeThrottlePos, .fuelLevel:
            return Double(bytes[2]) * 100.0 / 255.0
        
        case .shortTermFuelTrimB1, .longTermFuelTrimB1:
            return (Double(bytes[2]) - 128.0) * 100.0 / 128.0
        
        case .timingAdvance:
            return Double(bytes[2]) / 2.0 - 64.0
        
        case .batteryVoltage:
            guard bytes.count >= 4 else { return nil }
            return Double((Int(bytes[2]) * 256) + Int(bytes[3])) / 1000.0
        
        case .distanceSinceCleared, .distanceWithMIL, .engineRunTime:
            guard bytes.count >= 4 else { return nil }
            return Double((Int(bytes[2]) * 256) + Int(bytes[3]))
        
        case .warmupsSinceCleared:
            return Double(bytes[2])
        
        case .barometricPressure, .intakePressure:
            return Double(bytes[2])
        
        case .mafAirFlow:
            guard bytes.count >= 4 else { return nil }
            return Double((Int(bytes[2]) * 256) + Int(bytes[3])) / 100.0
        
        default:
            return nil
        }
    }
    
    /// Parse fuel type from response
    private func parseFuelType(_ response: String) -> String? {
        let bytes = parseHexBytes(response)
        guard bytes.count >= 3, bytes[0] == 0x41 else { return nil }
        
        let fuelTypes: [UInt8: String] = [
            0: "Not Available",
            1: "Gasoline",
            2: "Methanol",
            3: "Ethanol",
            4: "Diesel",
            5: "LPG",
            6: "CNG",
            8: "Electric",
            17: "Hybrid Gasoline",
            18: "Hybrid Ethanol",
            19: "Hybrid Diesel",
            20: "Hybrid Electric"
        ]
        
        return fuelTypes[bytes[2]]
    }
    
    /// Parse OBD standard from response
    private func parseOBDStandard(_ response: String) -> String? {
        let bytes = parseHexBytes(response)
        guard bytes.count >= 3, bytes[0] == 0x41 else { return nil }
        
        let standards: [UInt8: String] = [
            1: "OBD-II CARB",
            2: "OBD EPA",
            3: "OBD + OBD-II",
            6: "EOBD",
            7: "EOBD + OBD-II"
        ]
        
        return standards[bytes[2]]
    }
    
    /// Extract hex bytes from response
    private func parseHexBytes(_ response: String) -> [UInt8] {
        let clean = response.replacingOccurrences(of: ">", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "\r", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .uppercased()
        
        // Find response marker (41 for Mode 01)
        var hex = clean
        if let range = clean.range(of: "41") {
            hex = String(clean[range.lowerBound...])
        }
        
        var bytes: [UInt8] = []
        var index = hex.startIndex
        
        while index < hex.endIndex {
            guard let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) else {
                break
            }
            
            let byteString = String(hex[index..<nextIndex])
            if let byte = UInt8(byteString, radix: 16) {
                bytes.append(byte)
            }
            
            index = nextIndex
        }
        
        return bytes
    }
    
    // MARK: - Helpers
    
    @MainActor
    private func updateProgress(_ progress: Double, status: String) {
        self.scanProgress = progress
        self.currentStatus = status
    }
    
    // MARK: - Simulated Scan (for testing without device)
    
    /// Perform a simulated scan for development/testing
    func simulateScan() async -> OBDScanResults {
        var results = OBDScanResults()
        
        await MainActor.run {
            connectionState = .scanning
            scanProgress = 0
            currentStatus = "Initializing scanner..."
        }
        
        // Simulate scan progress
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(0.1, status: "Reading vehicle data...")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(0.2, status: "Checking for trouble codes...")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(0.3, status: "Reading engine data...")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(0.5, status: "Checking fuel system...")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(0.7, status: "Reading electrical systems...")
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(0.85, status: "Getting maintenance info...")
        
        // Generate simulated results (healthy car)
        results.vin = "1HGBH41JXMN109186"
        results.dtcs = []  // No trouble codes
        results.rpm = 750
        results.engineLoad = 22.5
        results.coolantTemp = 88  // Normal operating temp
        results.intakeTemp = 35
        results.fuelLevel = 65
        results.shortTermFuelTrim = 1.5
        results.longTermFuelTrim = -0.8
        results.batteryVoltage = 14.2  // Good charging
        results.throttlePosition = 15
        results.distanceSinceCleared = 5280
        results.warmupsSinceCleared = 145
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        
        try? await Task.sleep(nanoseconds: 500_000_000)
        await updateProgress(1.0, status: "Scan complete!")
        
        await MainActor.run {
            self.scanResults = results
            self.connectionState = .connected
        }
        
        return results
    }
}

// MARK: - Connection State
enum OBDConnectionState {
    case disconnected
    case connecting
    case connected
    case scanning
    case error
}

// MARK: - OBD Errors
enum OBDError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case timeout
    case sendFailed(String)
    case receiveFailed(String)
    case invalidResponse
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "Not connected to OBD scanner."
        case .connectionFailed(let reason):
            return "Connection failed: \(reason)"
        case .timeout:
            return "Connection timed out. Make sure the scanner is powered on."
        case .sendFailed(let reason):
            return "Failed to send command: \(reason)"
        case .receiveFailed(let reason):
            return "Failed to receive response: \(reason)"
        case .invalidResponse:
            return "Invalid response from scanner."
        }
    }
}
