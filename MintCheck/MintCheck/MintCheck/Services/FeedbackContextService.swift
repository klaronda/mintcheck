//
//  FeedbackContextService.swift
//  MintCheck
//
//  Builds feedback context (device, app, connectivity, scan, breadcrumbs) for submission.
//

import Foundation
import UIKit

/// Category for user feedback
enum FeedbackCategory: String, Codable, CaseIterable {
    case bug = "Bug / Something didn't work"
    case confusing = "Confusing / Didn't understand"
    case suggestion = "Suggestion"
    case other = "Other"
}

/// Source of feedback entry point
enum FeedbackSource: String, Codable {
    case in_app = "in_app"
    case error_cta = "error_cta"
}

// MARK: - Breadcrumb ring buffer (last ~20 events)

struct BreadcrumbEvent: Codable {
    let event: String
    let timestamp: Date
    let metadata: [String: String]?
    
    init(event: String, metadata: [String: String]? = nil) {
        self.event = event
        self.timestamp = Date()
        self.metadata = metadata
    }
}

final class BreadcrumbLogger {
    static let shared = BreadcrumbLogger()
    private let maxEvents = 20
    private var events: [BreadcrumbEvent] = []
    private let queue = DispatchQueue(label: "com.mintcheck.breadcrumbs")
    
    private init() {}
    
    func log(_ event: String, metadata: [String: String]? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.events.append(BreadcrumbEvent(event: event, metadata: metadata))
            if self.events.count > self.maxEvents {
                self.events.removeFirst(self.events.count - self.maxEvents)
            }
        }
    }
    
    func snapshot() -> [BreadcrumbEvent] {
        queue.sync { Array(events.suffix(maxEvents)) }
    }
}

// MARK: - Context builder

@MainActor
struct FeedbackContextService {
    
    /// Build full context dict for feedback. Pass prefill for error_code, error_message, scan_step, etc.
    static func buildContext(
        authService: AuthService,
        nav: NavigationManager,
        connectionManager: ConnectionManagerService,
        prefill: [String: Any]? = nil
    ) -> [String: Any] {
        var ctx: [String: Any] = [:]
        
        // Timestamp
        ctx["timestamp"] = ISO8601DateFormatter().string(from: Date())
        
        // App
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        ctx["app_version"] = "\(version) (\(build))"
        ctx["platform"] = "iOS"
        
        // Device
        ctx["device_model"] = UIDevice.current.model
        ctx["os_version"] = UIDevice.current.systemVersion
        ctx["locale"] = Locale.current.identifier
        ctx["timezone"] = TimeZone.current.identifier
        
        // User (nullable) — use optional string for JSON
        ctx["user_id"] = authService.currentUser?.id.uuidString as Any
        ctx["user_email"] = authService.currentUser?.email as Any
        
        // Screen / route
        ctx["screen"] = screenName(nav.currentScreen)
        
        // Connectivity
        ctx["internet_status"] = connectionManager.internetStatus.rawValue
        ctx["obd_transport"] = obdTransport(connectionManager)
        ctx["obd_status"] = obdStatus(connectionManager)
        
        // Scan state (from nav.currentScanData and inferred step)
        let scan = nav.currentScanData
        ctx["scan_state"] = scanState(scan, nav: nav)
        ctx["scan_step"] = scanStep(scan, nav: nav)
        ctx["scan_progress_percent"] = scanProgressPercent(scan, nav: nav)
        ctx["report_id"] = scan.shareCode ?? scan.scanId?.uuidString as Any
        
        // Breadcrumbs
        let breadcrumbs = BreadcrumbLogger.shared.snapshot().map { b in
            [
                "event": b.event,
                "timestamp": ISO8601DateFormatter().string(from: b.timestamp),
                "metadata": b.metadata as Any
            ] as [String: Any]
        }
        ctx["breadcrumbs"] = breadcrumbs
        
        // Prefill (error_code, error_message, etc.) overrides
        if let prefill = prefill {
            for (k, v) in prefill {
                ctx[k] = v
            }
        }
        
        return ctx
    }
    
    private static func screenName(_ screen: Screen) -> String {
        switch screen {
        case .loading: return "loading"
        case .home: return "home"
        case .signIn: return "sign_in"
        case .onboarding: return "onboarding"
        case .dashboard: return "dashboard"
        case .allScans: return "all_scans"
        case .support: return "support"
        case .settings: return "settings"
        case .scanFlow: return "scan_flow"
        case .vehicleBasics: return "vehicle_basics"
        case .deviceConnection: return "device_connection"
        case .scanning: return "scanning"
        case .disconnectReconnect: return "disconnect_reconnect"
        case .quickHumanCheck: return "quick_human_check"
        case .results: return "results"
        case .systemDetail: return "system_detail"
        case .resetPassword: return "reset_password"
        case .resetPasswordExpired: return "reset_password_expired"
        case .emailConfirmationSuccess: return "email_confirmation_success"
        case .deepCheckSuccess: return "deep_check_success"
        case .deepCheckReport: return "deep_check_report"
        case .myDeepChecks: return "my_deep_checks"
        case .deepCheckEntry: return "deep_check_entry"
        case .freeVinMismatch: return "free_vin_mismatch"
        case .buyerPassSuccess: return "buyer_pass_success"
        }
    }
    
    private static func obdTransport(_ cm: ConnectionManagerService) -> String {
        guard let deviceType = cm.currentDeviceType else { return "unknown" }
        switch deviceType {
        case .wifi: return "wifi"
        case .bluetooth: return "bluetooth"
        }
    }
    
    private static func obdStatus(_ cm: ConnectionManagerService) -> String {
        switch cm.currentDeviceType {
        case .wifi:
            let state = cm.wifiManager.connectionState
            switch state {
            case .connected: return "connected"
            case .connecting, .searching: return "unstable"
            case .failed, .idle, .disconnecting: return "disconnected"
            }
        case .bluetooth:
            // Could inspect bluetoothManager; default to unknown
            return "unknown"
        case .none:
            return "disconnected"
        }
    }
    
    private static func scanState(_ scan: ScanData, nav: NavigationManager) -> String {
        let screen = nav.currentScreen
        if [.vehicleBasics, .deviceConnection, .scanning, .disconnectReconnect, .quickHumanCheck].contains(screen) {
            if screen == .scanning { return "running" }
            if screen == .deviceConnection || screen == .vehicleBasics { return "preparing" }
            if screen == .disconnectReconnect { return "interrupted" }
            return "running"
        }
        if screen == .results || screen == .systemDetail {
            return "completed"
        }
        if scan.scanResults != nil && scan.reportStorage == .pending_upload {
            return "completed"
        }
        return "idle"
    }
    
    private static func scanStep(_ scan: ScanData, nav: NavigationManager) -> String {
        switch nav.currentScreen {
        case .vehicleBasics: return "vehicle_basics"
        case .deviceConnection: return "connect_obd"
        case .scanning: return "read_dtcs"
        case .disconnectReconnect: return "disconnect"
        case .quickHumanCheck: return "quick_check"
        case .results: return "results"
        case .systemDetail: return "system_detail"
        default: return "idle"
        }
    }
    
    private static func scanProgressPercent(_ scan: ScanData, nav: NavigationManager) -> Int {
        switch nav.currentScreen {
        case .vehicleBasics: return 10
        case .deviceConnection: return 25
        case .scanning: return 50
        case .disconnectReconnect: return 75
        case .quickHumanCheck: return 80
        case .results: return 100
        default: return 0
        }
    }
}
