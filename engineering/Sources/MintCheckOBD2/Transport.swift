/**
 * Transport Layer - Bluetooth Serial Port Connection
 * 
 * Handles discovering and connecting to ELM327 devices over Bluetooth Classic SPP.
 * Uses IOBluetooth framework for macOS.
 */

import Foundation
import IOBluetooth
import IOBluetoothUI

struct BluetoothDevice {
    let address: String
    let name: String?
}

class BluetoothTransport: NSObject, IOBluetoothRFCOMMChannelDelegate {
    private var channel: IOBluetoothRFCOMMChannel?
    private var device: IOBluetoothDevice?
    private var channelID: BluetoothRFCOMMChannelID = 0
    private var isConnected = false
    private var dataHandler: ((String) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private var closeHandler: (() -> Void)?
    private var receivedData = Data()
    private var connectionSemaphore: DispatchSemaphore?
    private var connectionSuccess = false
    
    var connected: Bool {
        return isConnected
    }
    
    /**
     * Discover paired Bluetooth devices
     */
    static func discoverPairedDevices() -> [BluetoothDevice] {
        var devices: [BluetoothDevice] = []
        
        if let pairedDevices = IOBluetoothDevice.pairedDevices() as? [IOBluetoothDevice] {
            for device in pairedDevices {
                if let address = device.addressString {
                    let name = device.name
                    devices.append(BluetoothDevice(address: address, name: name))
                }
            }
        }
        
        return devices
    }
    
    /**
     * Connect to a device by address
     */
    func connect(to address: String) throws {
        guard let targetDevice = IOBluetoothDevice(addressString: address) else {
            throw NSError(domain: "BluetoothTransport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Device not found: \(address)"])
        }
        
        self.device = targetDevice
        
        // Note: We don't need to call openConnection() - openRFCOMMChannelSync will handle the connection
        // Some devices are already "connected" at the Bluetooth level, but we still need to open RFCOMM
        // The openRFCOMMChannelSync call will establish the RFCOMM connection we need
        
        // Try to discover RFCOMM channel from device services
        var channelID: BluetoothRFCOMMChannelID = 1 // Default
        
        // Try to get channel from services (some devices don't use channel 1)
        if let services = targetDevice.services as? [IOBluetoothSDPServiceRecord] {
            for service in services {
                var discoveredChannel: BluetoothRFCOMMChannelID = 0
                let result = service.getRFCOMMChannelID(&discoveredChannel)
                if result == kIOReturnSuccess && discoveredChannel != 0 {
                    channelID = discoveredChannel
                    break
                }
            }
        }
        
        // Try channel 1 first (most common for ELM327), then try discovered channel
        var result: IOReturn = kIOReturnError
        var attemptedChannels: [BluetoothRFCOMMChannelID] = []
        
        // Try default channel 1 first
        attemptedChannels.append(1)
        connectionSuccess = false
        connectionSemaphore = DispatchSemaphore(value: 0)
        result = targetDevice.openRFCOMMChannelAsync(&channel, withChannelID: 1, delegate: self)
        
        // Wait for async connection with timeout
        if result == kIOReturnSuccess {
            let timeoutResult = connectionSemaphore?.wait(timeout: .now() + 5.0)
            if timeoutResult == .timedOut || !connectionSuccess {
                result = kIOReturnTimeout
            }
        }
        
        // If that fails and we found a different channel, try it
        if result != kIOReturnSuccess && channelID != 1 {
            attemptedChannels.append(channelID)
            connectionSuccess = false
            connectionSemaphore = DispatchSemaphore(value: 0)
            result = targetDevice.openRFCOMMChannelAsync(&channel, withChannelID: channelID, delegate: self)
            
            if result == kIOReturnSuccess {
                let timeoutResult = connectionSemaphore?.wait(timeout: .now() + 5.0)
                if timeoutResult == .timedOut || !connectionSuccess {
                    result = kIOReturnTimeout
                }
            }
        }
        
        connectionSemaphore = nil
        
        if result != kIOReturnSuccess {
            let channelsTried = attemptedChannels.map { String($0) }.joined(separator: ", ")
            let errorMsg = "Failed to open RFCOMM channel (tried channels: \(channelsTried)). Error: \(result). Make sure the device supports SPP, is powered on, and is not connected to another app."
            throw NSError(domain: "BluetoothTransport", code: 2, userInfo: [NSLocalizedDescriptionKey: errorMsg])
        }
        
        guard let channel = channel else {
            throw NSError(domain: "BluetoothTransport", code: 3, userInfo: [NSLocalizedDescriptionKey: "Channel is nil after successful open"])
        }
        
        self.channel = channel
        self.channelID = channel.getID()
        self.isConnected = true
    }
    
