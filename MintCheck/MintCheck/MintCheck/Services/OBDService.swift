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
    @Published var scanState: ScanState = .idle
    
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
            let resumeLock = NSLock()
            var didResume = false
            func resumeOnce(_ action: () -> Void) {
                resumeLock.lock()
                defer { resumeLock.unlock() }
                guard !didResume else { return }
                didResume = true
                action()
            }

            let parameters = NWParameters.tcp
            connection = NWConnection(host: host, port: port, using: parameters)
            
            connection?.stateUpdateHandler = { [weak self] state in
                Task { @MainActor in
                    switch state {
                    case .ready:
                        self?.connectionState = .connected
                        self?.currentStatus = "Connected"
                        resumeOnce {
                            continuation.resume()
                        }
                    case .failed(let error):
                        self?.connectionState = .error
                        self?.currentStatus = "Connection failed"
                        resumeOnce {
                            continuation.resume(throwing: OBDError.connectionFailed(error.localizedDescription))
                        }
                    case .cancelled:
                        self?.connectionState = .disconnected
                        resumeOnce {
                            continuation.resume(throwing: OBDError.connectionFailed("Connection cancelled."))
                        }
                    default:
                        break
                    }
                }
            }
            
            connection?.start(queue: queue)
            
            // Timeout after 10 seconds
            queue.asyncAfter(deadline: .now() + 10) { [weak self] in
                resumeOnce {
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
    
    /// Attempt reconnection (disconnect then connect). Returns true if connected.
    private func attemptReconnect() async -> Bool {
        disconnect()
        try? await Task.sleep(nanoseconds: 1_000_000_000)  // 1 second
        do {
            try await connect()
            return connectionState == .connected
        } catch {
            return false
        }
    }
    
    /// Perform full vehicle scan with mid-scan drop recovery (3 attempts over ~20s).
    func performScan() async throws -> OBDScanResults {
        guard connectionState == .connected else {
            throw OBDError.notConnected
        }
        
        await MainActor.run { scanState = .scanning }
        defer { Task { @MainActor in scanState = .idle } }
        
        let maxReconnectAttempts = 3
        let delayBetweenAttempts: UInt64 = 6_000_000_000  // 6s (~18s total for 3 attempts)
        
        func runScan() async throws -> OBDScanResults {
            var results = OBDScanResults()
            
            await MainActor.run {
                scanProgress = 0
                currentStatus = "Initializing scanner..."
            }
            
            try await initializeDevice()
            await updateProgress(0.1, status: "Reading vehicle data...")
            
            if let vin = try? await queryVIN() { results.vin = vin }
            await updateProgress(0.2, status: "Checking for trouble codes...")
            
            results.dtcs = try await queryDTCs()
            await updateProgress(0.3, status: "Reading engine data...")
            
            results.rpm = try? await queryPID(.rpm)
            results.engineLoad = try? await queryPID(.engineLoad)
            results.coolantTemp = try? await queryPID(.coolantTemp)
            results.intakeTemp = try? await queryPID(.intakeAirTemp)
            results.timingAdvance = try? await queryPID(.timingAdvance)
            if results.rpm == nil && results.coolantTemp == nil {
                try? await Task.sleep(nanoseconds: 400_000_000)
                results.rpm = try? await queryPID(.rpm)
                results.coolantTemp = try? await queryPID(.coolantTemp)
            }
            await updateProgress(0.5, status: "Checking fuel system...")
            
            results.fuelLevel = try? await queryPID(.fuelLevel)
            results.shortTermFuelTrim = try? await queryPID(.shortTermFuelTrimB1)
            results.longTermFuelTrim = try? await queryPID(.longTermFuelTrimB1)
            results.barometricPressure = try? await queryPID(.barometricPressure)
            if results.fuelLevel == nil && results.shortTermFuelTrim == nil && results.longTermFuelTrim == nil {
                try? await Task.sleep(nanoseconds: 400_000_000)
                results.fuelLevel = try? await queryPID(.fuelLevel)
                results.shortTermFuelTrim = try? await queryPID(.shortTermFuelTrimB1)
                results.longTermFuelTrim = try? await queryPID(.longTermFuelTrimB1)
            }
            if results.barometricPressure == nil {
                try? await Task.sleep(nanoseconds: 300_000_000)
                results.barometricPressure = try? await queryPID(.barometricPressure)
            }
            await updateProgress(0.7, status: "Reading electrical systems...")
            
            results.batteryVoltage = try? await queryPID(.batteryVoltage)
            if results.batteryVoltage == nil {
                try? await Task.sleep(nanoseconds: 400_000_000)
                results.batteryVoltage = try? await queryPID(.batteryVoltage)
            }
            results.throttlePosition = try? await queryPID(.throttlePosition)
            await updateProgress(0.85, status: "Getting maintenance info...")
            
            results.distanceSinceCleared = try? await queryPID(.distanceSinceCleared)
            results.warmupsSinceCleared = try? await queryPIDInt(.warmupsSinceCleared)
            results.fuelType = try? await queryFuelType()
            results.obdStandard = try? await queryOBDStandard()
            
            await updateProgress(1.0, status: "Scan complete!")
            await MainActor.run { self.scanResults = results }
            return results
        }
        
        for attempt in 1...maxReconnectAttempts {
            do {
                return try await runScan()
            } catch {
                if attempt < maxReconnectAttempts {
                    await MainActor.run { currentStatus = "Connection lost. Reconnecting… (\(attempt)/\(maxReconnectAttempts))" }
                    let reconnected = await attemptReconnect()
                    if reconnected {
                        try? await Task.sleep(nanoseconds: 500_000_000)
                        continue
                    }
                }
                try? await Task.sleep(nanoseconds: delayBetweenAttempts)
            }
        }
        
        await MainActor.run { scanState = .interrupted }
        ErrorEventLogger.shared.log(screen: "scanning", errorCode: .ERR_OBD_DROP, message: "Mid-scan drop after reconnect attempts")
        throw OBDError.scanInterrupted
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
    
    /// Mock scenario types for testing
    enum MockScenario: String, CaseIterable {
        // Healthy scenarios
        case healthySedan = "Healthy Sedan"
        case healthyTruck = "Healthy Truck"
        case healthyHybrid = "Healthy Hybrid"
        
        // Caution scenarios
        case recentlyCleared = "Recently Cleared Codes"
        case minorFuelIssue = "Minor Fuel System Issue"
        case agingBattery = "Aging Battery"
        case highMileage = "High Mileage Wear"
        
        // Problematic scenarios
        case engineMisfire = "Engine Misfire"
        case catalyticConverter = "Catalytic Converter Failure"
        case overheating = "Overheating Engine"
        case transmissionIssue = "Transmission Problems"
        case multipleDTCs = "Multiple System Failures"
    }
    
    /// Perform a simulated scan for development/testing
    /// Set scenario to nil for random selection
    func simulateScan(scenario: MockScenario? = nil) async -> OBDScanResults {
        // Pick random scenario if none specified
        let selectedScenario = scenario ?? MockScenario.allCases.randomElement()!
        
        await MainActor.run {
            connectionState = .scanning
            scanProgress = 0
            currentStatus = "Initializing scanner..."
        }
        
        // Simulate scan progress with scenario-specific messages
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.1, status: "Reading vehicle data...")
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.2, status: "Checking for trouble codes...")
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.35, status: "Reading engine data...")
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.5, status: "Checking fuel system...")
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.65, status: "Analyzing emissions...")
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.8, status: "Reading electrical systems...")
        
        try? await Task.sleep(nanoseconds: 400_000_000)
        await updateProgress(0.9, status: "Getting maintenance info...")
        
        // Generate simulated results based on scenario
        let results = generateResults(for: selectedScenario)
        
        try? await Task.sleep(nanoseconds: 300_000_000)
        await updateProgress(1.0, status: "Scan complete!")
        
        await MainActor.run {
            self.scanResults = results
            self.connectionState = .connected
        }
        
        return results
    }
    
    private func generateResults(for scenario: MockScenario) -> OBDScanResults {
        switch scenario {
        // Healthy scenarios
        case .healthySedan:
            return generateHealthySedan()
        case .healthyTruck:
            return generateHealthyTruck()
        case .healthyHybrid:
            return generateHealthyHybrid()
            
        // Caution scenarios
        case .recentlyCleared:
            return generateRecentlyCleared()
        case .minorFuelIssue:
            return generateMinorFuelIssue()
        case .agingBattery:
            return generateAgingBattery()
        case .highMileage:
            return generateHighMileage()
            
        // Problematic scenarios
        case .engineMisfire:
            return generateEngineMisfire()
        case .catalyticConverter:
            return generateCatalyticConverter()
        case .overheating:
            return generateOverheating()
        case .transmissionIssue:
            return generateTransmissionIssue()
        case .multipleDTCs:
            return generateMultipleDTCs()
        }
    }
    
    // MARK: - Healthy Scenarios
    
    /// Clean 2019 Honda Accord - perfect condition
    private func generateHealthySedan() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "1HGCV1F34KA012345"
        results.dtcs = []
        results.rpm = Double.random(in: 720...780)
        results.engineLoad = Double.random(in: 18...25)
        results.coolantTemp = Double.random(in: 85...92)
        results.intakeTemp = Double.random(in: 30...40)
        results.fuelLevel = Double.random(in: 55...85)
        results.shortTermFuelTrim = Double.random(in: -2...3)
        results.longTermFuelTrim = Double.random(in: -2...2)
        results.batteryVoltage = Double.random(in: 13.8...14.4)
        results.throttlePosition = Double.random(in: 12...18)
        results.distanceSinceCleared = Double.random(in: 3000...15000)
        results.warmupsSinceCleared = Int.random(in: 80...200)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Clean 2020 Ford F-150 - well maintained truck
    private func generateHealthyTruck() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "1FTEW1EP5LFA12345"
        results.dtcs = []
        results.rpm = Double.random(in: 650...720)
        results.engineLoad = Double.random(in: 20...28)
        results.coolantTemp = Double.random(in: 88...95)
        results.intakeTemp = Double.random(in: 32...42)
        results.fuelLevel = Double.random(in: 40...75)
        results.shortTermFuelTrim = Double.random(in: -3...4)
        results.longTermFuelTrim = Double.random(in: -2...3)
        results.batteryVoltage = Double.random(in: 13.9...14.5)
        results.throttlePosition = Double.random(in: 14...20)
        results.distanceSinceCleared = Double.random(in: 5000...20000)
        results.warmupsSinceCleared = Int.random(in: 100...250)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Clean 2021 Toyota Prius - efficient hybrid
    private func generateHealthyHybrid() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "JTDKN3DU5M3012345"
        results.dtcs = []
        results.rpm = Double.random(in: 0...1200) // Hybrids can show 0 when on battery
        results.engineLoad = Double.random(in: 10...20)
        results.coolantTemp = Double.random(in: 75...88)
        results.intakeTemp = Double.random(in: 28...38)
        results.fuelLevel = Double.random(in: 60...90)
        results.shortTermFuelTrim = Double.random(in: -1...2)
        results.longTermFuelTrim = Double.random(in: -1...1)
        results.batteryVoltage = Double.random(in: 13.5...14.2)
        results.throttlePosition = Double.random(in: 10...15)
        results.distanceSinceCleared = Double.random(in: 8000...25000)
        results.warmupsSinceCleared = Int.random(in: 150...300)
        results.fuelType = "Hybrid Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    // MARK: - Caution Scenarios
    
    /// Codes recently cleared - suspicious seller behavior
    private func generateRecentlyCleared() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "2T1BURHE5JC073541"
        results.dtcs = [] // No codes but...
        results.rpm = Double.random(in: 750...820)
        results.engineLoad = Double.random(in: 25...32)
        results.coolantTemp = Double.random(in: 90...96)
        results.intakeTemp = Double.random(in: 35...42)
        results.fuelLevel = Double.random(in: 35...55)
        results.shortTermFuelTrim = Double.random(in: 5...9) // Slightly high
        results.longTermFuelTrim = Double.random(in: 4...7)
        results.batteryVoltage = Double.random(in: 13.6...14.0)
        results.throttlePosition = Double.random(in: 15...20)
        results.distanceSinceCleared = Double.random(in: 15...50) // Very recent!
        results.warmupsSinceCleared = Int.random(in: 1...5) // Almost none
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Minor vacuum leak causing fuel compensation
    private func generateMinorFuelIssue() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "1N4AL3AP8JC123456"
        results.dtcs = [] // No codes yet, but trending
        results.rpm = Double.random(in: 780...850)
        results.engineLoad = Double.random(in: 28...35)
        results.coolantTemp = Double.random(in: 88...94)
        results.intakeTemp = Double.random(in: 38...45)
        results.fuelLevel = Double.random(in: 30...60)
        results.shortTermFuelTrim = Double.random(in: 8...12) // High compensation
        results.longTermFuelTrim = Double.random(in: 6...10) // System adapting
        results.batteryVoltage = Double.random(in: 13.8...14.2)
        results.throttlePosition = Double.random(in: 16...22)
        results.distanceSinceCleared = Double.random(in: 2000...5000)
        results.warmupsSinceCleared = Int.random(in: 40...80)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Battery starting to fail, alternator working hard
    private func generateAgingBattery() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "5YFBURHE8JP123456"
        results.dtcs = []
        results.rpm = Double.random(in: 720...780)
        results.engineLoad = Double.random(in: 22...28)
        results.coolantTemp = Double.random(in: 86...92)
        results.intakeTemp = Double.random(in: 32...40)
        results.fuelLevel = Double.random(in: 45...70)
        results.shortTermFuelTrim = Double.random(in: -2...3)
        results.longTermFuelTrim = Double.random(in: -1...2)
        results.batteryVoltage = Double.random(in: 12.8...13.2) // Low!
        results.throttlePosition = Double.random(in: 14...18)
        results.distanceSinceCleared = Double.random(in: 4000...10000)
        results.warmupsSinceCleared = Int.random(in: 60...120)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// High mileage vehicle with expected wear
    private func generateHighMileage() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "JM1BL1SF5A1123456"
        results.dtcs = ["P0420"] // Aging catalytic converter
        results.rpm = Double.random(in: 700...760)
        results.engineLoad = Double.random(in: 24...30)
        results.coolantTemp = Double.random(in: 90...98)
        results.intakeTemp = Double.random(in: 35...44)
        results.fuelLevel = Double.random(in: 25...50)
        results.shortTermFuelTrim = Double.random(in: 3...7)
        results.longTermFuelTrim = Double.random(in: 2...5)
        results.batteryVoltage = Double.random(in: 13.6...14.1)
        results.throttlePosition = Double.random(in: 15...20)
        results.distanceSinceCleared = Double.random(in: 15000...35000)
        results.warmupsSinceCleared = Int.random(in: 200...400)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    // MARK: - Problematic Scenarios
    
    /// Active misfire - needs immediate attention
    private func generateEngineMisfire() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "1G1YY22G965123456"
        results.dtcs = ["P0300", "P0302", "P0304"] // Random & specific cylinder misfires
        results.rpm = Double.random(in: 680...750) // Rough idle
        results.engineLoad = Double.random(in: 30...40)
        results.coolantTemp = Double.random(in: 92...100)
        results.intakeTemp = Double.random(in: 40...48)
        results.fuelLevel = Double.random(in: 20...45)
        results.shortTermFuelTrim = Double.random(in: 10...18)
        results.longTermFuelTrim = Double.random(in: 8...14)
        results.batteryVoltage = Double.random(in: 13.5...14.0)
        results.throttlePosition = Double.random(in: 18...25)
        results.distanceSinceCleared = Double.random(in: 200...800)
        results.warmupsSinceCleared = Int.random(in: 10...30)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Failed catalytic converter - expensive repair
    private func generateCatalyticConverter() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "3FAHP0HA8CR123456"
        results.dtcs = ["P0420", "P0430"] // Both cat banks failing
        results.rpm = Double.random(in: 720...780)
        results.engineLoad = Double.random(in: 25...32)
        results.coolantTemp = Double.random(in: 88...95)
        results.intakeTemp = Double.random(in: 36...44)
        results.fuelLevel = Double.random(in: 30...55)
        results.shortTermFuelTrim = Double.random(in: 4...8)
        results.longTermFuelTrim = Double.random(in: 3...7)
        results.batteryVoltage = Double.random(in: 13.7...14.2)
        results.throttlePosition = Double.random(in: 15...20)
        results.distanceSinceCleared = Double.random(in: 500...2000)
        results.warmupsSinceCleared = Int.random(in: 15...50)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Overheating - possible head gasket or thermostat
    private func generateOverheating() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "2C3CDXCT4JH123456"
        results.dtcs = ["P0217", "P0128"] // Overheating & thermostat
        results.rpm = Double.random(in: 800...900) // High idle from heat
        results.engineLoad = Double.random(in: 35...45)
        results.coolantTemp = Double.random(in: 108...118) // Danger zone!
        results.intakeTemp = Double.random(in: 50...60)
        results.fuelLevel = Double.random(in: 35...60)
        results.shortTermFuelTrim = Double.random(in: 6...12)
        results.longTermFuelTrim = Double.random(in: 4...9)
        results.batteryVoltage = Double.random(in: 13.4...13.9)
        results.throttlePosition = Double.random(in: 20...28)
        results.distanceSinceCleared = Double.random(in: 100...500)
        results.warmupsSinceCleared = Int.random(in: 5...15)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Transmission slipping/failing
    private func generateTransmissionIssue() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "1HGCP2F31BA123456"
        results.dtcs = ["P0700", "P0730", "P0740"] // Trans codes
        results.rpm = Double.random(in: 750...820)
        results.engineLoad = Double.random(in: 28...36)
        results.coolantTemp = Double.random(in: 90...98)
        results.intakeTemp = Double.random(in: 38...46)
        results.fuelLevel = Double.random(in: 25...50)
        results.shortTermFuelTrim = Double.random(in: 2...6)
        results.longTermFuelTrim = Double.random(in: 1...4)
        results.batteryVoltage = Double.random(in: 13.6...14.1)
        results.throttlePosition = Double.random(in: 16...22)
        results.distanceSinceCleared = Double.random(in: 300...1200)
        results.warmupsSinceCleared = Int.random(in: 12...40)
        results.fuelType = "Gasoline"
        results.obdStandard = "OBD-II CARB"
        results.deviceType = "WiFi (Simulated)"
        return results
    }
    
    /// Multiple system failures - walk away
    private func generateMultipleDTCs() -> OBDScanResults {
        var results = OBDScanResults()
        results.vin = "WVWZZZ3CZWE123456"
        results.dtcs = ["P0171", "P0300", "P0401", "P0420", "P0505", "C0035", "U0100"]
        results.rpm = Double.random(in: 650...750)
        results.engineLoad = Double.random(in: 35...48)
        results.coolantTemp = Double.random(in: 98...106)
        results.intakeTemp = Double.random(in: 45...55)
        results.fuelLevel = Double.random(in: 15...35)
        results.shortTermFuelTrim = Double.random(in: 15...22)
        results.longTermFuelTrim = Double.random(in: 12...18)
        results.batteryVoltage = Double.random(in: 12.2...12.8) // Weak
        results.throttlePosition = Double.random(in: 22...30)
        results.distanceSinceCleared = Double.random(in: 50...200)
        results.warmupsSinceCleared = Int.random(in: 3...10)
        results.fuelType = "Gasoline"
        results.obdStandard = "EOBD"
        results.deviceType = "WiFi (Simulated)"
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

/// Scan progress state for mid-scan drop recovery.
enum ScanState {
    case idle
    case scanning
    case interrupted
}

// MARK: - OBD Errors
enum OBDError: LocalizedError {
    case notConnected
    case connectionFailed(String)
    case timeout
    case sendFailed(String)
    case receiveFailed(String)
    case invalidResponse
    case scanInterrupted  // Connection lost mid-scan after reconnect attempts failed
    
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
        case .scanInterrupted:
            return "Connection to the scanner was lost. You can retry the connection or start over."
        }
    }
}
