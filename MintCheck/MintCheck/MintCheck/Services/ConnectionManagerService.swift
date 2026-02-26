//
//  ConnectionManagerService.swift
//  MintCheck
//
//  Centralized service to manage WiFi and Bluetooth connections
//

import SwiftUI
import Combine
import NetworkExtension
import CoreBluetooth
import Network

/// Internet connectivity status for error handling & offline fallback.
enum InternetStatus: String {
    case online
    case limited  // Path satisfied but actual reachability may be poor
    case offline
}

/// Service to manage device connections (WiFi and Bluetooth)
class ConnectionManagerService: ObservableObject {
    @Published var currentDeviceType: DeviceType?
    @Published var wifiManager = WiFiConnectionManager()
    @Published var bluetoothManager = BluetoothManager()
    /// Last known internet status; updated by checkInternetStatus().
    @Published var internetStatus: InternetStatus = .offline
    
    /// Disconnect from all active connections based on device type
    func disconnectAll() async {
        if let deviceType = currentDeviceType {
            switch deviceType {
            case .wifi:
                _ = await disconnectWiFi()
            case .bluetooth:
                disconnectBluetooth()
            }
        }
    }
    
    /// Disconnect from WiFi scanner
    /// Returns true if successfully disconnected, false if still connected
    func disconnectWiFi() async -> Bool {
        let savedDevice = DeviceStorage.loadSavedDevice()
        return await wifiManager.disconnectFromKnownNetworks(savedDevice: savedDevice)
    }
    
    /// Disconnect from Bluetooth scanner
    func disconnectBluetooth() {
        bluetoothManager.disconnect()
    }
    
    /// Set the current device type being used
    func setDeviceType(_ deviceType: DeviceType?) {
        currentDeviceType = deviceType
    }

    /// Wait for internet connectivity after disconnecting from scanner Wi-Fi
    func waitForInternet(timeout: TimeInterval) async -> Bool {
        let monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "com.mintcheck.network.monitor")

