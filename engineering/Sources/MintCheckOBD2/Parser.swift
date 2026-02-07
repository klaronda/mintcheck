/**
 * Parser - OBD-II Response Decoding
 * 
 * Parses hex responses from ELM327 according to SAE J1979 specification.
 * Handles stripping whitespace, ignoring prompts, and decoding PID values.
 */

import Foundation

struct ParsedResponse {
    let raw: String
    let hex: String
    let value: Double?
    let unit: String?
    let error: String?
}

class OBDParser {
    /**
     * Clean response: strip whitespace, remove prompt characters (>)
     */
    static func cleanResponse(_ response: String) -> String {
        return response
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\\s+", with: "", options: .regularExpression)
            .replacingOccurrences(of: ">", with: "")
            .uppercased()
    }
    
    /**
     * Check if response indicates an error condition
     */
    static func isError(_ response: String) -> Bool {
        let cleaned = cleanResponse(response)
        return cleaned.contains("NODATA") ||
               cleaned.contains("STOPPED") ||
               cleaned.contains("UNABLE") ||
               cleaned.contains("ERROR")
    }
    
    /**
     * Extract error message from response
     */
    static func extractError(_ response: String) -> String? {
        let cleaned = cleanResponse(response)
        if cleaned.contains("NODATA") { return "NO DATA" }
        if cleaned.contains("STOPPED") { return "STOPPED" }
        if cleaned.contains("UNABLE") { return "UNABLE TO CONNECT" }
        if cleaned.contains("ERROR") { return "ERROR" }
        return nil
    }
    
    /**
     * Parse Mode 01 PID response
     * Format: 41 [PID] [BYTE1] [BYTE2] [BYTE3] [BYTE4]
     * May include CAN headers like 7E8 (strip them)
     */
    static func parseMode01Response(pid: String, response: String) -> ParsedResponse {
        let cleaned = cleanResponse(response)
        var hex = cleaned
        
        // Check for errors first
        if let error = extractError(response) {
            return ParsedResponse(
                raw: response,
                hex: hex,
                value: nil,
                unit: nil,
                error: error
            )
        }
        
        // Strip CAN headers (7E8, 7E9, etc.) - these are 3 hex digits
        // CAN headers appear at the start: 7E804410C... -> 410C...
        if hex.count >= 3 {
            let firstThree = String(hex.prefix(3))
            // Check if it's a CAN header (starts with 7E)
            if firstThree.hasPrefix("7E") {
                // Find where the actual response starts (look for 41 which is Mode 01 response)
                if let index41 = hex.range(of: "41") {
                    let startIndex = hex.index(index41.lowerBound, offsetBy: 0)
                    hex = String(hex[startIndex...])
                } else {
                    // Try to strip the first 3-4 hex digits (CAN header + length)
                    if hex.count >= 4 {
                        hex = String(hex.dropFirst(4))
                    }
                }
            }
        }
        
        // Validate format: should start with 41 (Mode 01 response) and PID
        let expectedPrefix = "41\(pid.uppercased())"
        if !hex.hasPrefix(expectedPrefix) {
            let actualPrefix = hex.count >= 6 ? String(hex.prefix(6)) : hex
            return ParsedResponse(
                raw: response,
                hex: hex,
                value: nil,
                unit: nil,
                error: "Invalid response format. Expected \(expectedPrefix), got \(actualPrefix)"
            )
        }
        
        // Extract data bytes (skip 41 and PID)
        let startIndex = hex.index(hex.startIndex, offsetBy: 4)
        guard startIndex < cleaned.endIndex else {
            return ParsedResponse(
                raw: response,
                hex: hex,
                value: nil,
                unit: nil,
                error: "Insufficient data bytes"
            )
        }
        
        let dataHex = String(cleaned[startIndex...])
        
        if dataHex.count < 2 {
            return ParsedResponse(
                raw: response,
                hex: hex,
                value: nil,
                unit: nil,
                error: "Insufficient data bytes"
            )
        }
        
        // Parse based on PID
        return parsePIDValue(pid: pid, dataHex: dataHex, raw: response, hex: hex)
    }
    
