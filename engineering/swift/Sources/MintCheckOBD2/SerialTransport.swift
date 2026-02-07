/**
 * Serial Port Transport - Alternative to direct Bluetooth RFCOMM
 * 
 * On macOS, paired Bluetooth SPP devices appear as serial ports (/dev/cu.* or /dev/tty.*).
 * This is often more reliable than direct RFCOMM access.
 */

import Foundation
import IOKit
import IOKit.serial

class SerialTransport {
    private var fileHandle: FileHandle?
    private var isConnected = false
    private var dataHandler: ((String) -> Void)?
    private var errorHandler: ((Error) -> Void)?
    private var closeHandler: (() -> Void)?
    private var readSource: DispatchSourceRead?
    private let serialQueue = DispatchQueue(label: "com.mintcheck.serial")
    private var pollingTask: DispatchWorkItem?
    private var receivedBuffer: String = "" // Buffer for incomplete responses
    
    var connected: Bool {
        return isConnected
    }
    
    /**
     * List available serial ports (for discovering OBDII devices)
     */
    static func listSerialPorts() -> [String] {
        var ports: [String] = []
        
        // Check common locations for Bluetooth serial ports
        let fileManager = FileManager.default
        let devPath = "/dev"
        
        if let contents = try? fileManager.contentsOfDirectory(atPath: devPath) {
            for item in contents {
                // Look for OBDII, ELM, or Bluetooth-related serial ports
                let lowerItem = item.lowercased()
                if (item.hasPrefix("cu.") || item.hasPrefix("tty.")) &&
                   (lowerItem.contains("obd") || lowerItem.contains("elm") || lowerItem.contains("bluetooth")) {
                    ports.append("/dev/\(item)")
                }
            }
        }
        
        return ports.sorted()
    }
    
    /**
     * Connect to a serial port
     */
    func connect(to portPath: String) throws {
        // Open the serial port for reading and writing
        // On macOS, we need to use the same file handle for both
        guard let handle = FileHandle(forUpdatingAtPath: portPath) else {
            throw NSError(domain: "SerialTransport", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to open serial port: \(portPath). Make sure the device is not in use by another app."])
        }
        
        self.fileHandle = handle
        
        // Set up read monitoring with a background queue
        let readQueue = DispatchQueue(label: "com.mintcheck.serial.read")
        
        handle.readabilityHandler = { [weak self] fileHandle in
            readQueue.async {
                let data = fileHandle.availableData
                if !data.isEmpty {
                    if let string = String(data: data, encoding: .utf8) {
                        // Accumulate in buffer
                        self?.receivedBuffer += string
                        
                        // Process complete lines
                        while let range = self?.receivedBuffer.range(of: "\r") ?? self?.receivedBuffer.range(of: "\n") {
                            let line = String(self!.receivedBuffer[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                            self!.receivedBuffer = String(self!.receivedBuffer[range.upperBound...])
                            
                            if !line.isEmpty && line != ">" {
                                self?.dataHandler?(line)
                            }
                        }
                    }
                }
            }
        }
        
        // Also set up a polling mechanism as backup (some serial ports don't trigger readabilityHandler reliably)
        // This is critical because FileHandle.readabilityHandler doesn't always work reliably on macOS serial ports
        var pollTask: DispatchWorkItem!
        pollTask = DispatchWorkItem { [weak self] in
            guard let self = self, self.isConnected else { return }
            
            if let handle = self.fileHandle {
                // Try to read available data (non-blocking)
                // Note: availableData might block briefly, but should return quickly
                let data = handle.availableData
                if !data.isEmpty {
                    if let string = String(data: data, encoding: .utf8) {
                        // Accumulate data in buffer (responses might come in chunks)
                        self.receivedBuffer += string
                        
                        // Process complete lines (terminated with \r or \n)
                        while let range = self.receivedBuffer.range(of: "\r") ?? self.receivedBuffer.range(of: "\n") {
                            let line = String(self.receivedBuffer[..<range.lowerBound]).trimmingCharacters(in: .whitespacesAndNewlines)
                            self.receivedBuffer = String(self.receivedBuffer[range.upperBound...])
                            
                            if !line.isEmpty && line != ">" {
                                // Always call handler - it should be set by now
                                if let handler = self.dataHandler {
                                    handler(line)
                                }
                            }
                        }
                    }
                }
            }
            
            // Schedule next poll (keep polling even if no data - device might be slow)
            if self.isConnected {
                self.serialQueue.asyncAfter(deadline: .now() + 0.05, execute: pollTask) // Poll every 50ms
            }
        }
        
        self.pollingTask = pollTask
        // Start polling immediately (don't wait for handler to be set)
        serialQueue.async(execute: pollTask)
        
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
        guard let handle = fileHandle, isConnected else {
            throw NSError(domain: "SerialTransport", code: 4, userInfo: [NSLocalizedDescriptionKey: "Not connected"])
        }
        
        // ELM327 expects commands terminated with \r
        let command = data.hasSuffix("\r") ? data : data + "\r"
        guard let commandData = command.data(using: .utf8) else {
            throw NSError(domain: "SerialTransport", code: 5, userInfo: [NSLocalizedDescriptionKey: "Failed to encode command"])
        }
        
        handle.write(commandData)
        // Note: FileHandle.write() should automatically flush, but we can't use synchronizeFile() on serial ports
        // The data should be sent immediately
    }
    
    /**
     * Disconnect from the device
     */
    func disconnect() {
        isConnected = false
        pollingTask?.cancel()
        pollingTask = nil
        
        if let handle = fileHandle {
            handle.readabilityHandler = nil
            handle.closeFile()
            self.fileHandle = nil
        }
        
        closeHandler?()
    }
}