        return await withCheckedContinuation { continuation in
            var didFinish = false

            monitor.pathUpdateHandler = { path in
                guard path.status == .satisfied, !didFinish else { return }
                Task {
                    let hasInternet = await self.verifyInternetAccess()
                    if hasInternet && !didFinish {
                        didFinish = true
                        monitor.cancel()
                        continuation.resume(returning: true)
                    }
                }
            }

            monitor.start(queue: queue)

            queue.asyncAfter(deadline: .now() + timeout) {
                if !didFinish {
                    didFinish = true
                    monitor.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }

    private func verifyInternetAccess() async -> Bool {
        guard let url = URL(string: "https://www.apple.com/library/test/success.html") else {
            return false
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 3
        request.cachePolicy = .reloadIgnoringLocalCacheData

        do {
            let (_, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                await MainActor.run { internetStatus = .offline }
                return false
            }
            let ok = (200...299).contains(httpResponse.statusCode)
            await MainActor.run { internetStatus = ok ? .online : .offline }
            return ok
        } catch {
            await MainActor.run { internetStatus = .offline }
            return false
        }
    }

    /// Check internet connectivity and update internetStatus. Returns true if online.
    func checkInternetStatus() async -> Bool {
        let pathSatisfied = await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let monitor = NWPathMonitor()
            let q = DispatchQueue(label: "com.mintcheck.internet.check")
            var didResume = false
            let lock = NSLock()
            func resumeOnce(_ value: Bool) {
                lock.lock()
                defer { lock.unlock() }
                guard !didResume else { return }
                didResume = true
                monitor.cancel()
                continuation.resume(returning: value)
            }
            monitor.pathUpdateHandler = { path in
                resumeOnce(path.status == .satisfied)
            }
            monitor.start(queue: q)
            q.asyncAfter(deadline: .now() + 2) {
                resumeOnce(monitor.currentPath.status == .satisfied)
            }
        }
        if !pathSatisfied {
            await MainActor.run { internetStatus = .offline }
            return false
        }
        let hasInternet = await verifyInternetAccess()
        if !hasInternet {
            await MainActor.run { internetStatus = .limited }
        }
        return hasInternet
    }
}

// MARK: - WiFi Connection Manager (moved from DeviceConnectionView)
enum WiFiConnectionState {
    case idle
    case searching
    case connecting
    case connected
    case failed
    case disconnecting
}

class WiFiConnectionManager: ObservableObject {
    @Published var connectionState: WiFiConnectionState = .idle
    @Published var currentMessage: String = ""
    @Published var currentSSID: String? = nil
    
    // Common OBD-II WiFi network names to try (ordered by likelihood; exclude V-LINK/VEEPEAK per testing)
    private let commonNetworkNames = [
        // WiFi-first naming (very common with cheap adapters)
        "WiFi_OBDII",
        "WIFI_OBDII",
        "WiFi-OBDII",
        "WIFI-OBDII",
        // OBD-first naming
        "OBDII_WIFI",
        "OBDII-WIFI",
        "OBDII",
        "OBD2_WIFI",
        "OBD2-WIFI",
        "OBD2",
        // ELM327
        "ELM327",
        // Other common variants
        "CARWIFI",
        "CAR_WIFI",
        "CAR-WIFI"
    ]
    
    var connectedNetworkName: String?
    
    /// Check if current SSID looks like an OBD device (excludes V-LINK/VEEPEAK per testing)
    var isConnectedToOBDNetwork: Bool {
        guard let ssid = currentSSID else { return false }
        let upperSSID = ssid.uppercased()
        return commonNetworkNames.contains { upperSSID.contains($0.uppercased()) } ||
               upperSSID.contains("OBD") ||
               upperSSID.contains("ELM") ||
               upperSSID.contains("CARWIFI")
    }
    
    /// Fetch current WiFi SSID. Uses NEHotspotNetwork.fetchCurrent; iOS may return nil (shown as "Unknown" in UI) unless the app has Hotspot Configuration and the network was joined in a way iOS exposes to the app.
    func fetchCurrentSSID() async {
        await withCheckedContinuation { continuation in
            NEHotspotNetwork.fetchCurrent { network in
                DispatchQueue.main.async {
                    self.currentSSID = network?.ssid
                    continuation.resume()
                }
            }
        }
    }
    
    /// Attempt to connect to an OBD-II WiFi network
    func connectToScanner(savedDevice: SavedDevice?) async {
        await MainActor.run {
            connectionState = .searching
            currentMessage = "Searching for your scanner..."
        }
        
        // If we have a saved device, try that first
        var networksToTry = commonNetworkNames
        if let saved = savedDevice {
            networksToTry = [saved.networkName] + commonNetworkNames.filter { $0 != saved.networkName }
        }
        
        // Try each network name
        for networkName in networksToTry {
            await MainActor.run {
                currentMessage = "Trying to connect to \(networkName)..."
                connectionState = .connecting
            }
            
            let result = await attemptConnection(to: networkName)
            
            switch result {
            case .success:
                await MainActor.run {
                    connectionState = .connected
                    currentMessage = "Connected to \(networkName)"
                    connectedNetworkName = networkName
                }
                // Auto-dismiss after 2 seconds on success
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                await MainActor.run {
                    connectionState = .idle
                }
                return
                
            case .failure:
                // Continue to next network
                continue
            }
        }
        
        // If we get here, none of the networks were found
        await MainActor.run {
            connectionState = .failed
            currentMessage = "Scanner network not found"
        }
    }
    
    private func attemptConnection(to networkName: String) async -> Result<Void, Error> {
        return await withCheckedContinuation { continuation in
            // Create hotspot configuration for open network (most OBD-II adapters are open)
            let configuration = NEHotspotConfiguration(ssid: networkName)
            configuration.joinOnce = false // Keep connection after app closes
            
            NEHotspotConfigurationManager.shared.apply(configuration) { error in
                if let error = error {
                    // Check if it's a NEHotspotConfigurationError
                    let nsError = error as NSError
                    if nsError.domain == "NEHotspotConfigurationErrorDomain" {
                        // Error codes:
                        // 7 = userDenied (user cancelled)
                        // 8 = internal
                        // 11 = systemConfiguration
                        // Network not found typically returns code 7 or 8
                        continuation.resume(returning: .failure(error))
                    } else {
                        continuation.resume(returning: .failure(error))
                    }
                } else {
                    // Successfully connected
                    continuation.resume(returning: .success(()))
                }
            }
        }
    }
    
    func reset() {
        connectionState = .idle
        currentMessage = ""
        connectedNetworkName = nil
    }
    
    /// Disconnect from the WiFi scanner network
    /// Returns true if successfully disconnected, false if still connected
    func disconnectFromKnownNetworks(savedDevice: SavedDevice?) async -> Bool {
        var networksToRemove = commonNetworkNames

        if let saved = savedDevice {
            networksToRemove.insert(saved.networkName, at: 0)
        }

        if let connected = connectedNetworkName {
            networksToRemove.insert(connected, at: 0)
        }

        let uniqueNetworks = Array(Set(networksToRemove))
        
        print("[WiFi Disconnect] Starting disconnect. Networks to remove: \(uniqueNetworks)")
        print("[WiFi Disconnect] Currently connected network: \(connectedNetworkName ?? "unknown")")

        await MainActor.run {
            connectionState = .disconnecting
            currentMessage = "Disconnecting from scanner Wi‑Fi..."
        }

        // Remove configurations - this only works for networks WE connected to via apply()
        uniqueNetworks.forEach { ssid in
            print("[WiFi Disconnect] Removing configuration for: \(ssid)")
            NEHotspotConfigurationManager.shared.removeConfiguration(forSSID: ssid)
        }

        // Wait for iOS to process the removal
        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // First check - are we still connected?
        var stillConnected = await verifyStillConnectedToOBD()
        print("[WiFi Disconnect] After removeConfiguration - still connected: \(stillConnected)")
        
        if stillConnected {
            // Try aggressive disconnect approach
            print("[WiFi Disconnect] Trying aggressive disconnect...")
            await aggressiveDisconnectAttempts()
            
            // Wait and check again
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            stillConnected = await verifyStillConnectedToOBD()
            print("[WiFi Disconnect] After aggressive attempts - still connected: \(stillConnected)")
        }
        
        // Give the phone 2–3 more seconds to recognize the new network before showing "still connected"
        if stillConnected {
            try? await Task.sleep(nanoseconds: 2_500_000_000) // 2.5 seconds
            stillConnected = await verifyStillConnectedToOBD()
            print("[WiFi Disconnect] After 2.5s wait - still connected: \(stillConnected)")
        }
        if stillConnected {
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 more seconds
            stillConnected = await verifyStillConnectedToOBD()
            print("[WiFi Disconnect] After second wait - still connected: \(stillConnected)")
        }

        await MainActor.run {
            connectedNetworkName = nil
            connectionState = .idle
            currentMessage = ""
        }

        let disconnectedSuccessfully = !stillConnected
        print("[WiFi Disconnect] Final result - disconnected successfully: \(disconnectedSuccessfully)")
        return disconnectedSuccessfully
    }
    
    /// Make multiple aggressive connection attempts that get cancelled
    /// This may trigger iOS to drop the WiFi connection
    private func aggressiveDisconnectAttempts() async {
        let host = NWEndpoint.Host("192.168.0.10")
        guard let port = NWEndpoint.Port(rawValue: 35000) else { return }
        
        // Try 5 times with increasing delays - this aggressive approach may force disconnect
        for i in 0..<5 {
            let parameters = NWParameters.tcp
            let queue = DispatchQueue(label: "com.mintcheck.force.disconnect.\(i)")
            
            let connection = NWConnection(host: host, port: port, using: parameters)
            
            // Start connection attempt
            connection.start(queue: queue)
            
            // Small delay to let connection start (increases with each attempt)
            try? await Task.sleep(nanoseconds: UInt64(50_000_000 + (i * 50_000_000))) // 0.05s to 0.25s
            
            // Cancel immediately
            connection.cancel()
            
            // Brief pause between attempts
            try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        }
    }
    
    /// Verify if we're still connected to OBD device by attempting to reach it
    private func verifyStillConnectedToOBD() async -> Bool {
        let host = NWEndpoint.Host("192.168.0.10")
        guard let port = NWEndpoint.Port(rawValue: 35000) else { return false }
        let parameters = NWParameters.tcp
        let queue = DispatchQueue(label: "com.mintcheck.verify.obd")
        
        return await withCheckedContinuation { continuation in
            let connection = NWConnection(host: host, port: port, using: parameters)
            var didResolve = false
            let resumeLock = NSLock()
            
            func resumeOnce(_ action: () -> Void) {
                resumeLock.lock()
                defer { resumeLock.unlock() }
                guard !didResolve else { return }
                didResolve = true
                action()
            }
            
            // Set up state handler
            connection.stateUpdateHandler = { state in
                switch state {
                case .ready:
                    // We can reach the OBD device - still connected
                    connection.cancel()
                    resumeOnce {
                        continuation.resume(returning: true)
                    }
                case .failed, .cancelled:
                    // Can't reach it - disconnected
                    resumeOnce {
                        continuation.resume(returning: false)
                    }
                default:
                    break
                }
            }
            
            connection.start(queue: queue)
            
            // Timeout after 2 seconds - if we can't connect, assume we're disconnected
            queue.asyncAfter(deadline: .now() + 2.0) {
                resumeOnce {
                    connection.cancel()
                    continuation.resume(returning: false)
                }
            }
        }
    }
}

// MARK: - Bluetooth Manager (moved from DeviceConnectionView)
class BluetoothManager: NSObject, ObservableObject, CBCentralManagerDelegate {
    // Keep a strong reference to prevent deallocation
    private var centralManager: CBCentralManager?
    
    /// Initialize CoreBluetooth with power alert option
    /// This will trigger a system prompt if Bluetooth is off
    func initialize() {
        // Only initialize if not already initialized
        guard centralManager == nil else { return }
        
        // Initialize with showPowerAlert option to trigger system prompt if Bluetooth is off
        // Use a background queue to avoid blocking the main thread
        centralManager = CBCentralManager(
            delegate: self,
            queue: nil, // nil uses a background queue
            options: [CBCentralManagerOptionShowPowerAlertKey: true]
        )
    }
    
    // MARK: - CBCentralManagerDelegate
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Update happens on the queue specified during initialization
        DispatchQueue.main.async { [weak self] in
            switch central.state {
            case .poweredOn:
                // Bluetooth is on - user can proceed
                break
            case .poweredOff:
                // Bluetooth is off - system prompt should have appeared
                // The system prompt is automatically shown when Bluetooth is off
                // and CBCentralManagerOptionShowPowerAlertKey is set to true
                break
            case .unauthorized:
                // User denied Bluetooth permission
                break
            case .unsupported:
                // Device doesn't support Bluetooth
                break
            case .resetting:
                // Bluetooth is resetting
                break
            @unknown default:
                break
            }
        }
    }
    
    /// Disconnect and clean up Bluetooth resources
    func disconnect() {
        // Cancel any active scanning
        centralManager?.stopScan()
        
        // Clean up manager
        centralManager = nil
    }
}