    /**
     * Set event handlers
     */
    func setDataHandler(_ handler: @escaping (String) -> Void) {
        self.dataHandler = handler
    }
    
    func setErrorHandler(_ handler: @escaping (Error) -> Void) {
        self.errorHandler = handler
    }
    
    func setCloseHandler(_ handler: @escaping () -> Void) {
        self.closeHandler = handler
    }
    
    /**
     * Send data to the device
     */
    func write(_ data: String) throws {
        guard let channel = channel, isConnected else {
            throw NSError(domain: "BluetoothTransport", code: 4, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        
        // ELM327 expects commands terminated with \r
        let command = data.hasSuffix("\r") ? data : data + "\r"
        guard let commandData = command.data(using: .utf8) else {
            throw NSError(domain: "BluetoothTransport", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to encode command"])
        }
        
        let result = commandData.withUnsafeBytes { bytes in
            channel.writeSync(UnsafeMutableRawPointer(mutating: bytes.baseAddress!), length: UInt16(commandData.count))
        }
        if result != kIOReturnSuccess {
            throw NSError(domain: "BluetoothTransport", code: 6, userInfo: [NSLocalizedDescriptionKey: "Write failed: \(result)"])
        }
    }
    
    /**
     * Disconnect from the device
     */
    func disconnect() {
        if let channel = channel {
            channel.close()
            self.channel = nil
        }
        
        if let device = device {
            device.closeConnection()
            self.device = nil
        }
        
        isConnected = false
    }
    
    // MARK: - IOBluetoothRFCOMMChannelDelegate
    
    func rfcommChannelData(_ rfcommChannel: IOBluetoothRFCOMMChannel!, data dataPointer: UnsafeMutableRawPointer!, length dataLength: Int) {
        let data = Data(bytes: dataPointer, count: dataLength)
        receivedData.append(data)
        
        // ELM327 responses are typically terminated with \r or \r\n
        if let string = String(data: receivedData, encoding: .utf8) {
            if string.contains("\r") || string.contains("\n") {
                // Split by line terminators
                let lines = string.components(separatedBy: CharacterSet.newlines)
                    .flatMap { $0.components(separatedBy: "\r") }
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                
                for line in lines {
                    if !line.isEmpty {
                        dataHandler?(line)
                    }
                }
                
                receivedData.removeAll()
            }
        }
    }
    
    func rfcommChannelOpened(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        connectionSuccess = true
        connectionSemaphore?.signal()
    }
    
    func rfcommChannelClosed(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        isConnected = false
        connectionSuccess = false
        closeHandler?()
    }
    
    func rfcommChannelControlSignalsChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        // Handle control signal changes if needed
    }
    
    func rfcommChannelFlowControlChanged(_ rfcommChannel: IOBluetoothRFCOMMChannel!) {
        // Handle flow control changes if needed
    }
    
    func rfcommChannelWriteComplete(_ rfcommChannel: IOBluetoothRFCOMMChannel!, refcon: UnsafeMutableRawPointer!, status error: IOReturn) {
        if error != kIOReturnSuccess {
            let nsError = NSError(domain: "BluetoothTransport", code: 7, userInfo: [NSLocalizedDescriptionKey: "Write complete error: \(error)"])
            errorHandler?(nsError)
        }
    }
}
