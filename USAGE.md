# MintCheck OBD-II Usage Guide

## Quick Start

1. **Pair your ELM327 device**
   - Open System Preferences → Bluetooth
   - Put your ELM327 device in pairing mode
   - Pair the device (it will appear in paired devices list)

2. **Build the project**
   ```bash
   cd mintcheck
   swift build
   ```

3. **Run the communication test**
   ```bash
   swift run mintcheck-obd2
   ```
   
   Or after building, run directly:
   ```bash
   .build/debug/mintcheck-obd2
   ```

4. **Specify a device manually** (if auto-detection doesn't work)
   ```bash
   swift run mintcheck-obd2 --address 00-1D-A5-00-00-00
   ```
   
   Or:
   ```bash
   .build/debug/mintcheck-obd2 --address 00-1D-A5-00-00-00
   ```

## What to Expect

The CLI will:
1. **Discover devices** - Lists all paired Bluetooth devices
2. **Connect** - Opens RFCOMM connection to ELM327 device
3. **Initialize** - Sends AT commands (ATZ, ATE0, ATL0, etc.)
4. **Query PIDs** - Reads diagnostic data (RPM, speed, temperature, etc.)
5. **Validate** - Checks that ATZ and RPM queries work correctly

## Output Format

All communication is logged with timestamps:
```
[2024-01-01T12:00:00.000Z] [INFO] [TX] → ATZ
[2024-01-01T12:00:00.100Z] [INFO] [RX] ← ELM327 v1.5
[2024-01-01T12:00:00.101Z] [INFO] [TX] → 010C
[2024-01-01T12:00:00.200Z] [INFO] [RX] ← 41 0C 1A F8
[2024-01-01T12:00:00.201Z] [INFO] [MAIN] ✓ Value: 1728.5 rpm
```

## Troubleshooting

### "No paired devices found"
- Make sure the ELM327 device is paired in System Preferences
- Check that the device is powered on and connected to the car's OBD port
- Try unplugging and replugging the device
- Make sure Bluetooth is enabled on your Mac

### "Command timeout"
- The device might be slow to respond
- Try increasing the timeout in `CommandLayer.swift` (default: 2.0 seconds)
- Make sure the car's ignition is on (not just accessory)

### "NO DATA" responses
- The car might not support the requested PID
- Some PIDs only work when the engine is running
- This is normal - the parser will log these as warnings

### Connection issues
- Make sure Bluetooth is enabled on your Mac
- Try disconnecting and reconnecting the device in System Preferences
- Some ELM327 clones have compatibility issues
- The device must be paired before running the tool

### RFCOMM channel errors
- ELM327 devices typically use RFCOMM channel 1
- If connection fails, the device might use a different channel
- Check the device documentation for the correct channel

## Architecture

```
main.swift (CLI)
    ↓
CommandLayer.swift (AT commands, OBD queries, retries)
    ↓
Transport.swift (Bluetooth RFCOMM connection via IOBluetooth)
    ↓
Parser.swift (Hex decoding, PID value extraction)
    ↓
Logger.swift (Raw TX/RX visibility)
```

## Supported PIDs (Mode 01)

| PID | Name | Unit | Formula |
|-----|------|------|---------|
| 0100 | Supported PIDs [01-20] | bitmask | Raw hex |
| 010C | Engine RPM | rpm | ((A*256)+B)/4 |
| 010D | Vehicle Speed | km/h | A |
| 0105 | Coolant Temperature | °C | A-40 |
| 0111 | Throttle Position | % | (100*A)/255 |
| 010F | Intake Air Temperature | °C | A-40 |

## Next Steps

This is the foundation layer. Future phases will add:
- Confidence scoring based on response quality
- More PIDs and diagnostic modes
- Data persistence
- UI integration (SwiftUI for macOS/iOS app)
