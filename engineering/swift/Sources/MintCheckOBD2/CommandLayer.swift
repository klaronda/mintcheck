/**
 * Command Layer - AT Commands and OBD PID Requests
 * 
 * Handles sending commands to ELM327, waiting for responses,
 * with timeout, retry, and error detection.
 */

import Foundation

struct ATResponse {
    let raw: String
    let success: Bool
    let data: String?
    let error: String?
}

struct PIDResponse {
    let pid: String
    let raw: String
    let hex: String
    let value: Double?
    let unit: String?
    let error: String?
}

// Protocol for transport layer
protocol OBDTransport {
    var connected: Bool { get }
    func setDataHandler(_ handler: @escaping (String) -> Void)
    func setErrorHandler(_ handler: @escaping (Error) -> Void)
    func setCloseHandler(_ handler: @escaping () -> Void)
    func write(_ data: String) throws
    func disconnect()
}

// Make BluetoothTransport conform
extension BluetoothTransport: OBDTransport {}

// Make SerialTransport conform
extension SerialTransport: OBDTransport {}

class CommandLayer {
    private let transport: OBDTransport
    private let logger: Logger
    private let timeout: TimeInterval
    private let retries: Int
    private var responseQueue: [(String) -> Void] = []
    private var errorQueue: [(Error) -> Void] = []
    private var currentResponse: String = ""
    private var responseTimer: Timer?
    
    init(transport: OBDTransport, logger: Logger, timeout: TimeInterval = 2.0, retries: Int = 1) {
        self.transport = transport
        self.logger = logger
        self.timeout = timeout
        self.retries = retries
        
        // Set up transport event handlers
        transport.setDataHandler { [weak self] data in
            self?.handleResponse(data)
        }
        
        transport.setErrorHandler { [weak self] error in
            self?.logger.error("TRANSPORT", "Transport error", data: error.localizedDescription)
            self?.rejectCurrent(NSError(domain: "CommandLayer", code: 1, userInfo: [NSLocalizedDescriptionKey: "Transport error: \(error.localizedDescription)"]))
        }
        
        transport.setCloseHandler { [weak self] in
            self?.logger.warn("TRANSPORT", "Connection closed")
            // Don't reject on close if we're already disconnected - this prevents double-resume crashes
            // The main disconnect will handle cleanup
        }
    }
    
