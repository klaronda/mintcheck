/**
 * Logger - Raw TX/RX visibility with timestamps
 * 
 * Provides explicit logging for all communication with the ELM327 device.
 * Critical for debugging and building user trust.
 */

import Foundation

enum LogLevel: String {
    case debug = "DEBUG"
    case info = "INFO"
    case warn = "WARN"
    case error = "ERROR"
}

struct LogEntry {
    let timestamp: Date
    let level: LogLevel
    let category: String
    let message: String
    let data: String?
}

class Logger {
    private var entries: [LogEntry] = []
    private var verbose: Bool
    
    init(verbose: Bool = true) {
        self.verbose = verbose
    }
    
    private func log(_ level: LogLevel, category: String, message: String, data: String? = nil) {
        let entry = LogEntry(
            timestamp: Date(),
            level: level,
            category: category,
            message: message,
            data: data
        )
        
        entries.append(entry)
        
        if verbose || level != .debug {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            let timestamp = formatter.string(from: entry.timestamp)
            let prefix = "[\(timestamp)] [\(level.rawValue)] [\(category)]"
            
            if let data = data {
                print("\(prefix) \(message) \(data)")
            } else {
                print("\(prefix) \(message)")
            }
        }
    }
    
    func debug(_ category: String, _ message: String, data: String? = nil) {
        log(.debug, category: category, message: message, data: data)
    }
    
    func info(_ category: String, _ message: String, data: String? = nil) {
        log(.info, category: category, message: message, data: data)
    }
    
    func warn(_ category: String, _ message: String, data: String? = nil) {
        log(.warn, category: category, message: message, data: data)
    }
    
    func error(_ category: String, _ message: String, data: String? = nil) {
        log(.error, category: category, message: message, data: data)
    }
    
    /// Log raw TX (transmitted command)
    func tx(_ command: String) {
        let escaped = command.replacingOccurrences(of: "\r", with: "\\r")
        info("TX", "→ \(escaped)")
    }
    
    /// Log raw RX (received response)
    func rx(_ response: String) {
        info("RX", "← \(response)")
    }
    
    func getEntries() -> [LogEntry] {
        return entries
    }
    
    func clear() {
        entries.removeAll()
    }
    
    func setVerbose(_ verbose: Bool) {
        self.verbose = verbose
    }
}
