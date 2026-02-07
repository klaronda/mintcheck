# Quick Start Guide - How to Use MintCheck OBD-II

## Step 1: Pair Your ELM327 Device

1. **Plug the ELM327 device into your car's OBD-II port** (usually under the dashboard, near the steering wheel)
2. **Turn on your car's ignition** (doesn't need to be running, but ignition should be on)
3. **On your Mac:**
   - Open **System Preferences** → **Bluetooth**
   - Put your ELM327 device in pairing mode (usually by pressing a button, or it auto-pairs)
   - Look for a device name like "OBDII" or "ELM327" or similar
   - Click **Pair** and enter the PIN if prompted (often "1234" or "0000")

## Step 2: Run the Program

```bash
cd /Users/kevoo/Cursor/mintcheck
swift run mintcheck-obd2
```

The program will:
1. **Discover** your paired Bluetooth devices
2. **Connect** to the ELM327 device
3. **Initialize** the connection (sends AT commands)
4. **Read Diagnostic Trouble Codes (DTCs)** - This is what you asked for!
5. **Read sensor data** (RPM, speed, temperature, etc.)

## Step 3: Read the Output

You'll see output like this:

```
[2024-01-01T12:00:00.000Z] [INFO] [MAIN] MintCheck OBD-II Communication Layer
[2024-01-01T12:00:00.001Z] [INFO] [MAIN] =====================================
[2024-01-01T12:00:00.002Z] [INFO] [MAIN] Discovering paired Bluetooth devices...
[2024-01-01T12:00:00.100Z] [INFO] [MAIN] Found 1 paired device(s):
[2024-01-01T12:00:00.101Z] [INFO] [MAIN]   1. OBDII (00-1D-A5-00-00-00)
[2024-01-01T12:00:00.102Z] [INFO] [MAIN] Connecting to device...
[2024-01-01T12:00:00.500Z] [INFO] [MAIN] Connected successfully

=== Reading Diagnostic Trouble Codes (DTCs) ===
[2024-01-01T12:00:01.000Z] [INFO] [TX] → 03
[2024-01-01T12:00:01.200Z] [INFO] [RX] ← 43 01 33 00 00 00
[2024-01-01T12:00:01.201Z] [INFO] [MAIN]   Found 1 diagnostic trouble code(s):
[2024-01-01T12:00:01.202Z] [INFO] [MAIN]     1. P0133

=== PHASE 2: Basic OBD Queries ===
[2024-01-01T12:00:02.000Z] [INFO] [MAIN] Querying 010C (Engine RPM)...
[2024-01-01T12:00:02.200Z] [INFO] [TX] → 010C
[2024-01-01T12:00:02.400Z] [INFO] [RX] ← 41 0C 1A F8
[2024-01-01T12:00:02.401Z] [INFO] [MAIN]   ✓ Value: 1728.5 rpm
```

## Understanding Diagnostic Trouble Codes (DTCs)

DTCs are formatted like: **P0133**

- **First letter** = System:
  - `P` = Powertrain (engine, transmission)
  - `C` = Chassis (ABS, traction control)
  - `B` = Body (airbags, climate control)
  - `U` = Network (communication issues)

- **Next digit** = Code type:
  - `0` = Generic (SAE standard)
  - `1` = Manufacturer-specific

- **Last 3 digits** = Specific code (e.g., `133`)

**Example:** `P0133` = Powertrain, Generic, Code 133 (O2 Sensor Circuit Slow Response)

## Common Issues

### "No paired devices found"
- Make sure the device is paired in System Preferences → Bluetooth
- Make sure Bluetooth is enabled on your Mac
- Try unplugging and replugging the ELM327 device

### "Command timeout" or "NO DATA"
- Make sure the car's **ignition is ON** (doesn't need to be running)
- Some PIDs only work when the engine is running
- The car might not support certain PIDs

### "Connection failed"
- Make sure the ELM327 device is powered on (LED should be blinking)
- Try disconnecting and reconnecting in System Preferences
- Some cheap ELM327 clones have compatibility issues

## What the Program Does

1. **Connects** to your ELM327 device via Bluetooth
2. **Reads DTCs** (Mode 03) - Diagnostic Trouble Codes
3. **Reads sensor data** (Mode 01) - RPM, speed, temperatures, etc.
4. **Logs everything** - You can see every command sent and response received

## Next Steps

- The program currently **reads only** - it doesn't clear codes or write anything
- All data is logged to the console with timestamps
- You can use `--quiet` to reduce verbosity: `swift run mintcheck-obd2 --quiet`
- You can specify a device: `swift run mintcheck-obd2 --address 00-1D-A5-00-00-00`