    /**
     * Handle incoming data from transport
     */
    private func handleResponse(_ data: String) {
        logger.rx(data)
        
        // Accumulate response (ELM327 may send multiple lines)
        if !currentResponse.isEmpty {
            currentResponse += " " + data
        } else {
            currentResponse = data
        }
        
        // Check if we have a complete response
        // ELM327 typically ends with '>' prompt, but we also accept standalone responses
        if data.contains(">") || !data.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Clear timeout
            responseTimer?.invalidate()
            responseTimer = nil
            
            // Resolve the current pending command
            let response = currentResponse.trimmingCharacters(in: .whitespacesAndNewlines)
            currentResponse = ""
            
            if !responseQueue.isEmpty {
                let resolve = responseQueue.removeFirst()
                resolve(response)
            }
        }
    }
    
    /**
     * Reject current pending command
     */
    private func rejectCurrent(_ error: Error) {
        responseTimer?.invalidate()
        responseTimer = nil
        currentResponse = ""
        
        // Only reject if there's actually a pending command
        if !errorQueue.isEmpty && !responseQueue.isEmpty {
            let reject = errorQueue.removeFirst()
            let _ = responseQueue.removeFirst() // Remove corresponding resolve too
            reject(error)
        }
    }
    
    /**
     * Send command and wait for response
     */
    private func sendCommand(_ command: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Add to queue
            responseQueue.append { response in
                continuation.resume(returning: response)
            }
            
            errorQueue.append { error in
                continuation.resume(throwing: error)
            }
            
            // Set timeout
            let commandCopy = command
            responseTimer = Timer.scheduledTimer(withTimeInterval: timeout, repeats: false) { [weak self] _ in
                self?.rejectCurrent(NSError(domain: "CommandLayer", code: 3, userInfo: [NSLocalizedDescriptionKey: "Command timeout: \(commandCopy)"]))
            }
            
            // Send command
            do {
                try transport.write(command)
            } catch {
                rejectCurrent(error)
            }
        }
    }
    
    /**
     * Send AT command with retry logic
     */
    func sendAT(_ command: String) async -> ATResponse {
        logger.tx(command)
        
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                let response = try await sendCommand(command)
                
                // Check for OK
                let cleaned = OBDParser.cleanResponse(response)
                if cleaned.contains("OK") || cleaned.contains("ELM") || !cleaned.isEmpty {
                    return ATResponse(
                        raw: response,
                        success: true,
                        data: response,
                        error: nil
                    )
                }
                
                // Check for error
                if let error = OBDParser.extractError(response) {
                    return ATResponse(
                        raw: response,
                        success: false,
                        data: nil,
                        error: error
                    )
                }
                
                // Empty or unexpected response
                if attempt < retries {
                    logger.warn("COMMAND", "Empty response, retrying... (attempt \(attempt + 1)/\(retries + 1))")
                    try await Task.sleep(nanoseconds: 100_000_000) // 100ms delay
                    continue
                }
                
                return ATResponse(
                    raw: response,
                    success: false,
                    data: nil,
                    error: "Unexpected response format"
                )
            } catch {
                lastError = error
                logger.error("COMMAND", "Command failed: \(command)", data: error.localizedDescription)
                
                if attempt < retries {
                    logger.warn("COMMAND", "Retrying... (attempt \(attempt + 1)/\(retries + 1))")
                    Task {
                        try? await Task.sleep(nanoseconds: 100_000_000)
                    }
                    continue
                }
            }
        }
        
        return ATResponse(
            raw: "",
            success: false,
            data: nil,
            error: lastError?.localizedDescription ?? "Command failed after retries"
        )
    }
    
    /**
     * Send OBD PID request (Mode 01)
     */
    func queryPID(_ pid: String) async -> PIDResponse {
        let command = pid.uppercased()
        logger.tx(command)
        
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                let response = try await sendCommand(command)
                let parsed = OBDParser.parseMode01Response(pid: pid, response: response)
                
                if parsed.error != nil {
                    if attempt < retries {
                        logger.warn("COMMAND", "PID query failed, retrying... (attempt \(attempt + 1)/\(retries + 1))")
                        try await Task.sleep(nanoseconds: 100_000_000)
                        continue
                    }
                }
                
                return PIDResponse(
                    pid: pid,
                    raw: parsed.raw,
                    hex: parsed.hex,
                    value: parsed.value,
                    unit: parsed.unit,
                    error: parsed.error
                )
            } catch {
                lastError = error
                logger.error("COMMAND", "PID query failed: \(pid)", data: error.localizedDescription)
                
                if attempt < retries {
                    logger.warn("COMMAND", "Retrying... (attempt \(attempt + 1)/\(retries + 1))")
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    continue
                }
            }
        }
        
        return PIDResponse(
            pid: pid,
            raw: "",
            hex: "",
            value: nil,
            unit: nil,
            error: lastError?.localizedDescription ?? "PID query failed after retries"
        )
    }
    
    /**
     * Query Diagnostic Trouble Codes (Mode 03)
     */
    func queryDTCs() async -> (count: Int, dtcs: [String], error: String?) {
        let command = "03" // Mode 03 - Request DTCs
        logger.tx(command)
        
        var lastError: Error?
        
        for attempt in 0...retries {
            do {
                let response = try await sendCommand(command)
                let parsed = OBDParser.parseMode03Response(response)
                
                if parsed.dtcs.isEmpty && parsed.count == 0 {
                    // Check if it's an actual error or just no codes
                    if OBDParser.isError(response) {
                        if attempt < retries {
                            logger.warn("COMMAND", "DTC query failed, retrying... (attempt \(attempt + 1)/\(retries + 1))")
                            try await Task.sleep(nanoseconds: 100_000_000)
                            continue
                        }
                        return (count: 0, dtcs: [], error: OBDParser.extractError(response))
                    }
                }
                
                return (count: parsed.count, dtcs: parsed.dtcs, error: nil)
            } catch {
                lastError = error
                logger.error("COMMAND", "DTC query failed", data: error.localizedDescription)
                
                if attempt < retries {
                    logger.warn("COMMAND", "Retrying... (attempt \(attempt + 1)/\(retries + 1))")
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    continue
                }
            }
        }
        
        return (count: 0, dtcs: [], error: lastError?.localizedDescription ?? "DTC query failed after retries")
    }
    
    /**
     * Initialize ELM327 device (Phase 1 handshake)
     */
    func initialize() async -> Bool {
        logger.info("INIT", "Starting ELM327 initialization...")
        
        let commands = [
            ("ATZ", "Reset"),
            ("ATE0", "Echo off"),
            ("ATL0", "Linefeeds off"),
            ("ATS0", "Spaces off"),
            ("ATH1", "Headers on"),
            ("ATSP0", "Auto protocol"),
        ]
        
        for (cmd, desc) in commands {
            logger.info("INIT", "Sending \(cmd) (\(desc))...")
            let result = await sendAT(cmd)
            
            if !result.success {
                logger.error("INIT", "Failed: \(cmd)", data: result.error)
                return false
            }
            
            // Special handling for ATZ - should return version
            if cmd == "ATZ", let data = result.data {
                logger.info("INIT", "ELM327 version: \(data)")
            }
            
            // Small delay between commands
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }
        
        logger.info("INIT", "Initialization complete")
        return true
    }
}
