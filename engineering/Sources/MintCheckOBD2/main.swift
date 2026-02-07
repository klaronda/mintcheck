import Foundation

struct MintCheckOBD2 {
    static func printHelp() {
        print("""
        MintCheck OBD-II Communication Layer
        
        Usage:
          swift run mintcheck-obd2 [options]
          .build/debug/mintcheck-obd2 [options]
        
        Options:
          --address <address>    Specify Bluetooth device address (e.g., 00-1D-A5-00-00-00)
          --quiet                Reduce logging verbosity
          --help, -h             Show this help message
        
        Examples:
          swift run mintcheck-obd2
          swift run mintcheck-obd2 --address 00-1D-A5-00-00-00
          swift run mintcheck-obd2 --quiet
          .build/debug/mintcheck-obd2 --address 00-1D-A5-00-00-00
        
        Notes:
          - Make sure your ELM327 device is paired via System Preferences
          - The device should appear in paired devices list
          - All communication is logged with timestamps for debugging
        """)
    }
    static func main() async {
        let args = CommandLine.arguments.dropFirst()
        var deviceAddress: String?
        var verbose = true
        
        // Parse CLI arguments
        var i = args.startIndex
        while i < args.endIndex {
            let arg = args[i]
            if arg == "--address" && i + 1 < args.endIndex {
                deviceAddress = String(args[i + 1])
                i += 2
            } else if arg == "--quiet" {
                verbose = false
                i += 1
            } else if arg == "--help" || arg == "-h" {
                Self.printHelp()
                return
            } else {
                i += 1
            }
        }
        
        let logger = Logger(verbose: verbose)
        logger.info("MAIN", "MintCheck OBD-II Communication Layer")
        logger.info("MAIN", "=====================================")
        
        do {
            // First, try to find serial port (easier and more reliable on macOS)
            logger.info("MAIN", "Checking for serial port devices...")
            let serialPorts = SerialTransport.listSerialPorts()
            
            var transport: Any
            var useSerial = false
            
            if !serialPorts.isEmpty {
                logger.info("MAIN", "Found \(serialPorts.count) serial port(s):")
                for (index, port) in serialPorts.enumerated() {
                    logger.info("MAIN", "  \(index + 1). \(port)")
                }
                
                // Prioritize OBDII ports (prefer cu.* over tty.*, and OBDII over Bluetooth-Incoming)
                let selectedPort: String
                if let obdPort = serialPorts.first(where: { $0.contains("OBDII") && $0.contains("cu.") }) {
                    selectedPort = obdPort
                } else if let obdPort = serialPorts.first(where: { $0.contains("OBDII") }) {
                    selectedPort = obdPort
                } else if let cuPort = serialPorts.first(where: { $0.contains("cu.") }) {
                    selectedPort = cuPort
                } else {
                    selectedPort = serialPorts.first!
                }
                
                logger.info("MAIN", "Using serial port: \(selectedPort)")
                logger.info("MAIN", "Connecting via serial port...")
                
                let serialTransport = SerialTransport()
                try serialTransport.connect(to: selectedPort)
                transport = serialTransport
                useSerial = true
                logger.info("MAIN", "Connected successfully via serial port")
            } else {
                // Fall back to Bluetooth RFCOMM
                logger.info("MAIN", "No serial ports found. Trying Bluetooth RFCOMM...")
                logger.info("MAIN", "Discovering paired Bluetooth devices...")
                let devices = BluetoothTransport.discoverPairedDevices()
                
                if devices.isEmpty {
                    logger.error("MAIN", "No paired devices found. Make sure your ELM327 device is paired.")
                    exit(1)
                }
                
                logger.info("MAIN", "Found \(devices.count) paired device(s):")
                for (index, device) in devices.enumerated() {
                    let name = device.name ?? "Unknown"
                    logger.info("MAIN", "  \(index + 1). \(name) (\(device.address))")
                }
                
                // Select device - prioritize OBDII devices
                let selectedAddress: String
                if let address = deviceAddress {
                    selectedAddress = address
                    logger.info("MAIN", "Using specified address: \(selectedAddress)")
                } else if devices.count == 1 {
                    selectedAddress = devices[0].address
                    logger.info("MAIN", "Auto-selected device: \(devices[0].name ?? "Unknown") (\(selectedAddress))")
                } else {
                    // Try to find OBDII device by name (case-insensitive)
                    let obdDevice = devices.first { device in
                        let name = (device.name ?? "").uppercased()
                        return name.contains("OBD") || name.contains("ELM") || name.contains("327")
                    }
                    
                    if let obdDevice = obdDevice {
                        selectedAddress = obdDevice.address
                        logger.info("MAIN", "Auto-selected OBDII device: \(obdDevice.name ?? "Unknown") (\(selectedAddress))")
                    } else {
                        // Fall back to first device
                        selectedAddress = devices[0].address
                        logger.warn("MAIN", "Multiple devices found. No OBDII device detected. Using first: \(devices[0].name ?? "Unknown") (\(selectedAddress))")
                        logger.warn("MAIN", "Use --address <address> to specify the OBDII device")
                    }
                }
                
                // Create transport and connect
                logger.info("MAIN", "Connecting to device...")
                let bluetoothTransport = BluetoothTransport()
                
                try bluetoothTransport.connect(to: selectedAddress)
                transport = bluetoothTransport
                logger.info("MAIN", "Connected successfully via Bluetooth")
            }
            
            // Create command layer (works with both transport types)
            // IMPORTANT: Set up handlers BEFORE we start sending commands
            let commandLayer: CommandLayer
            if useSerial {
                commandLayer = CommandLayer(transport: transport as! SerialTransport, logger: logger, timeout: 2.0, retries: 1)
            } else {
                commandLayer = CommandLayer(transport: transport as! BluetoothTransport, logger: logger, timeout: 2.0, retries: 1)
            }
            
            // Give handlers a moment to be fully set up
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            
            // Phase 1: Initialization
            logger.info("MAIN", "")
            logger.info("MAIN", "=== PHASE 1: Connection & Handshake ===")
            
            // Give the device a moment to be ready after connection
            logger.info("MAIN", "Waiting for device to be ready...")
            try? await Task.sleep(nanoseconds: 500_000_000) // 500ms delay
            
            let initSuccess = await commandLayer.initialize()
            
            if !initSuccess {
                logger.error("MAIN", "Initialization failed. Cannot proceed.")
                if useSerial {
                    (transport as! SerialTransport).disconnect()
                } else {
                    (transport as! BluetoothTransport).disconnect()
                }
                exit(1)
            }
            
            // Query Diagnostic Trouble Codes (Mode 03)
            logger.info("MAIN", "")
            logger.info("MAIN", "=== Reading Diagnostic Trouble Codes (DTCs) ===")
            let dtcResult = await commandLayer.queryDTCs()
            
            if let error = dtcResult.error {
                logger.warn("MAIN", "  ❌ Error reading DTCs: \(error)")
            } else if dtcResult.count == 0 {
                logger.info("MAIN", "  ✓ No diagnostic trouble codes found")
            } else {
                logger.info("MAIN", "  Found \(dtcResult.count) diagnostic trouble code(s):")
                for (index, dtc) in dtcResult.dtcs.enumerated() {
                    logger.info("MAIN", "    \(index + 1). \(dtc)")
                }
            }
            
            // Phase 2: Basic OBD Queries
            logger.info("MAIN", "")
            logger.info("MAIN", "=== PHASE 2: Basic OBD Queries ===")
            
            let pids = [
                ("0100", "Supported PIDs [01-20]"),
                ("010C", "Engine RPM"),
                ("010D", "Vehicle Speed"),
                ("0105", "Coolant Temperature"),
                ("0111", "Throttle Position"),
                ("010F", "Intake Air Temperature"),
            ]
            
            var results: [(pid: String, name: String, result: PIDResponse)] = []
            
            for (pid, name) in pids {
                logger.info("MAIN", "Querying \(pid) (\(name))...")
                let result = await commandLayer.queryPID(pid)
                results.append((pid: pid, name: name, result: result))
                
                if let error = result.error {
                    logger.warn("MAIN", "  ❌ Error: \(error)")
                } else if let value = result.value {
                    let unit = result.unit ?? ""
                    logger.info("MAIN", "  ✓ Value: \(value) \(unit)")
                    logger.info("MAIN", "  Raw: \(result.raw)")
                    logger.info("MAIN", "  Hex: \(result.hex)")
                } else {
                    logger.warn("MAIN", "  ⚠ No value parsed")
                }
                
                // Delay between queries
                try? await Task.sleep(nanoseconds: 200_000_000) // 200ms
            }
            
            // Phase 3: Validation Checklist
            logger.info("MAIN", "")
            logger.info("MAIN", "=== PHASE 3: Validation Checklist ===")
            
            // Check ATZ version
            logger.info("MAIN", "Checking ATZ version response...")
            let atzResult = await commandLayer.sendAT("ATZ")
            let atzCheck = atzResult.success && atzResult.data?.contains("ELM") == true
            logger.info("MAIN", atzCheck ? "  ✓ ATZ returns version string" : "  ❌ ATZ failed")
            
            // Check RPM query
            logger.info("MAIN", "Checking RPM query (010C)...")
            let rpmResult = await commandLayer.queryPID("010C")
            let rpmCheck = rpmResult.error == nil && rpmResult.value != nil && rpmResult.value! >= 0
            if rpmCheck, let rpmValue = rpmResult.value {
                logger.info("MAIN", "  ✓ 010C returns valid RPM: \(rpmValue) rpm")
            } else {
                logger.info("MAIN", "  ❌ 010C failed")
            }
            
            // Summary
            logger.info("MAIN", "")
            logger.info("MAIN", "=== Summary ===")
            logger.info("MAIN", "ATZ Version: \(atzCheck ? "PASS" : "FAIL")")
            logger.info("MAIN", "RPM Query: \(rpmCheck ? "PASS" : "FAIL")")
            logger.info("MAIN", "")
            logger.info("MAIN", "All queries completed. Check logs above for details.")
            logger.info("MAIN", "")
            logger.info("MAIN", "To test reconnection:")
            logger.info("MAIN", "  1. Unplug/replug the OBD device")
            logger.info("MAIN", "  2. Run this script again")
            
            // Keep connection open for a moment, then disconnect
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            logger.info("MAIN", "Disconnecting...")
            if useSerial {
                (transport as! SerialTransport).disconnect()
            } else {
                (transport as! BluetoothTransport).disconnect()
            }
            logger.info("MAIN", "Disconnected")
            
        } catch {
            logger.error("MAIN", "Fatal error", data: error.localizedDescription)
            exit(1)
        }
    }
}

// Entry point - run async main and wait
let semaphore = DispatchSemaphore(value: 0)
Task {
    await MintCheckOBD2.main()
    semaphore.signal()
}
semaphore.wait()