    /**
     * Parse PID-specific value
     */
    private static func parsePIDValue(pid: String, dataHex: String, raw: String, hex: String) -> ParsedResponse {
        let pidUpper = pid.uppercased()
        
        switch pidUpper {
        case "0100": // Supported PIDs [01-20]
            if let value = UInt32(dataHex.prefix(min(8, dataHex.count)), radix: 16) {
                return ParsedResponse(
                    raw: raw,
                    hex: hex,
                    value: Double(value),
                    unit: "bitmask",
                    error: nil
                )
            }
            
        case "010C": // Engine RPM
            // Formula: ((A * 256) + B) / 4
            if dataHex.count >= 4 {
                let aHex = String(dataHex.prefix(2))
                let bHex = String(dataHex.dropFirst(2).prefix(2))
                if let a = UInt8(aHex, radix: 16), let b = UInt8(bHex, radix: 16) {
                    let rpm = Double((UInt16(a) * 256) + UInt16(b)) / 4.0
                    return ParsedResponse(
                        raw: raw,
                        hex: hex,
                        value: round(rpm * 100) / 100,
                        unit: "rpm",
                        error: nil
                    )
                }
            }
            return ParsedResponse(raw: raw, hex: hex, value: nil, unit: nil, error: "Insufficient bytes for RPM")
            
        case "010D": // Vehicle Speed
            // Formula: A (km/h)
            if dataHex.count >= 2 {
                let speedHex = String(dataHex.prefix(2))
                if let speed = UInt8(speedHex, radix: 16) {
                    return ParsedResponse(
                        raw: raw,
                        hex: hex,
                        value: Double(speed),
                        unit: "km/h",
                        error: nil
                    )
                }
            }
            return ParsedResponse(raw: raw, hex: hex, value: nil, unit: nil, error: "Insufficient bytes for speed")
            
        case "0105": // Coolant Temperature
            // Formula: A - 40 (°C)
            if dataHex.count >= 2 {
                let tempHex = String(dataHex.prefix(2))
                if let temp = UInt8(tempHex, radix: 16) {
                    return ParsedResponse(
                        raw: raw,
                        hex: hex,
                        value: Double(temp) - 40.0,
                        unit: "°C",
                        error: nil
                    )
                }
            }
            return ParsedResponse(raw: raw, hex: hex, value: nil, unit: nil, error: "Insufficient bytes for temperature")
            
        case "0111": // Throttle Position
            // Formula: (100 * A) / 255 (%)
            if dataHex.count >= 2 {
                let throttleHex = String(dataHex.prefix(2))
                if let throttle = UInt8(throttleHex, radix: 16) {
                    let throttlePercent = (100.0 * Double(throttle)) / 255.0
                    return ParsedResponse(
                        raw: raw,
                        hex: hex,
                        value: round(throttlePercent * 100) / 100,
                        unit: "%",
                        error: nil
                    )
                }
            }
            return ParsedResponse(raw: raw, hex: hex, value: nil, unit: nil, error: "Insufficient bytes for throttle")
            
        case "010F": // Intake Air Temperature
            // Formula: A - 40 (°C)
            if dataHex.count >= 2 {
                let iatHex = String(dataHex.prefix(2))
                if let iat = UInt8(iatHex, radix: 16) {
                    return ParsedResponse(
                        raw: raw,
                        hex: hex,
                        value: Double(iat) - 40.0,
                        unit: "°C",
                        error: nil
                    )
                }
            }
            return ParsedResponse(raw: raw, hex: hex, value: nil, unit: nil, error: "Insufficient bytes for temperature")
            
        default:
            // Generic: return raw hex value
            if let value = UInt32(dataHex, radix: 16) {
                return ParsedResponse(
                    raw: raw,
                    hex: hex,
                    value: Double(value),
                    unit: "raw",
                    error: nil
                )
            }
        }
        
        return ParsedResponse(raw: raw, hex: hex, value: nil, unit: nil, error: "Failed to parse value")
    }
    
    /**
     * Validate hex string format
     */
    static func isValidHex(_ hex: String) -> Bool {
        let hexPattern = "^[0-9A-F]+$"
        let regex = try? NSRegularExpression(pattern: hexPattern, options: .caseInsensitive)
        let range = NSRange(location: 0, length: hex.utf16.count)
        return regex?.firstMatch(in: hex, options: [], range: range) != nil
    }
    
    /**
     * Parse Mode 03 response (Diagnostic Trouble Codes)
     * Format: 43 [COUNT] [DTC1] [DTC2] [DTC3] ...
     * Each DTC is 2 bytes: [A][B] where:
     *   - First byte (A): First 2 bits = type, last 6 bits = first digit
     *   - Second byte (B): Two hex digits = last 3 digits
     */
    static func parseMode03Response(_ response: String) -> (count: Int, dtcs: [String], raw: String) {
        let cleaned = cleanResponse(response)
        
        // Check for errors
        if let error = extractError(response) {
            return (count: 0, dtcs: [], raw: response)
        }
        
        // Should start with 43 (Mode 03 response)
        guard cleaned.hasPrefix("43") else {
            return (count: 0, dtcs: [], raw: response)
        }
        
        // Skip "43" prefix
        let startIndex = cleaned.index(cleaned.startIndex, offsetBy: 2)
        guard startIndex < cleaned.endIndex else {
            return (count: 0, dtcs: [], raw: response)
        }
        
        let dataHex = String(cleaned[startIndex...])
        
        // Parse DTCs (each DTC is 2 bytes = 4 hex chars)
        var dtcs: [String] = []
        var index = dataHex.startIndex
        
        while index < dataHex.endIndex {
            // Need at least 4 hex chars for one DTC
            if let nextIndex = dataHex.index(index, offsetBy: 4, limitedBy: dataHex.endIndex) {
                let dtcHex = String(dataHex[index..<nextIndex])
                
                if dtcHex.count == 4,
                   let byte1 = UInt8(String(dtcHex.prefix(2)), radix: 16),
                   let byte2 = UInt8(String(dtcHex.suffix(2)), radix: 16) {
                    
                    // Decode DTC
                    let typeBits = (byte1 >> 6) & 0x03
                    let firstDigit = byte1 & 0x3F
                    let lastDigits = byte2
                    
                    let typeChar: String
                    switch typeBits {
                    case 0: typeChar = "P" // Powertrain
                    case 1: typeChar = "C" // Chassis
                    case 2: typeChar = "B" // Body
                    case 3: typeChar = "U" // Network
                    default: typeChar = "?"
                    }
                    
                    // Format: P0XXX, P1XXX, etc.
                    let dtc = String(format: "%@%X%02X", typeChar, firstDigit, lastDigits)
                    dtcs.append(dtc)
                    
                    index = nextIndex
                } else {
                    break
                }
            } else {
                break
            }
        }
        
        return (count: dtcs.count, dtcs: dtcs, raw: response)
    }
}
