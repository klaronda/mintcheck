//
//  ErrorEventLogger.swift
//  MintCheck
//
//  Lightweight local error event logging for error handling & offline fallback.
//

import Foundation

/// Error codes for real failure paths (no mock/fake codes).
enum ErrorEventCode: String, Codable {
    case ERR_NO_INTERNET = "ERR_NO_INTERNET"
    case ERR_OBD_EARLY_WIFI = "ERR_OBD_EARLY_WIFI"
    case ERR_OBD_CONNECT_FAIL = "ERR_OBD_CONNECT_FAIL"
    case ERR_OBD_DROP = "ERR_OBD_DROP"
    case ERR_EMAIL_SEND_FAIL = "ERR_EMAIL_SEND_FAIL"
    case ERR_DELETE_FAIL = "ERR_DELETE_FAIL"
    case ERR_SAVE_UPLOAD_FAIL = "ERR_SAVE_UPLOAD_FAIL"
    case ERR_SHARE_OFFLINE = "ERR_SHARE_OFFLINE"
    case ERR_AI_ANALYSIS_FAIL = "ERR_AI_ANALYSIS_FAIL"
    case ERR_AUTH_FAIL = "ERR_AUTH_FAIL"
    case ERR_DELETE_ACCOUNT_FAIL = "ERR_DELETE_ACCOUNT_FAIL"
    case ERR_DELETE_SHARED_LINK_FAIL = "ERR_DELETE_SHARED_LINK_FAIL"
    case ERR_LOAD_SHARED_REPORTS_FAIL = "ERR_LOAD_SHARED_REPORTS_FAIL"
    case ERR_VIN_DECODE_FAIL = "ERR_VIN_DECODE_FAIL"
    case ERR_GENERIC = "ERR_GENERIC"
}

/// Single error event for local logging.
struct ErrorEvent: Codable {
    let timestamp: Date
    let screen: String
    let internetStatus: String?
    let obdStatus: String?
    let errorCode: String
    let message: String
}

/// Lightweight local logger for error events. In-memory ring buffer; optional persistence.
final class ErrorEventLogger {
    static let shared = ErrorEventLogger()
    
    private let maxEvents = 100
    private var events: [ErrorEvent] = []
    private let queue = DispatchQueue(label: "com.mintcheck.errorlogger")
    
    private init() {}
    
    /// Log an error event (call from real failure paths only).
    func log(
        screen: String,
        internetStatus: String? = nil,
        obdStatus: String? = nil,
        errorCode: ErrorEventCode,
        message: String
    ) {
        let event = ErrorEvent(
            timestamp: Date(),
            screen: screen,
            internetStatus: internetStatus,
            obdStatus: obdStatus,
            errorCode: errorCode.rawValue,
            message: message
        )
        queue.async { [weak self] in
            guard let self = self else { return }
            self.events.append(event)
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }
        }
    }
    
    /// Return recent events (e.g. for debugging). Main thread safe.
    func recentEvents(limit: Int = 20) -> [ErrorEvent] {
        queue.sync {
            Array(events.suffix(limit))
        }
    }
}
